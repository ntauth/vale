#
# Main file for building Vale source code, under the src\tree
#

# Python imports
import os, os.path
import sys

# Imported identifiers defined in the SConstruct file
Import('env', 'BuildOptions', 'dafny_default_args_nlarith', 'dafny_default_args_larith', 'fstar_default_args', 'fstar_default_args_nosmtencoding', 'do_dafny', 'do_fstar', 'stage1', 'stage2', 'fstar_extract')

#
# Verify *.vad and *.dfy under src/test/ and tools/vale/test/
#
verify_paths = [
  'src/',
  'tools/Vale/test',
]
Export('verify_paths')

external_files = [
  'obj/external/CanonCommSwaps.fst',
  'obj/external/CanonCommMonoid.fst',
  'obj/external/CanonCommSemiring.fst',
]
Export('external_files')

no_extraction_files = [
  'obj/ml_out/CanonCommMonoid.ml',
  'obj/ml_out/CanonCommSemiring.ml',
  'obj/ml_out/X64_Poly1305_Math_i.ml',
  'obj/ml_out/Vale_Tactics.ml',
]
Export('no_extraction_files')

manual_dependencies = {
  'obj/arch/x64/X64.Vale.InsLemmas_i.fst.verified.tmp': 'obj/arch/x64/X64.Vale.Decls_i.fst',
  'obj/arch/x64/X64.Vale.InsBasic.fst.verified.tmp': 'obj/arch/x64/X64.Vale.Decls_i.fst',
  'obj/arch/x64/X64.Vale.InsMem.fst.verified.tmp': 'obj/arch/x64/X64.Vale.Decls_i.fst',
  'obj/arch/x64/X64.Vale.InsVector.fst.verified.tmp': 'obj/arch/x64/X64.Vale.Decls_i.fst',
  'obj/arch/x64/X64.Vale.InsAes.fst.verified.tmp': 'obj/arch/x64/X64.Vale.Decls_i.fst',

  'obj/arch/x64/X64.Vale.InsMem.fst.tmp': 'obj/arch/x64/X64.Memory_i.fst',
  'obj/arch/x64/X64.Vale.InsVector.fst.tmp': 'obj/arch/x64/X64.Memory_i.fst',
  'obj/arch/x64/X64.Vale.StateLemmas_i.fsti.tmp': 'obj/arch/x64/X64.Memory_i.fst',
  'obj/arch/x64/X64.Vale.StateLemmas_i.fst.tmp': 'obj/arch/x64/X64.Memory_i.fst',
  'obj/arch/x64/X64.Memory_i_s.fst.tmp': 'obj/arch/SecretByte.fst',
}
Export('manual_dependencies')

#
# All include paths for FStar should be in this list.
# All files should use exactly the include paths in this list.
# All .fst files and .fsti files in the include paths should have distinct names.
# Otherwise, the dependency analysis will not be able to find all the
# dependencies for all the files using just one invocation of FStar.exe --dep.
#
# For .vaf files, the generated .fst and .fsti files live under the obj directory,
# so the include path should contain obj/... for any .vaf files.
#
fstar_include_paths = [
  'obj/Vale/test',
  'obj/test',
  'obj/arch',
  'obj/arch/x64/',
  'obj/arch/x64/interop',
  'obj/lib/collections/',
  'obj/lib/math',
  'obj/lib/util',
  'obj/crypto/aes/',
  'obj/crypto/aes/x64',
  'obj/crypto/poly1305/',
  'obj/crypto/poly1305/x64/',
  'obj/thirdPartyPorts/OpenSSL/poly1305/x64/',
  'obj/external/'
]
Export('fstar_include_paths')
env['FSTAR_INCLUDES'] = " ".join(["--include " + x for x in fstar_include_paths])

