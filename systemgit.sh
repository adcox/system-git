#!/bin/sh
#
# Maintain a list of git repositories on your system and provide a quick way to
# see the status of all of them
#
# For usage, call systemgit -h
#
# Author: Andrew Cox
# Version: 4 Feb 2021

# Reset POSIX variable
OPTIND=1

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD=$(tput bold)
NORM=$(tput sgr0)

# ------------------------------------------------------------------------------
# Function Definitions
# ------------------------------------------------------------------------------

isInRepoList() {
    local path=$1
    # Determine if path is in the REPO_LIST file

    while read line
    do
        if [[ $line == \#* ]]; then
            continue
        fi

        if [ $line = $path ]; then
            return 1
        fi
    done < $REPO_LIST

    return 0
}

isGitRepo(){
    local path=$1
    # Determine if the directory, $path, is a git repository

    if [ -d "$path/.git" ]; then
        return 1
    else
        return 0
    fi
}

showRepoStatus () {
    local path=$1       # path to git repository, no trailing slash
    local maxLen=$2     # length of longest path string

    # Check that we have a valid repo; return if not
    isGitRepo $path
    if [ $? = 0 ]; then
        return
    fi

    # Command to get info from a git repo in a different directory
    gitAtDir="git --git-dir=$path/.git --work-tree=$path"

    # Bring remote references up to date; this can take some computation time!
    # If the repo requires a password, the process will hang until the password is input
    #update=$($gitAtDir remote update)

    # most recent commit
    commit=$($gitAtDir log -1 | grep "commit" |\
        awk '$2>0 {print substr($2,1,6)}')

    # Date of most recent commit
    ver=$($gitAtDir log -1 | grep "Date" | awk '{print $3, $4, $5, $6}')

    # Current branch
    branch=$($gitAtDir status | grep "On branch" | awk '{print $3}')

    # Status of current branch w.r.t. origin
    status=$($gitAtDir status | grep "Your branch is" |\
        awk '{for(i=4;i<=NF;i++) printf $i" "; print ""}')

    if [ -z "$status" ]; then
        status="N/A"
        statusColor="${ORANGE}"
    else
        if [ "${status#*up to date}" != "$status" ]; then
            statusColor="${GREEN}"
        else
            statusColor="${RED}"
        fi
    fi

    # number of modifications
    numMod=$($gitAtDir diff --numstat | wc -l | awk '{print $1}')

    if [ -z "$numMod" ] || [ "$numMod" -eq 0 ]; then
        numMod="0"
        modColor="${GREEN}"
    else
        modColor="${RED}"
    fi

    if [ $verbose == 1 ]; then
        print "${BLUE}${BOLD}$path:${NORM}${NC}"
        print "  Currently at $branch/$commit"
        print "  Updated $ver"
        print "  ${statusColor}Status: $status${NC}"
        print "  ${modColor}$numMod modifications${NC}"
        print "" # newline after each repo
    else
        # Use printf to avoid newlines
        printf "${BLUE}${BOLD}%-${maxLen}s:${NORM}${NC}" "$path"
        printf "%-25s" " $branch/$commit"
        printf "%-24s" " | $ver"
        printf " | ${statusColor}%-40s${NC}" "$status"
        printf " | ${modColor}$numMod diff${NC}"
        printf "\n"
    fi
}

showHelp(){
    print "Usage: systemgit"
    print "       systemgit [show | add | add-all | remove]\n"

    print "Arguments:"
    print "  show:    show the status of all tracked repositories"
    print "  add:     add the current directory as a tracked repository"
    print "  add-all: add all git repositories within the current directory as"
    print "           tracked repositories"
    print "  remove:  remove the current directory from being tracked"
    print ""

    print "Options:"
    print "  -h     Show this help information"
    print "  -f     Specify a path for add/remove/add-all other than the current directory"
    print "  -v     Use verbose output"
}

print() {
    printf "$1\n"
}

# ------------------------------------------------------------------------------
# Parse Inputs
# ------------------------------------------------------------------------------

# Default values
path="`pwd`"
verbose=0
REPO_LIST="$HOME/.gitrepos"

# Parse options
while getopts "h?vf:" opt; do
    case "$opt" in
        h|\?)
            showHelp
            exit 0
            ;;
        v)
            verbose=1
            ;;
        f)
            path="$OPTARG"
            ;;
    esac
done

# Shift to after the options
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

if [ "$#" -lt 1 ]; then
    # No arguments passed in - do default action
    action="show"
else
    action="$1"
fi

# Check to make sure REPO_LIST exists
if [ ! -f $REPO_LIST ]; then
    touch $REPO_LIST
fi

case $action in
    help)
        showHelp
        ;;
    show) # Display git-repos
        print "Status of all repositories:\n"

        # Get length of longest string
        maxLen=0
        while read line
        do
            len=${#line}
            if [ $len -gt $maxLen ]; then
                maxLen=$len
            fi
        done < $REPO_LIST

        # Print the repository status
        while read line
        do
            if [[ $line == \#* ]]; then
                # Print lines that begin with "#" character
                print "$line"
            else
                showRepoStatus $line $maxLen
            fi
        done < $REPO_LIST
        print "Done!"
        ;;
    add) # add a repo to the list
        isInRepoList $path
        if [ $? = 1 ]; then
            print "Error: $path is already listed"
            exit 1
        fi

        isGitRepo $path
        if [ $? = 0 ]; then
            print "Error: $path is not a git repo"
            exit 1
        fi

        # We've passed the checks, add the repo to the list
        echo $path >> $REPO_LIST
        print "Added $path"
        ;;
    add-all) # add all repos within the current directory to the list
        # $0 is the full path to this script, so this essentially just runs
        # 'systemgit add' from each git repo found
        find "$path" -name .git -type d -execdir "$0" add \;
        ;;
    remove) # remove a repo from the list
        isInRepoList $path
        if [ $? = 0 ]; then
            print "$path is not listed"
            exit 0
        fi

        # The path exists, so delete it from the list
        #   Read through the lines of REPO_LIST and write any
        #   that aren't the line to delete to the temp file. Finally, replace
        #   the list with the temp file and delete the temp file.
        tempFile="$REPO_LIST.bak"
        touch $tempFile
        while read line
        do
            if [ $line != $path ]; then
                echo $line >> $tempFile
            fi
        done < $REPO_LIST
        mv $tempFile $REPO_LIST
        ;;
    *)
        print "Error: unrecognized command: $action"
        showHelp
        ;;
esac
