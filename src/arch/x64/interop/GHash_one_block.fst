module GHash_one_block

open LowStar.Buffer
module B = LowStar.Buffer
module BV = LowStar.BufferView
open LowStar.Modifies
module M = LowStar.Modifies
open LowStar.ModifiesPat
open FStar.HyperStack.ST
module HS = FStar.HyperStack
open Interop
open Words_s
open Types_s
open X64.Machine_s
open X64.Memory_i_s
open X64.Vale.State_i
open X64.Vale.Decls_i
open GHash_i
#set-options "--z3rlimit 40"

open Vale_ghash_incremental_one_block_buffer

assume val st_put (h:HS.mem) (p:HS.mem -> Type0) (f:(h0:HS.mem{p h0}) -> GTot HS.mem) : Stack unit (fun h0 -> p h0 /\ h == h0) (fun h0 _ h1 -> h == h0 /\ f h == h1)

let b8 = B.buffer UInt8.t

//The map from buffers to addresses in the heap, that remains abstract
assume val addrs: addr_map

let rec loc_locs_disjoint_rec (l:b8) (ls:list b8) : Type0 =
  match ls with
  | [] -> True
  | h::t -> M.loc_disjoint (M.loc_buffer l) (M.loc_buffer h) /\ loc_locs_disjoint_rec l t

let rec locs_disjoint_rec (ls:list b8) : Type0 =
  match ls with
  | [] -> True
  | h::t -> loc_locs_disjoint_rec h t /\ locs_disjoint_rec t

unfold
let locs_disjoint (ls:list b8) : Type0 = normalize (locs_disjoint_rec ls)

open FStar.Mul


let buffer_to_quad32 (b:B.buffer UInt8.t { B.length b % 16 == 0 /\ B.length b > 0 }) (h:HS.mem) : GTot quad32 =
  let b128 = BV.mk_buffer_view b Views.view128 in
  BV.as_buffer_mk_buffer_view b Views.view128;
  BV.get_view_mk_buffer_view b Views.view128;
  BV.length_eq b128;
  assert (B.length b >= 16);
  assert (BV.length b128 > 0);
  BV.sel h b128 0
  //index (BV.as_seq h b128) 0

let buffer_to_seq_quad32 (b:B.buffer UInt8.t { B.length b % 16 == 0 }) (h:HS.mem) : GTot (s:Seq.seq quad32 {Seq.length s == B.length b / 16} ) =
  let b128 = BV.mk_buffer_view b Views.view128 in
  BV.as_buffer_mk_buffer_view b Views.view128;
  BV.get_view_mk_buffer_view b Views.view128;
  BV.length_eq b128;
  (BV.as_seq h b128)

// TODO: Complete with your pre- and post-conditions
let pre_cond (h:HS.mem) (h_b:b8) (hash_b:b8) (input_b:b8) (offset:nat64) = live h h_b /\ live h hash_b /\ live h input_b /\ locs_disjoint [h_b;hash_b;input_b] /\ length h_b % 16 == 0 /\ length hash_b % 16 == 0 /\ length input_b % 16 == 0 /\
  B.length h_b >= 16 /\ B.length hash_b >= 16 /\ B.length input_b >= 16 * (offset + 1)

