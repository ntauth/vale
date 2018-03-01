module GCTR_s

open Types_s
open FStar.Mul
open AES_s
open FStar.List.Tot.Base

type gctr_plain = p:list quad32 { 256 * length p < nat32_max }

let inc32 (cb:quad32) (i:int) = 
  Quad32 ((cb.lo + i) % nat32_max) cb.mid_lo cb.mid_hi cb.hi

let rec gctr_encrypt_recursive (icb:quad32) (plain:gctr_plain) 
			       (alg:algorithm) (key:aes_key alg) (i:int) =
  match plain with
  | [] -> []
  | hd :: tl -> (quad32_xor hd (aes_encrypt alg key (inc32 icb i))) :: (gctr_encrypt_recursive icb tl alg key (i + 1))
  
// length plain < nat32_max / 256 <= spec max of 2**39 - 256;
let gctr_encrypt (icb:quad32) (plain:gctr_plain) (alg:algorithm) (key:aes_key alg) =
  gctr_encrypt_recursive icb plain alg key 0
  