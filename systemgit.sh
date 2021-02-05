#!/bin/sh
#
# Maintain a list of git repositories on your system and provide a quick way to
# see the status of all of them
#
# For usage, call systemgit help
#
# Author: Andrew Cox
# Version: 4 Feb 2021

REPO_LIST="$HOME/.gitrepos"

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
	local path=$1
	# Input arguments
	#
	# $path - Path to the git repo, no trailing slash

	# Command to get info from a git repo in a different directory
	gitAtDir="git --git-dir=$path/.git --work-tree=$path"

	# Bring remote references up to date; this can take some computation time!
	# If the repo requires a password, the process will hang until the password is input
	#update=$($gitAtDir remote update)

	#basename `"$gitAtDir rev-parse --show-top-level"`
	#repoName=$?

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

	echo "${BLUE}${BOLD}$path:${NORM}${NC}"
	echo "  Currently at $branch/$commit"
	echo "  Updated $ver"
	echo "  ${statusColor}Status: $status${NC}"
	echo "  ${modColor}$numMod modifications${NC}"
	echo "" # newline after each repo
}

showHelp(){
	echo "Usage: systemgit"
	echo "       systemgit [show | add | remove]\n"

	echo "Arguments:"
	echo "  show:   show the status of all tracked repositories"
	echo "  add:    add the current directory as a tracked repository"
	echo "  remove: remove the current directory from being tracked"
}

# ------------------------------------------------------------------------------
# Parse Inputs
# ------------------------------------------------------------------------------
if [ "$#" -lt 1 ]; then
	# No arguments passed in - do default action
	action="show"
else
	action="$1"
fi

path="`pwd`" # TODO - allow user to specify a path

case $action in
	help)
		showHelp
		;;
	show) # Display git-repos
		echo "Status of all repositories:\n"
		while read line
		do
			showRepoStatus $line
		done < $REPO_LIST
		echo "Done!"
		;;
	add) # add a repo to the list
		isInRepoList $path
		if [ $? = 1 ]; then
			echo "Error: $path is already listed"
			exit 1
		fi

		isGitRepo $path
		if [ $? = 0 ]; then
			echo "Error: $path is not a git repo"
			exit 1
		fi

		# We've passed the checks, add the repo to the list
		echo $path >> $REPO_LIST
		echo "Added $path"
		;;
	remove) # remove a repo from the list
		isInRepoList $path
		if [ $? = 0 ]; then
			echo "$path is not listed"
			exit 0
		fi

		# The path exists, so delete it from the list
		# 	Read through the lines of REPO_LIST and write any
		#	that aren't the line to delete to the temp file. Finally, replace
		#	the list with the temp file and delete the temp file.
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
		echo "Error: unrecognized command: $action"
		showHelp
		;;
esac