#
# Table of special-case Dafny source which requires non-default arguments
#
verify_options = {
  'src/arch/arm/nlarith.s.dfy': BuildOptions(dafny_default_args_nlarith),
  'src/arch/arm/bitvectors.i.dfy': BuildOptions(dafny_default_args_larith + ' /proverOpt:OPTIMIZE_FOR_BV=true'),
  'src/crypto/aes/x64/aes_main.i.dfy': BuildOptions(dafny_default_args_larith),
  'src/lib/math/mul_nonlinear.i.dfy': BuildOptions(dafny_default_args_nlarith),
  'src/lib/math/div_nonlinear.i.dfy': BuildOptions(dafny_default_args_nlarith),
  'src/crypto/hashing/sha-arm/bit-vector-lemmas.i.dfy': BuildOptions(dafny_default_args_larith + ' /proverOpt:OPTIMIZE_FOR_BV=true'),
  'src/crypto/hashing/sha-x64/sha256_vale_main.i.dfy': BuildOptions(dafny_default_args_larith),
  'src/lib/math/div.i.dfy': BuildOptions(dafny_default_args_larith + ' /timeLimit:60'),
  'src/lib/util/operations.i.dfy': BuildOptions(dafny_default_args_larith + ' /proverOpt:OPTIMIZE_FOR_BV=true'),
  'obj/crypto/aes/cbc.gen.dfy': BuildOptions(dafny_default_args_larith + ' /timeLimit:120'),
  'obj/crypto/aes/x64/cbc.gen.dfy': BuildOptions(dafny_default_args_larith + ' /timeLimit:120'),
  'src/lib/util/operator.vaf': BuildOptions(fstar_default_args, valeIncludes = ''),

  # Any use of expose_interfaces requires adding to manual_dependencies
  'src/arch/x64/X64.Vale.InsLemmas_i.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Vale.Decls_i.fst' + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'obj/arch/x64/X64.Vale.InsBasic.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Vale.Decls_i.fst' + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'obj/arch/x64/X64.Vale.InsMem.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Vale.Decls_i.fst' + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'obj/arch/x64/X64.Vale.InsVector.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Vale.Decls_i.fst' + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'obj/arch/x64/X64.Vale.InsAes.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Vale.Decls_i.fst' + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'src/arch/x64/X64.Vale.StateLemmas_i.fsti': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'src/arch/x64/X64.Vale.StateLemmas_i.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'src/arch/x64/X64.Vale.Lemmas_i.fsti': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'src/arch/x64/X64.Vale.Lemmas_i.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),
  'src/arch/x64/X64.Vale.Decls_i.fst': BuildOptions(fstar_default_args + ' --expose_interfaces obj/arch/x64/X64.Memory_i.fst'),

  # .dfy files default to this set of options
  '.dfy': BuildOptions(dafny_default_args_larith),

  # Special treatment for sensitive modules
  'src/arch/x64/X64.Leakage_Ins_i.fst': BuildOptions(fstar_default_args_nosmtencoding),

  # Disable verification by adding 'filename': None
  'tools/Vale/test/vale-debug.vad': None,
  'tools/Vale/test/tactics1.vaf': None,
  'src/crypto/aes/x64/Low.GCMencrypt.fst': None,
  'src/arch/x64/interop/Interop_Printer.fst': None, # TODO: (117,2-118,42): (Error 276) Unexpected output from Z3: (error "line 86815 column 3: unknown function/constant Tm_arrow_9bcbe8d4241cd40112d64a75809541a7")
