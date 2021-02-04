#System Git

A simple command-line tool that maintains a list of git repositories and 
provides a simple interface to see the status of every repo, a quick way to 
see if you need to update or push any of them.

## Installation
1. Make the `systemgit.sh` script executable: `chmod +x systemgit.sh`
2. Create a symlink to your script from a folder on the path, e.g., 
`ln -s /path/to/script/systemgit.sh $HOME/.local/bin/systemgit`

## Usage
1. Create a list of git repositories. You can do this easily by navigating to 
each directory and calling `systemgit add`. The path is saved in the 
`$HOME/.gitrepos` file. To remove a repository, simply call `systemgit remove` 
from the repository directory. Of course, you can always modify `.gitrepos`
manually.
2. Call `systemgit` or `systemgit show` to view the status of all the 
repositories you've added to the `.gitrepos` list.

`systemgit help` displays the help message.