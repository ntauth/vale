module X64.Vale.Decls_i
open X64.Machine_s
open X64.Vale
open X64.Vale.State_i
open X64.Vale.StateLemmas_i
open FStar.UInt
module S = X64.Semantics_s
module P = X64.Print_s
module BS = X64.Bytes_Semantics_s
module TS = X64.Taint_Semantics_s

#reset-options "--z3cliopt smt.arith.nl=true"
let lemma_mul_in_bounds (x y:nat64) : Lemma (requires x `op_Multiply` y < pow2_64) (ensures FStar.UInt.mul_mod #64 x y == x `op_Multiply` y) = ()

#reset-options "--z3cliopt smt.arith.nl=true --using_facts_from Prims --using_facts_from FStar.Math"
let lemma_mul_nat (x:nat) (y:nat) : Lemma (ensures 0 <= (x `op_Multiply` y)) = ()
#reset-options "--initial_fuel 2 --max_fuel 2"

let cf = Lemmas_i.cf
let overflow = Lemmas_i.overflow
let update_cf = Lemmas_i.update_cf
let update_of = Lemmas_i.update_of
let ins = TS.tainted_ins
type ocmp = TS.tainted_ocmp
type va_fuel = nat
let va_fuel_default () = 0

let va_opr_lemma_Mem (s:va_state) (base:va_operand) (offset:int) (b:M.buffer64) (index:int) (t:taint) =
  let t = va_opr_code_Mem base offset t in
  M.lemma_valid_mem64 b index s.mem;
  let TMem m t = t in
  assert (valid_maddr (eval_maddr m s) s.mem s.memTaint b index t)

let taint_at memTaint addr = Map.sel memTaint addr

let va_cmp_eq o1 o2 = TS.TaintedOCmp (BS.OEq (t_op_to_op o1) (t_op_to_op o2)) Public
let va_cmp_ne o1 o2 = TS.TaintedOCmp (BS.ONe (t_op_to_op o1) (t_op_to_op o2)) Public
let va_cmp_le o1 o2 = TS.TaintedOCmp (BS.OLe (t_op_to_op o1) (t_op_to_op o2)) Public
let va_cmp_ge o1 o2 = TS.TaintedOCmp (BS.OGe (t_op_to_op o1) (t_op_to_op o2)) Public
let va_cmp_lt o1 o2 = TS.TaintedOCmp (BS.OLt (t_op_to_op o1) (t_op_to_op o2)) Public
let va_cmp_gt o1 o2 = TS.TaintedOCmp (BS.OGt (t_op_to_op o1) (t_op_to_op o2)) Public

let eval_code = Lemmas_i.eval_code
let eval_while_inv = Lemmas_i.eval_while_inv
let eval_ocmp = Lemmas_i.eval_ocmp
let valid_ocmp = Lemmas_i.valid_ocmp

unfold let va_eval_ins = Lemmas_i.eval_ins

let lemma_cmp_eq s o1 o2 = ()
let lemma_cmp_ne s o1 o2 = ()
let lemma_cmp_le s o1 o2 = ()
let lemma_cmp_ge s o1 o2 = ()
let lemma_cmp_lt s o1 o2 = ()
let lemma_cmp_gt s o1 o2 = ()

let lemma_valid_cmp_eq s o1 o2 = ()
let lemma_valid_cmp_ne s o1 o2 = ()
let lemma_valid_cmp_le s o1 o2 = ()
let lemma_valid_cmp_ge s o1 o2 = ()
let lemma_valid_cmp_lt s o1 o2 = ()
let lemma_valid_cmp_gt s o1 o2 = ()

let va_compute_merge_total = Lemmas_i.compute_merge_total
let va_lemma_merge_total b0 s0 f0 sM fM sN = Lemmas_i.lemma_merge_total b0 s0 f0 sM fM sN; Lemmas_i.compute_merge_total f0 fM
let va_lemma_empty_total = Lemmas_i.lemma_empty_total
let va_lemma_ifElse_total = Lemmas_i.lemma_ifElse_total
let va_lemma_ifElseTrue_total = Lemmas_i.lemma_ifElseTrue_total
let va_lemma_ifElseFalse_total = Lemmas_i.lemma_ifElseFalse_total
let va_lemma_while_total = Lemmas_i.lemma_while_total
let va_lemma_whileTrue_total = Lemmas_i.lemma_whileTrue_total
let va_lemma_whileFalse_total = Lemmas_i.lemma_whileFalse_total
let va_lemma_whileMerge_total = Lemmas_i.lemma_whileMerge_total

let printer = P.printer
let print_string = FStar.IO.print_string
let print_header = P.print_header
let print_proc = P.print_proc
let print_footer = P.print_footer
let masm = P.masm
let gcc = P.gcc