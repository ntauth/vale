module Vale_aes128_encrypt_block_be_win


open FStar.Seq
open X64.Machine_s
open X64.Memory_i
open X64.Vale.State_i
open X64.Vale.Decls_i
open AES_s
open Types_i
//open AES_helpers_i
open AES256_helpers_i
//open Opaque_s
open X64.AES128
open X64.AES256
open X64.AES
open GCTR_i

let is_win = true

val va_code_aes128_encrypt_block_be_win: unit -> va_code
let va_code_aes128_encrypt_block_be_win () = va_code_AESEncryptBlockStdcall_BE is_win AES_128

let vale_pre (va_b0:va_code) (va_s0:va_state) (win:bool) (alg:algorithm)
  (input:quad32) (key:(aes_key_LE alg)) (input_buffer:buffer128) (output_buffer:buffer128)
  (keys_buffer:buffer128) =
((va_require_total va_b0 (va_code_AESEncryptBlockStdcall_BE win alg) va_s0) /\
    (va_get_ok va_s0) /\ (let output_ptr = (if win then (va_get_reg Rcx va_s0) else (va_get_reg Rdi
    va_s0)) in let input_ptr = (if win then (va_get_reg Rdx va_s0) else (va_get_reg Rsi va_s0)) in
    let expanded_key_ptr = (if win then (va_get_reg R8 va_s0) else (va_get_reg Rdx va_s0)) in
    (locs_disjoint [(loc_buffer input_buffer); (loc_buffer keys_buffer)]) /\ (locs_disjoint
    [(loc_buffer output_buffer); (loc_buffer keys_buffer)]) /\ (l_or (buffers_disjoint128
    output_buffer input_buffer) (output_buffer == input_buffer)) /\ (alg = AES_128 || alg =
    AES_256) /\ (buffer128_read input_buffer 0 (va_get_mem va_s0)) == input /\ expanded_key_ptr ==
    (buffer_addr keys_buffer (va_get_mem va_s0)) /\ (validSrcAddrs128 (va_get_mem va_s0) input_ptr
    input_buffer 1 (va_get_memTaint va_s0) Secret) /\ (validSrcAddrs128 (va_get_mem va_s0)
    output_ptr output_buffer 1 (va_get_memTaint va_s0) Secret) /\ (validSrcAddrs128 (va_get_mem
    va_s0) expanded_key_ptr keys_buffer ((nr alg) + 1) (va_get_memTaint va_s0) Secret) /\ (forall
    (i:int) . (0 <= i && i < (nr alg) + 1) ==> (buffer128_read keys_buffer i (va_get_mem va_s0)) ==
    (index (key_to_round_keys_LE alg key) i))))


  //va_pre and va_post should correspond to the pre- and postconditions generated by Vale
let va_pre (va_b0:va_code) (va_s0:va_state) (stack_b:buffer64)
(output_b:buffer128) (input_b:buffer128) (key:(aes_key_LE AES_128)) (keys_b:buffer128)  =
  vale_pre va_b0 va_s0 is_win AES_128 (buffer128_read input_b 0 va_s0.mem) key input_b output_b keys_b

let vale_post (va_b0:va_code) (va_s0:va_state) (win:bool) (alg:algorithm)
  (input:quad32) (key:(aes_key_LE alg)) (input_buffer:buffer128) (output_buffer:buffer128)
  (keys_buffer:buffer128) (va_sM:va_state) (va_fM:va_fuel) =
  ((va_ensure_total va_b0 va_s0 va_sM va_fM) /\ (va_get_ok va_sM)
    /\ (let output_ptr = (if win then (va_get_reg Rcx va_s0) else (va_get_reg Rdi va_s0)) in let
    input_ptr = (if win then (va_get_reg Rdx va_s0) else (va_get_reg Rsi va_s0)) in let
    expanded_key_ptr = (if win then (va_get_reg R8 va_s0) else (va_get_reg Rdx va_s0)) in
    (modifies_mem (loc_buffer output_buffer) (va_get_mem va_s0) (va_get_mem va_sM)) /\
    (validSrcAddrs128 (va_get_mem va_sM) output_ptr output_buffer 1 (va_get_memTaint va_sM) Secret)
    /\ (buffer128_read output_buffer 0 (va_get_mem va_sM)) == (aes_encrypt_BE alg key input)) /\
    (va_state_eq va_sM ((va_update_flags va_sM (va_update_xmm 2 va_sM
    (va_update_xmm 0 va_sM (va_update_mem va_sM (va_update_reg Rax va_sM (va_update_reg R8 va_sM
    (va_update_ok va_sM va_s0))))))))))

let va_post (va_b0:va_code) (va_s0:va_state) (va_sM:va_state) (va_fM:va_fuel) (stack_b:buffer64)
  (output_b:buffer128) (input_b:buffer128) (key:(aes_key_LE AES_128)) (keys_b:buffer128) =
  vale_post va_b0 va_s0 is_win AES_128
    (buffer128_read input_b 0 va_s0.mem) key input_b output_b keys_b va_sM va_fM

val va_lemma_aes128_encrypt_block_be_win(va_b0:va_code) (va_s0:va_state) (stack_b:buffer64)
  (output_b:buffer128) (input_b:buffer128) (key:(aes_key_LE AES_128)) (keys_b:buffer128) : Ghost ((va_sM:va_state) * (va_fM:va_fuel))
  (requires va_pre va_b0 va_s0 stack_b output_b input_b key keys_b )
  (ensures (fun (va_sM, va_fM) -> va_post va_b0 va_s0 va_sM va_fM stack_b output_b input_b key keys_b ))

let va_lemma_aes128_encrypt_block_be_win va_b0 va_s0 stack_b output_b input_b key keys_b =
  let input = buffer128_read input_b 0 va_s0.mem in
  va_lemma_AESEncryptBlockStdcall_BE va_b0 va_s0 is_win AES_128 input key input_b output_b keys_b

