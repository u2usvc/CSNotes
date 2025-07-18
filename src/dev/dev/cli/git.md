# git
## Example usage
let's say 2 machines (RW-1 and RW-2) want to fully sync `master`
```bash
### RW-1 commit changes to git origin
git checkout -b SOME-BRANCH-1       # create some-branch and switch, make some changes
# then at home:
git add --all
git commit -m "mod"
git push origin SOME-BRANCH-1


### REPEAT THE SAME ON RW-2 (i.e. commit changes), then:
git checkout -b SOME-BRANCH-2       # create some-branch and switch, make some changes
# then at home:
git add --all
git commit -m "mod"
git push origin SOME-BRANCH-2


### MERGE and SYNC (valid for both machines)
# let's say we're on RW-2 and we want to merge all branches into origin/master
git fetch --all -Pp                 # fetch current state
git checkout master                 # switch to master for merging
git merge SOME-BRANCH-2             # merge 1st
git merge origin/SOME-BRANCH-1      # merge 2nd
# if conflicts arise (if you modified the same line) - delete all git-added lines and leave 
# only things that're needed. 
# e.g. remove all <<<<<<,  ======, >>>>>> lines edit the file to the state you wish to commit
# Then run:
# git add .
# git commit -m "mod"
git push origin master              # push changes to repo
git checkout SOME-BRANCH-2          # don't forget to switch to machine's repo for future work


### SYNC the working branch (DO THAT ONLY AFTER YOU COMMIT CHANGES)
# let's assume that the worse_branch is SOME-BRANCH-1 and the better_branch master
git fetch --all -Pp

git checkout master           # switch to master
git pull                      # sync changes in local master with fetched master

git branch -d SOME-BRANCH-1   # delete SOME-BRANCH-1
git checkout -b SOME-BRANCH-1 master # create new SOME-BRANCH-1 from synced master
```

## .gitignore
```bash
# ignore a file
DEV_README.md
# ignore all files inside the directory
ImpTgsReq/obj/*

# after adding .gitignore you can do the following to get rid of unneded tracked files
git rm -r --cached .
git add .
git commit -m "fixed untracked files"
```
symlink to a directory is to be handled as a file in .gitignore for correct interpretation

## find lost commit
```bash
# find lost commit in reflog tree
git reflog
git reset --hard e870e41
```

## create orphan branch (no commit history)
```bash
git checkout --orphan main
git add . && git commit -m 'initial'
git push origin main
```

## useful commands
```bash
# if you don't like the commit, reset to the previous 
# one and keep the changes to files, but unstage them
git reset
# if you wanna keep the changes staged
git reset --soft HEAD~1

# unstage the file/dir
git restore --staged dev.txt

# commit all, even unstaged
git commit --all -m "$COMMIT_MESSAGE"
```
