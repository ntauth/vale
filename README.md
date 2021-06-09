Vale (Verified Assembly Language for Everest)
=============================================

Vale is a tool for constructing formally verified high-performance assembly language code,
with an emphasis on cryptographic code.
It uses existing verification frameworks,
such as [Dafny](https://github.com/Microsoft/dafny) and [F\*](https://github.com/FStarLang/FStar),
for formal verification.
It supports multiple architectures, such as x86, x64, and ARM, and multiple platforms, such as Windows, Mac, and Linux.
Additional architectures and platforms can be supported with no changes to the Vale tool.

Vale is part of the [Everest project](https://project-everest.github.io).

# Installation

See the [INSTALL](./INSTALL.md) file for installing Vale and its dependencies.

# Code Organization

See the [CODE](./CODE.md) file for more details on the various files in the repository.

# Documentation

See the [Vale documentation](./doc/index.html) for a description of the Vale language and Vale tool.

You can also see our academic paper describing Vale:

> [Vale: Verifying High-Performance Cryptographic Assembly Code](https://project-everest.github.io/assets/vale2017.pdf)  
> Barry Bond, Chris Hawblitzel, Manos Kapritsos, K. Rustan M. Leino, Jacob R. Lorch, Bryan Parno, Ashay Rane, Srinath Setty, Laure Thompson.  
> In Proceedings of the USENIX Security Symposium, 2017.  
> Distinguished Paper Award

# Examples
The examples can be found in `test/`.
## memcpy (x64)
1. Build Dafny artifacts:
   ```bash
    mono ../bin/vale.exe -includeSuffix .vad .dfy -sourceFrom BASE ../src/ -destFrom BASE ../obj/ -in ./memcpy_checked.vad -out ../obj/test/memcpy_checked.dfy
    ```
2. **(Needs fixing)** Rename `decls*.gen.dfy` to `decls*.dfy` in `obj/arch/x64`. Open `decls64.dfy` and `include "decls.dfy"` instead of `include "decls.gen.dfy"`.
2. Verify and produce an executable:
   ```bash
   mono ../bin/Dafny.exe /ironDafny /allocated:1 /induction:1 /compile:1 /timeLimit:30 /errorLimit:1 /errorTrace:0 /trace /noNLarith /z3exe:/usr/bin/z3 ../obj/test/memcpy_checked.dfy 1> ../obj/test/memcpy_checked.dfy.verified.tmp 2>&1
   ```
3. Generate the assembly after verifying constant time and leakage properties:
    ```bash
    mono ../obj/test/memcpy_checked.exe
    ```

# License

Vale is licensed under the Apache license in the [LICENSE](./LICENSE) file.

# Version History
- v0.1:   Initial code release, containing code written by:
Andrew Baumann, Barry Bond, Andrew Ferraiuolo, Chris Hawblitzel,
Jon Howell, Manos Kapritsos, K. Rustan M. Leino, Jacob R. Lorch,
Bryan Parno, Ashay Rane, Srinath Setty, and Laure Thompson.
