# System Git

Do you have dozens of repositories on your machine and can't keep track of which
ones you need to push or pull to/from a remote server? System git is
a simple command-line tool that maintains a list of git repositories and 
provides a simple interface to see the status of every repo at once, a quick way 
to see if you need to update or push any of them.

## Installation
1. Make the `systemgit.sh` script executable: `chmod +x systemgit.sh`
2. Create a symlink to your script from a folder on the path, e.g., 
`ln -s /path/to/script/systemgit.sh $HOME/.local/bin/systemgit`

## Usage
1. Create a list of git repositories. You can do this easily by navigating to 
each directory and calling `systemgit add`. The path is saved in the 
`$HOME/.gitrepos` file. If you have many git repositories within a parent
directory, you can use `systemgit add-all` to find and add them all, regardless
of how deeply nested they may be. To remove a repository, simply call `systemgit remove` 
from the repository directory. Of course, you can always modify `.gitrepos`
manually.
2. Call `systemgit` or `systemgit show` to view the status of all the 
repositories you've added to the `.gitrepos` list.

## Tips
* `systemgit -h` displays the help message.
* When you first set up the system, you can begin with `find $HOME -name ".git"`
to get a list of repositories within your home directory. Or you can just run
`systemgit add-all` from your home directory to add them all automatically!
