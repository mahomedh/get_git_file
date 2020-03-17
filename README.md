# get_git_file
Script to download individual files from a private Github repo

I didn't want to particularly clone the entire repo nor did I want to download to my Windows machine, to then upload to the Linux machines.
 
This script allows you to create a personal token. This is then saved into the `.get_git_file.conf` in the user's home directory. Every time you specify a repo and repo owner, this is stored as well. Subsequent calls will use the stored values unless new values are given at the command line.

The idea is that you can download the one script with curl or wget from the public repo. Then you are able to download your other scripts from the private repo without much faffing.
