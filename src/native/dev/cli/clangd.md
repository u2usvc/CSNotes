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