#  'src/arch/x64/interop/*.fst': None,
#  'src/arch/x64/interop/*.fsti': None,

  # Interop stubs
  'src/arch/x64/interop/AESEncryptBlock_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/AESEncryptBE_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Gcm_load_xor_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Gcm_make_length_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/GCTR_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/GHash_extra_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/GHash_one_block_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/GHash_stdcall_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Inc32_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Mk_quad32_1_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Quad32_xor_win.fst': None, # TODO: BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Reverse_quad32_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  'src/arch/x64/interop/Zero_quad32_win.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces SecretByte.fst --expose_interfaces X64.Memory_i_s.fst --expose_interfaces X64.Memory_i.fst'),
  
  #'src/thirdPartyPorts/OpenSSL/poly1305/x64/X64.Poly1305.vaf': None,

  'src/*/*.fst': BuildOptions(fstar_default_args),
  'src/*/*.fsti': BuildOptions(fstar_default_args),


  # .fst/.fsti files default to this set of options
  '.fst': BuildOptions(fstar_default_args + ' --use_two_phase_tc false'),
  '.fsti': BuildOptions(fstar_default_args + ' --use_two_phase_tc false'),

  # Needed to significantly speed up verification of interop files (and use the checked Memory_i_s.fst with expose_interfaces)
  'src/arch/x64/Views.fst': BuildOptions(fstar_default_args.replace('--smtencoding.nl_arith_repr wrapped', '--smtencoding.nl_arith_repr native') + ' --expose_interfaces SecretByte.fst'),
  'src/arch/x64/X64.Bytes_Semantics_i.fst': BuildOptions(fstar_default_args.replace('--smtencoding.nl_arith_repr wrapped', '--smtencoding.nl_arith_repr native') + ' --expose_interfaces SecretByte.fst'),

  'obj/lib/collections/Collections.Lists_i.fst': BuildOptions(fstar_default_args.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100','')),
  'src/crypto/poly1305/x64/X64.Poly1305.Util_i.fst': BuildOptions(fstar_default_args_nosmtencoding),
  'src/crypto/poly1305/x64/X64.Poly1305.Util_i.fsti': BuildOptions(fstar_default_args_nosmtencoding),
  'src/arch/x64/X64.Memory_i_s.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '').replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.arith.nl=false', '') + '--smtencoding.elim_box true ' + ' --expose_interfaces obj/arch/SecretByte.fst'),
  'src/arch/x64/Interop.fst': BuildOptions(fstar_default_args_nosmtencoding.replace('--use_extracted_interfaces true', '').replace('--z3cliopt smt.QI.EAGER_THRESHOLD=100', '') + '--smtencoding.elim_box true '),
  'src/arch/Memory_s.fst': BuildOptions(fstar_default_args.replace('--use_extracted_interfaces true', '')),
  'src/lib/util/BufferViewHelpers.fst' : BuildOptions(fstar_default_args_nosmtencoding.replace('--z3cliopt smt.arith.nl=false', '')),

  # We copy these files from F*'s library because we need to generate a .checked file for them,
  # but we don't need to reverify them:
  'obj/external/*.fst': BuildOptions('--cache_checked_modules --admit_smt_queries true'),

  # .vad/.vaf files default to this set of options when compiling .gen.dfy/.fst/.fsti
  '.vad': BuildOptions(dafny_default_args_larith),
  '.vaf': BuildOptions(fstar_default_args  + ' --use_two_phase_tc false'),
}
if env['TARGET_ARCH'] != 'x86':
  verify_options['src/test/memcpy.vad'] = None
  verify_options['src/test/stack-test.vad'] = None

if do_fstar and stage1:
  for x in ['CanonCommSwaps.fst', 'CanonCommMonoid.fst', 'CanonCommSemiring.fst']:
    env.Command('obj/external/' + x, env['FSTAR_PATH'] + '/examples/tactics/' + x, Copy("$TARGET", "$SOURCE"))
  if 'KREMLIN_HOME' in os.environ:
    for x in ['C.Loops.fst']:
      env.Command('obj/external/' + x, env['KREMLIN_HOME'] + '/kremlib/' + x, Copy("$TARGET", "$SOURCE"))
 

Export('verify_options')

#
# Table of files we exclude from the minimal test suite
# (typically for performance reasons)
# Note that the entries below are prefixes of blacklisted files
#
min_test_suite_blacklist = [
  'obj/crypto/aes/x64/X64.GCMencrypt.fst',
  'obj/crypto/aes/x64/X64.GCMdecrypt.fst',
  'obj/thirdPartyPorts/OpenSSL/poly1305/x64/X64.Poly1305.fst',
  'obj/crypto/aes/x64/X64.GHash',
  'obj/crypto/aes/x64/X64.GCTR.fst',
  'obj/crypto/aes/x64/X64.AES.fst'
]

Export('min_test_suite_blacklist')

#
# build sha256-exe
#
if do_dafny:
  sha_asm = env.ExtractValeCode(
    ['src/crypto/hashing/$SHA_ARCH_DIR/sha256.vad'],           # Vale source
    'src/crypto/hashing/$SHA_ARCH_DIR/sha256_vale_main.i.dfy', # Dafny main
    'sha256'                                                   # Base name for the ASM files and EXE
    )
  if 'KREMLIN_HOME' in os.environ:
    sha_c_h = env.ExtractDafnyCode(['src/crypto/hashing/sha256_main.i.dfy'])
    sha_include_dir = os.path.split(str(sha_c_h[0][1]))[0]
    env.BuildTest(['src/crypto/hashing/testsha256.c', sha_asm[0], sha_c_h[0][0]], sha_include_dir, 'testsha256')

