# nvim

## inline latex rendering support

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

# clangd

## mingw

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
