# Nand2Tetris in Lua: VM Translator and Jack Compiler

Software tools from the [Nand2Tetris](https://www.nand2tetris.org/) course, all written in **Lua**:

1. a **VM translator** that converts VM code to Hack assembly, and
2. a **compiler for the Jack language** that parses Jack source files and generates VM code.

Together they cover the software half of the course: from a high-level program, through a virtual machine, down to assembly for the Hack computer.

## What is inside

| Folder | Content |
|---|---|
| `Targil0/` | Warm-up exercise in Lua: reads `.vm` files that contain `buy` / `sell` lines and writes totals. |
| `Targil1/` | **VM translator.** `Parser.lua` reads VM commands and `CodeWriter.lua` writes Hack assembly: arithmetic and logic, push and pop for all memory segments, labels, goto and if-goto, function, call and return. Includes the course test programs (`.vm` and `.asm`) and our own tests in `Our_Tests/`. |
| `Targil3/` | A small program written **in Jack** (`Main`, `Shape`, `ShapeGame`) that draws shapes on the screen. |
| `targil4/` | **Jack compiler.** `JackTokenizer.lua` breaks the source into tokens, `JackParser.lua` is a recursive-descent parser for the Jack grammar, `SymbolTable.lua` tracks variables and scopes, `VMWriter.lua` emits VM commands, and `JackAnalyzer.lua` is the entry point. |

## How the compiler works

1. **Tokenizer:** removes comments and splits the source into keywords, symbols, identifiers and constants (it also writes a `...T.xml` token file for checking).
2. **Parser:** compiles classes, subroutines, statements and expressions with recursive descent, and writes the parse tree as XML.
3. **Symbol table and VM writer:** the parser fills the symbol table (fields, statics, arguments and locals) and generates the matching VM code, including object allocation for constructors, arrays, and `if` / `while` labels.

## How to run

Requirements: [Lua](https://www.lua.org/). The file scanning uses the Windows `dir` command, so the tools were written for **Windows**.

```bash
# VM translator: a single .vm file or a folder of .vm files -> .asm
cd Targil1
lua Main.lua path/to/Program.vm

# Jack compiler: a single .jack file or a folder -> .xml and .vm
cd targil4
lua JackAnalyzer.lua path/to/JackProgram
```

The generated `.vm` files can be loaded into the course's VM Emulator and the `.asm` files into the CPU Emulator to run them.

## Team

Developed by **Efrat Brinkman** and **Yael Rubnitz** as part of the Nand2Tetris project at the Jerusalem College of Technology (JCT).
Test programs and the Nand2Tetris tools belong to the Nand2Tetris course.