#
# build cbc-exe
#
if do_dafny and (env['TARGET_ARCH']=='x86' or env['TARGET_ARCH']=='amd64'):   # x86 and x64 only
  cbc_asm = env.ExtractValeCode(
    ['src/crypto/aes/$AES_ARCH_DIR/aes.vad', 'src/crypto/aes/$AES_ARCH_DIR/cbc.vad'], # Vale source
    'src/crypto/aes/$AES_ARCH_DIR/cbc_main.i.dfy',              # Dafny main
    'cbc'                                                       # Base name for the ASM files and EXE
    )
  env.BuildTest(['src/crypto/aes/testcbc.c', cbc_asm[0]], '', 'testcbc')
else:
  print('Not building AES-CBC for this target architecture')

#
# build aes-exe
#
if do_dafny and (env['TARGET_ARCH']=='x86' or env['TARGET_ARCH']=='amd64'):   # x86 and x64 only
  aes_asm = env.ExtractValeCode(
    ['src/crypto/aes/$AES_ARCH_DIR/aes.vad'],        # Vale source
    'src/crypto/aes/$AES_ARCH_DIR/aes_main.i.dfy',   # Dafny main
    'aes'                                            # Base name for the ASM files and EXE
    )
  env.BuildTest(['src/crypto/aes/testaes.c', aes_asm[0]], 'src/crypto/aes', 'testaes')
else:
  print('Not building AES for this target architecture')

#
# build poly1305
#
if do_dafny and env['TARGET_ARCH']=='amd64' and sys.platform == "win32":     # x64-only; not yet tested on Linux
  poly1305_asm = env.ExtractValeCode(
    ['src/thirdPartyPorts/OpenSSL/poly1305/x64/poly1305.vad'],  # Vale source
    'src/crypto/poly1305/x64/poly1305_main.i.dfy',              # Dafny main
    'poly1305'                                                  # Base name for the ASM files and EXE
    )
  env.BuildTest(['src/crypto/poly1305/testpoly1305.c', poly1305_asm[0]], 'src/crypto/poly1305', 'testpoly1305')
else:
  print('Not building Poly1305 for this target architecture')

if 'KREMLIN_HOME' in os.environ:
  kremlin_path = os.environ['KREMLIN_HOME']
  kremlib_path = kremlin_path + '/kremlib'

#
# Build the OpenSSL engine
#
if do_dafny and env['OPENSSL_PATH'] != None and 'KREMLIN_HOME' in os.environ:
  engineenv = env.Clone()
  engineenv.Append(CPPPATH=[kremlib_path, '#obj/crypto/hashing', '$OPENSSL_PATH/include', '#src/lib/util'])
  cdeclenv = engineenv.Clone(CCFLAGS='/Ox /Zi /Gd /LD') # compile __cdecl so it can call OpenSSL code
  stdcallenv=engineenv.Clone(CCFLAGS='/Ox /Zi /Gz /LD') # compile __stdcall so it can call the Vale crypto code
  everest_sha256 = cdeclenv.Object('src/Crypto/hashing/EverestSha256.c')
  everest_glue = stdcallenv.Object('src/Crypto/hashing/EverestSHA256Glue.c')
  if env['TARGET_ARCH']=='x86':
    sha256_obj = engineenv.Object('obj/sha256_openssl', sha_c_h[0][0])
    cbc_obj = engineenv.Object('obj/cbc_openssl', cbc_asm[0])
    aes_obj = engineenv.Object('obj/aes_openssl', sha_asm[0])
    engine = engineenv.SharedLibrary(target='obj/EverestSha256.dll',
      source=[everest_sha256, everest_glue, sha256_obj, cbc_obj, aes_obj, '$OPENSSL_PATH/libcrypto.lib'])
  if env['TARGET_ARCH']=='amd64' and sys.platform == "win32":
    sha256_obj = engineenv.Object('obj/sha256_openssl', sha_c_h[0][0])
    sha256asm_obj = engineenv.Object('obj/sha256asm_openssl', sha_asm[0])
    poly1305_obj = engineenv.Object('obj/poly1305_openssl', poly1305_asm[0])
    engine = engineenv.SharedLibrary(target='obj/EverestSha256.dll',
      source=[everest_sha256, everest_glue, sha256_obj, sha256asm_obj, poly1305_obj, '$OPENSSL_PATH/libcrypto.lib'])

