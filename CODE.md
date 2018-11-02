The following directories contain Vale and related tools:

* [tools/Vale/src](./tools/Vale/src): Vale
* [tools/Vale/test](./tools/Vale/test): test files for Vale
* [tools/Dafny](./tools/Dafny): Dafny binaries built from https://github.com/Microsoft/dafny
* [tools/Kremlin](./tools/Kremlin): Interface to [Kremlin](https://www.github.com/FStarLang/Kremlin)

The following directories contain library code verified by Dafny and Vale:

* [dafny/specs/lib](./dafny/specs/lib) and [dafny/code/lib](./dafny/code/lib): general-purpose libraries for Dafny
* [dafny/specs/arch](./dafny/specs/arch) and [dafny/code/arch](./dafny/code/arch): definitions of assembly language architectures (x86, x64, ARM)
* [dafny/code/test](./dafny/code/test): test files for libraries and architecture code

Files in dafny/specs are specification files that are part of the trusted computing base.
Files in dafny/code contain verified code that is not part of the trusted computing base.
Files in dafny/specs should not depend on files in dafny/code.

Building Vale will create the following additional directories;
all files generated by the build should be in these directories:

* obj
* bin

Cryptography implementations verified with Vale/F* reside at https://github.com/project-everest/hacl-star/tree/fstar-master/vale .
Cryptography implementations verified with Vale/Dafny can be found in the legacy_dafny branch.