let post_cond (h:HS.mem) (h':HS.mem) (h_b:b8) (hash_b:b8) (input_b:b8) (offset:nat64) = length h_b % 16 == 0 /\ length hash_b % 16 == 0 /\ length input_b % 16 == 0 /\
 B.length h_b >= 16 /\ B.length hash_b >= 16 /\ B.length input_b >= 16 * (offset + 1) /\
    M.modifies (M.loc_buffer hash_b) h h' /\
    (let old_hash = buffer_to_quad32 hash_b h  in
     let new_hash = buffer_to_quad32 hash_b h' in
     let h_q      = buffer_to_quad32 h_b    h  in
     let input    = buffer_to_seq_quad32 input_b h in
     let input_quad = Seq.index input offset in
     new_hash == ghash_incremental h_q old_hash (Seq.create 1 input_quad)
    )
  

//The initial registers and xmms
assume val init_regs:reg -> nat64
assume val init_xmms:xmm -> quad32

#set-options "--initial_fuel 6 --max_fuel 6 --initial_ifuel 2 --max_ifuel 2"
// TODO: Prove these two lemmas if they are not proven automatically
let implies_pre (h0:HS.mem) (h_b:b8) (hash_b:b8) (input_b:b8) (offset:nat64) : Lemma
  (requires pre_cond h0 h_b hash_b input_b offset )
  (ensures (
(  let buffers = h_b::hash_b::input_b::[] in
  let (mem:mem) = {addrs = addrs; ptrs = buffers; hs = h0} in
  let addr_h_b = addrs h_b in
  let addr_hash_b = addrs hash_b in
  let addr_input_b = addrs input_b in
  let regs = fun r -> begin match r with
    | Rdi -> addr_h_b
    | Rsi -> addr_hash_b
    | Rdx -> addr_input_b
    | Rcx -> offset
    | _ -> init_regs r end in
  let xmms = init_xmms in
  let s0 = {ok = true; regs = regs; xmms = xmms; flags = 0; mem = mem} in
  length_t_eq (TBase TUInt128) h_b;
  length_t_eq (TBase TUInt128) hash_b;
  length_t_eq (TBase TUInt128) input_b;
  va_pre (va_code_ghash_incremental_one_block_buffer ()) s0 h_b hash_b input_b offset ))) =
  length_t_eq (TBase TUInt128) h_b;
  length_t_eq (TBase TUInt128) hash_b;
  length_t_eq (TBase TUInt128) input_b;
  ()

let implies_post (va_s0:va_state) (va_sM:va_state) (va_fM:va_fuel) (h_b:b8) (hash_b:b8) (input_b:b8) (offset:nat64)  : Lemma
  (requires pre_cond va_s0.mem.hs h_b hash_b input_b offset /\
    va_post (va_code_ghash_incremental_one_block_buffer ()) va_s0 va_sM va_fM h_b hash_b input_b offset )
  (ensures post_cond va_s0.mem.hs va_sM.mem.hs h_b hash_b input_b offset ) =
  length_t_eq (TBase TUInt128) h_b;
  length_t_eq (TBase TUInt128) hash_b;
  length_t_eq (TBase TUInt128) input_b;
  let h128_b = BV.mk_buffer_view h_b Views.view128 in
  assert (Seq.equal (buffer_as_seq (va_get_mem va_s0) h_b) (BV.as_seq va_s0.mem.hs h128_b));
  BV.as_seq_sel va_s0.mem.hs h128_b 0;  
  let hash128_b = BV.mk_buffer_view hash_b Views.view128 in
  assert (Seq.equal (buffer_as_seq (va_get_mem va_s0) hash_b) (BV.as_seq va_s0.mem.hs hash128_b));
  BV.as_seq_sel va_s0.mem.hs hash128_b 0;  
  let hash128_b = BV.mk_buffer_view hash_b Views.view128 in
  assert (Seq.equal (buffer_as_seq (va_get_mem va_sM) hash_b) (BV.as_seq va_sM.mem.hs hash128_b));
  BV.as_seq_sel va_sM.mem.hs hash128_b 0;  
  assert (Seq.equal (buffer_to_seq_quad32 input_b va_s0.mem.hs) (buffer128_as_seq (va_get_mem va_s0) input_b));  
  ()

val ghash_incremental_one_block_buffer: h_b:b8 -> hash_b:b8 -> input_b:b8 -> offset:nat64 -> Stack unit
	(requires (fun h -> pre_cond h h_b hash_b input_b offset ))
	(ensures (fun h0 _ h1 -> post_cond h0 h1 h_b hash_b input_b offset ))

val ghost_ghash_incremental_one_block_buffer: h_b:b8 -> hash_b:b8 -> input_b:b8 -> offset:nat64 -> (h0:HS.mem{pre_cond h0 h_b hash_b input_b offset }) -> GTot (h1:HS.mem{post_cond h0 h1 h_b hash_b input_b offset })

let ghost_ghash_incremental_one_block_buffer h_b hash_b input_b offset h0 =
  let buffers = h_b::hash_b::input_b::[] in
  let (mem:mem) = {addrs = addrs; ptrs = buffers; hs = h0} in
  let addr_h_b = addrs h_b in
  let addr_hash_b = addrs hash_b in
  let addr_input_b = addrs input_b in
  let regs = fun r -> begin match r with
    | Rdi -> addr_h_b
    | Rsi -> addr_hash_b
    | Rdx -> addr_input_b
    | Rcx -> offset
    | _ -> init_regs r end in
  let xmms = init_xmms in
  let s0 = {ok = true; regs = regs; xmms = xmms; flags = 0; mem = mem} in
  length_t_eq (TBase TUInt128) h_b;
  length_t_eq (TBase TUInt128) hash_b;
  length_t_eq (TBase TUInt128) input_b;
  implies_pre h0 h_b hash_b input_b offset ;
  let s1, f1 = va_lemma_ghash_incremental_one_block_buffer (va_code_ghash_incremental_one_block_buffer ()) s0 h_b hash_b input_b offset  in
  // Ensures that the Vale execution was correct
  assert(s1.ok);
  // Ensures that the callee_saved registers are correct
  assert(s0.regs Rbx == s1.regs Rbx);
  assert(s0.regs Rbp == s1.regs Rbp);
  assert(s0.regs R12 == s1.regs R12);
  assert(s0.regs R13 == s1.regs R13);
  assert(s0.regs R14 == s1.regs R14);
  assert(s0.regs R15 == s1.regs R15);
  // Ensures that va_code_ghash_incremental_one_block_buffer is actually Vale code, and that s1 is the result of executing this code
  assert (va_ensure_total (va_code_ghash_incremental_one_block_buffer ()) s0 s1 f1);
  implies_post s0 s1 f1 h_b hash_b input_b offset ;
  s1.mem.hs

let ghash_incremental_one_block_buffer h_b hash_b input_b offset  =
  let h0 = get() in
  st_put h0 (fun h -> pre_cond h h_b hash_b input_b offset ) (ghost_ghash_incremental_one_block_buffer h_b hash_b input_b offset )
