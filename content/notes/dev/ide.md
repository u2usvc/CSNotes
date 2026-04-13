# IDE & git

## git

### add global gitignore file

```bash
git config --global core.excludesFile ~/.gitignore_global && echo "fileiwanttoignore.txt" >> ~/.gitignore_global
```

### ambigious fix

```bash
# list refs
git show-ref master
# 15b28ec22dfb072ff4369b35ef18df51bb55e900 refs/heads/master
# 15b28ec22dfb072ff4369b35ef18df51bb55e900 refs/origin/master
# 15b28ec22dfb072ff4369b35ef18df51bb55e900 refs/remotes/origin/HEAD
# 15b28ec22dfb072ff4369b35ef18df51bb55e900 refs/remotes/origin/master
### ^^^ how it should normally look

# delete a weird ref locally if you see one
git update-ref -d refs/remotes/origin/origin/origin/master

# delete weird ref remotely
git push origin --all --prune
```

### create orphan repo

```bash
git checkout --orphan main
git add . && git commit -m 'initial'
git push origin main
```

### merge from development branch without commit history

```bash
# switch to master
git checkout master
# merge without commit history
git merge --squash dev
git commit --all -m 'commit'
git push origin master
```

### merge without merge commit

```bash
# create feature branch
git checkout -b feature/foo master

# make some commits

# rebase current feature branch to match master's commit history
git rebase master

# switch to master
git checkout master

# merge only fast-forward commits
git merge --ff-only feature/foo
### in order to merge without commit history at all use --squash
git merge --squash feature/foo

# -d (safe delete) ensure only fully merged branches are deleted
git branch -d feature/foo
```

### push using PAT via HTTPS

```bash
git remote add origin https://username:thisismypattoken@gitea.aperture.ad/username/proj.git
```

### stash

```bash
# stash changes in the current branch
git stash

# list stashed changes
git stash list
# inspect stashed changes
git stash show

# apply stashed changes
git stash apply
```

## mingw

### clangd w mingw

While setting up C crossdev environment on GNU/Linux for Microsoft Windows you may face an issue with clangd stating "Only Win32 target is supported!".
Even after you include the correct-architecture directory in CompileFlags for header search with -I compiler flag, do not forget to change the compiler itself by specifying the "Compiler" key in project's .clangd configuration file.

```yaml
CompileFlags:
    Add: [-I/usr/lib/mingw64-toolchain/x86_64-w64-mingw32/include]
    Compiler: /usr/lib/mingw64-toolchain/bin/x86_64-w64-mingw32-c++

```

The error appears because of the #if directive statement checking

```bash
clangd --check=./main.cpp 2>&1 | grep 'E\['
```

## nvim

### inline latex rendering support

- ensure snacks.nvim is installed and you are using a supported terminal for graphics (such as kitty)
- install `pdflatex`, `texlive-collection-latexextra` and `texlive-standalone` (fedora) or just `texlive-full` (debian)
- install `mermaid-cli` using `sudo npm install -g @mermaid-js/mermaid-cli`
- `sudo npm install -g tree-sitter-cli`
- `:TSInstall latex`

You can now test it using neorg for example:

```
@math
\[
\LaTeX \text{ is W}
\]
@end

$n = 7 \implies \phi(7) = \#\{1,2,3,4,5,6\} = 6$
```
