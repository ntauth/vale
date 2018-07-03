module Interop_Printer

#set-options "--initial_fuel 4 --initial_ifuel 2 --max_fuel 4 --max_ifuel 2"

type base_type = 
  | TUInt8
  | TUInt64
  | TUInt128

type ty =
  | TBuffer of base_type
  | TBase of base_type

type arg = string * ty
type func_ty = string * list arg

type os = | Windows | Linux
type target = | X86

let calling_registers os target = match target with
  | X86 -> begin match os with
    | Windows -> ["rcx"; "rdx"; "r8"; "r9"]
    | Linux -> ["rdi"; "rsi"; "rdx"; "rcx"; "r8"; "r9"]
  end

let callee_saved os target = match target with
  | X86 -> begin match os with
    | Windows -> ["rbx"; "rbp"; "rdi"; "rsi"; "rsp"; "r12"; "r13"; "r14"; "r15"]
    | Linux -> ["rbx"; "rbp"; "r12"; "r13"; "r14"; "r15"]
  end

let print_low_nat_ty = function
  | TUInt8 -> "nat8"
  | TUInt64 -> "nat64"
  | TUInt128 -> "nat128"

let print_low_ty = function
  | TBuffer ty -> "b8"
  | TBase ty -> print_low_nat_ty ty

let rec print_low_args = function
  | [] -> "Stack unit"
  | (a, ty)::q -> a ^ ":" ^ print_low_ty ty ^ " -> " ^ print_low_args q

let rec print_low_args_and = function
  | [] -> ""
  | (a, ty)::q -> a ^ ":" ^ print_low_ty ty ^ " -> " ^ print_low_args_and q

let rec print_args_list = function
  | [] -> ""
  | (a,ty)::q -> "(" ^ a ^ ":" ^ print_low_ty ty ^ ") " ^ print_args_list q

let rec print_args_names = function
  | [] -> ""
  | (a, _)::q -> a ^ " " ^ print_args_names q  

let rec print_buffers_list = function
  | [] -> "[]"
  | (a,ty)::q -> 
    (if TBuffer? ty then a ^ "::" else "") ^
    print_buffers_list q

let is_buffer arg =
  let _, ty = arg in TBuffer? ty

let rec liveness heap args =
  let args = List.Tot.Base.filter is_buffer args in
  let rec aux heap = function
  | [] -> "True"
  | [(a,TBuffer ty)] -> "live " ^ heap ^ " " ^ a 
  | [(a, TBase ty)] -> "" // Should not happen
  | (a, TBuffer ty)::q -> "live " ^ heap ^ " " ^ a ^ " /\\ " ^ aux heap q
  | (a, TBase ty)::q -> aux heap q // Should not happen
  in aux heap args

let print_base_type = function
  | TUInt8 -> "(TBase TUInt8)"
  | TUInt64 -> "(TBase TUInt64)"
  | TUInt128 -> "(TBase TUInt128)"

let single_length_t (arg: arg) = match arg with
  | (_, TBase _) -> ""
  | (a, TBuffer ty) -> "  length_t_eq " ^ print_base_type ty ^ " " ^ a ^ ";\n"

let rec print_length_t = function
  | [] -> ""
  | a::q -> single_length_t a ^ print_length_t q

let namelist_of_args args =
  let rec aux = function
  | [] -> ""
  | [a, _] -> a
  | (a, _)::q -> a ^ ";" ^ aux q in
  "[" ^ aux args ^ "]" 

let disjoint args =
  let args = List.Tot.Base.filter is_buffer args in
  "locs_disjoint " ^ namelist_of_args args

let enough_registers os target args = 
  List.Tot.Base.length args <= List.Tot.Base.length (calling_registers os target)

let reg_to_low = function
  | "rax" -> "Rax"
  | "rbx" -> "Rbx"
  | "rcx" -> "Rcx"
  | "rdx" -> "Rdx"
  | "rsi" -> "Rsi"
  | "rdi" -> "Rdi"
  | "rbp" -> "Rbp"
  | "rsp" -> "Rsp"
  | "r8" -> "R8"
  | "r9" -> "R9"
  | "r10" -> "R10"
  | "r11" -> "R11"
  | "r12" -> "R12"
  | "r13" -> "R13"
  | "r14" -> "R14"
  | "r15" -> "R15"
  | _ -> "error"

// TODO
let print_low_calling_stack (args:list arg) =
  let rec aux (i:nat) (args:list arg) : Tot string (decreases %[args]) = match args with
    | [] -> ""
    | (a, TBase _)::q -> "  let mem = buffer_write #(TBase TUInt64) stack_b " ^ (string_of_int i) ^ " " ^ a ^ " mem in\n" ^ aux (i+1) q
    | (a, TBuffer _)::q -> "  let mem = buffer_write #(TBase TUInt64) stack_b " ^ (string_of_int i) ^ " (addrs " ^ a ^ ") mem in\n" ^ aux (i+1) q
  in aux 0 args

let print_low_calling_args os target (args:list arg) =
  let rec aux regs (args:list arg) =
  match regs, args with
    | [], q -> "    | _ -> init_regs r end in\n" ^ print_low_calling_stack q
    | _, [] -> "    | _ -> init_regs r end in\n"
    | r1::rn, (a, ty)::q -> "    | " ^ (reg_to_low r1) ^ " -> " ^ 
      (if TBuffer? ty then "addr_" ^ a else a) ^ 
      "\n" ^ aux rn q
  in aux (calling_registers os target) args

let print_low_callee_saved os target =
  let rec aux = function
    | [] -> ""
    | a::q -> "  assert(s0.regs " ^ (reg_to_low a) ^ " == s1.regs " ^ (reg_to_low a) ^ ");\n" ^ aux q
  in aux (callee_saved os target)

let rec generate_low_addrs = function
  | [] -> ""
  | (a, TBuffer _)::q -> "  let addr_" ^ a ^ " = addrs " ^ a ^ " in\n" ^ generate_low_addrs q
  | _::q -> generate_low_addrs q

let size = function
  | TUInt8 -> "1"
  | TUInt64 -> "8"
  | TUInt128 -> "16"

let print_length = function
  | (a, TBase _) -> ""
  | (a, TBuffer ty) -> "length " ^ a ^ " % " ^ (size ty) ^ " == 0"

let print_lengths args =
 let rec aux = function
 | [] -> ""
 | [a] -> print_length a
 | a::q  -> print_length a ^ " /\\ " ^ aux q
 in aux (List.Tot.Base.filter is_buffer args)

let create_state os target args stack stack_length =
  "  let buffers = " ^ (if stack then "stack_b::" else "") ^ print_buffers_list args ^ " in\n" ^
  "  let (mem:mem) = {addrs = addrs; ptrs = buffers; hs = h0} in\n" ^
  generate_low_addrs args ^
  (if stack then "  let addr_stack:nat64 = addrs stack_b + " ^ (string_of_int stack_length) ^ " in\n" else "") ^
  "  let regs = fun r -> begin match r with\n" ^
  (if stack then "    | Rsp -> addr_stack\n" else "") ^
  (print_low_calling_args os target args) ^
  "  let xmms = init_xmms in\n" ^
  "  let s0 = {ok = true; regs = regs; xmms = xmms; flags = 0; mem = mem} in\n" ^
  print_length_t args

let print_vale_bufferty = function
  | TUInt8 -> "buffer8"
  | TUInt64 -> "buffer64"
  | TUInt128 -> "buffer128"

let print_vale_ty = function
  | TUInt8 -> "nat8"
  | TUInt64 -> "nat64"  
  | TUInt128 -> "quad32"

let print_vale_full_ty = function
  | TBase ty -> print_vale_ty ty
  | TBuffer ty -> print_vale_bufferty ty

let rec print_args_vale_list = function
  | [] -> ""
  | (a,ty)::q -> "(" ^ a ^ ":" ^ print_vale_full_ty ty ^ ") " ^ print_args_vale_list q

let translate_lowstar os target (func:func_ty) =
  let name, args = func in
  let buffer_args = List.Tot.Base.filter is_buffer args in
  let nbr_stack_args = List.Tot.Base.length args - 
    List.Tot.Base.length (calling_registers os target) in
  let length_stack = nbr_stack_args `op_Multiply` 8 in
  let stack_needed = nbr_stack_args > 0 in
  let fuel_value = string_of_int (List.Tot.Base.length buffer_args + 3) in
  let implies_precond = if stack_needed then "B.length stack_b == " ^ string_of_int length_stack ^
    " /\ live h0 stack_b /\ locs_disjoint " ^ (namelist_of_args (("stack_b",TBuffer TUInt64)::buffer_args)) ^ " /\ "
  else "" in
  let stack_precond memname = if stack_needed then
    "/\ B.length stack_b == " ^ string_of_int length_stack ^
    " /\ live " ^ memname ^ " stack_b /\ locs_disjoint " ^ (namelist_of_args (("stack_b",TBuffer TUInt64)::buffer_args))
  else "" in
  let separator0 = if (List.Tot.Base.length buffer_args = 0) then "" else " /\\ " in
  let separator1 = if (List.Tot.Base.length buffer_args <= 1) then "" else " /\\ " in  
  "module Vale_" ^ name ^
  "\n\nopen X64.Machine_s\nopen X64.Memory_i\nopen X64.Vale.State_i\nopen X64.Vale.Decls_i\n\n" ^
  "val va_code_" ^ name ^ ": unit -> va_code\n\n" ^
  "//TODO: Fill this
  //va_pre and va_post should correspond to the pre- and postconditions generated by Vale\n" ^
  "let va_pre (va_b0:va_code) (va_s0:va_state)\n" ^
  (print_args_vale_list args) ^ " = True\n\n" ^
  "let va_post (va_b0:va_code) (va_s0:va_state) (va_sM:va_state) (va_fM:va_fuel)\n  " ^
  (print_args_vale_list args) ^ " = True\n\n" ^
  "val va_lemma_" ^ name ^ "(va_b0:va_code) (va_s0:va_state)\n  " ^
  (print_args_vale_list args) ^ ": Ghost ((va_sM:va_state) * (va_fM:va_fuel))\n  " ^
  "(requires va_pre va_b0 va_s0 " ^ (print_args_names args) ^ ")\n  " ^
  "(ensures (fun (va_sM, va_fM) -> va_post va_b0 va_s0 va_sM va_fM " ^ (print_args_names args) ^ "))" ^
  "\n\n\n\n" ^
  "module " ^ name ^
  "\n\nopen LowStar.Buffer\nmodule B = LowStar.Buffer\nopen LowStar.Modifies\nmodule M = LowStar.Modifies\nopen LowStar.ModifiesPat\nopen FStar.HyperStack.ST\nmodule HS = FStar.HyperStack\nopen Interop\nopen Words_s\nopen Types_s\nopen X64.Machine_s\nopen X64.Memory_i_s\nopen X64.Vale.State_i\nopen X64.Vale.Decls_i\n#set-options \"--z3rlimit 40\"\n\n" ^
  "open Vale_" ^ name ^ "\n\n" ^
  "assume val st_put (h:HS.mem) (p:HS.mem -> Type0) (f:(h0:HS.mem{p h0}) -> GTot HS.mem) : Stack unit (fun h0 -> p h0 /\ h == h0) (fun h0 _ h1 -> h == h0 /\ f h == h1)\n\n" ^
  "let b8 = B.buffer UInt8.t\n\n" ^
  "//This lemma will be available in the next version of Low*\n" ^
  "assume val buffers_disjoint (b1 b2:b8) : Lemma
  (requires M.loc_disjoint (M.loc_buffer b1) (M.loc_buffer b2))
  (ensures B.disjoint b1 b2)
  [SMTPat (B.disjoint b1 b2)]\n\n" ^
  "//The map from buffers to addresses in the heap, that remains abstract\n" ^
  "assume val addrs: addr_map\n\n" ^  
   "let rec loc_locs_disjoint_rec (l:b8) (ls:list b8) : Type0 =\n" ^
   "  match ls with\n" ^
   "  | [] -> True\n" ^
   "  | h::t -> M.loc_disjoint (M.loc_buffer l) (M.loc_buffer h) /\ loc_locs_disjoint_rec l t\n\n" ^
  "let rec locs_disjoint_rec (ls:list b8) : Type0 =\n"^
  "  match ls with\n"^
  "  | [] -> True\n" ^
  "  | h::t -> loc_locs_disjoint_rec h t /\ locs_disjoint_rec t\n\n" ^
  "unfold\nlet locs_disjoint (ls:list b8) : Type0 = normalize (locs_disjoint_rec ls)\n\n" ^
  "// TODO: Complete with your pre- and post-conditions\n" ^
  "let pre_cond (h:HS.mem) " ^ (print_args_list args) ^ "= " ^ (liveness "h" args) ^ separator1 ^ (disjoint args) ^ separator0 ^ (print_lengths args) ^ "\n" ^
  "let post_cond (h0:HS.mem) (h1:HS.mem) " ^ (print_args_list args) ^ "= " 
    ^ (liveness "h0" args) ^ " /\\ " ^ (liveness "h1" args) ^ separator0 ^ (print_lengths args) ^ "\n\n" ^
  "//The initial registers and xmms\n" ^
  "assume val init_regs:reg -> nat64\n" ^
  "assume val init_xmms:xmm -> quad32\n\n" ^
  "#set-options \"--initial_fuel " ^ fuel_value ^ " --max_fuel " ^ fuel_value ^ " --initial_ifuel 2 --max_ifuel 2\"\n" ^
  "// TODO: Prove these two lemmas if they are not proven automatically\n" ^
  "let implies_pre (h0:HS.mem) " ^ (print_args_list args) ^ 
  (if stack_needed then " (stack_b:b8) " else "") ^
  ": Lemma\n" ^
  "  (requires pre_cond h0 " ^ (print_args_names args) ^ stack_precond "h0" ^ ")\n" ^
  "  (ensures (\n" ^ implies_precond ^ "(" ^
  (create_state os target args stack_needed length_stack) ^ 
  "  va_pre (va_code_" ^ name ^ " ()) s0 " ^ (print_args_names args) ^ "))) =\n" ^
  print_length_t args ^ 
  "  ()\n\n" ^
  "let implies_post (va_s0:va_state) (va_sM:va_state) (va_fM:va_fuel) " ^ (print_args_list args) ^
  (if stack_needed then " (stack_b:b8)" else "") ^
  " : Lemma\n" ^
  "  (requires pre_cond va_s0.mem.hs " ^ (print_args_names args) ^ "/\\\n" ^
  "    va_post (va_code_" ^ name ^ " ()) va_s0 va_sM va_fM " ^ (print_args_names args) ^ ")\n" ^
  "  (ensures post_cond va_s0.mem.hs va_sM.mem.hs " ^ (print_args_names args) ^ ") =\n" ^
  print_length_t args ^
  "  ()\n\n" ^
  "val " ^ name ^ ": " ^ (print_low_args args) ^
  "\n\t(requires (fun h -> pre_cond h " ^ (print_args_names args) ^ "))\n\t" ^
  "(ensures (fun h0 _ h1 -> post_cond h0 h1 " ^ (print_args_names args) ^ "))\n\n" ^
  "val ghost_" ^ name ^ ": " ^ (print_low_args_and args) ^ 
  (if stack_needed then " stack_b:b8 -> " else "") ^
    "(h0:HS.mem{pre_cond h0 " ^ (print_args_names args) ^ 
    stack_precond "h0" ^
    "}) -> GTot (h1:HS.mem{post_cond h0 h1 " ^ (print_args_names args) ^ "})\n\n" ^
  "let ghost_" ^ name ^ " " ^ (print_args_names args) ^
  (if stack_needed then "stack_b " else "") ^ "h0 =\n" ^
  (create_state os target args stack_needed length_stack) ^
  "  implies_pre h0 " ^ (print_args_names args) ^ 
  (if stack_needed then "stack_b " else "") ^ ";\n" ^
  "  let s1, f1 = va_lemma_" ^ name ^ " (va_code_" ^ name ^ " ()) s0 " ^ print_args_names args ^ " in\n" ^
  "  // Ensures that the Vale execution was correct\n" ^
  "  assert(s1.ok);\n" ^
  "  // Ensures that the callee_saved registers are correct\n" ^
  (print_low_callee_saved os target) ^
  "  // Ensures that va_code_" ^ name ^ " is actually Vale code, and that s1 is the result of executing this code\n" ^
  "  assert (va_ensure_total (va_code_" ^ name ^ " ()) s0 s1 f1);\n" ^
  "  implies_post s0 s1 f1 " ^ (print_args_names args) ^ 
  (if stack_needed then "stack_b " else "") ^ ";\n" ^
  "  s1.mem.hs\n\n" ^
  "let " ^ name ^ " " ^ (print_args_names args) ^ " =\n" ^
  (if stack_needed then "  push_frame();\n" ^
    "  let (stack_b:b8) = B.alloca (UInt8.uint_to_t 0) (UInt32.uint_to_t " ^ string_of_int length_stack ^ ") in\n"  else "") ^
  "  let h0 = get() in\n" ^
  "  st_put h0 (fun h -> pre_cond h " ^ (print_args_names args) ^ stack_precond "h" ^ ") (ghost_" ^ name ^ " " ^ (print_args_names args) ^ 
  (if stack_needed then "stack_b);\n  pop_frame()\n" else ")\n")
  
let print_vale_arg = function
  | (a, TBuffer ty) -> "ghost " ^ a ^ ":" ^ print_vale_bufferty ty
  | (a, TBase ty) -> a ^ ":" ^ print_vale_ty ty

let rec print_vale_args = function
  | [] -> ""
  | [arg] -> print_vale_arg arg
  | arg::q -> print_vale_arg arg ^ ", " ^ print_vale_args q

let rec print_vale_loc_buff = function
  | [] -> ""
  | [(a, _)] -> "loc_buffer("^a^")"
  | (a, _)::q -> "loc_buffer("^a^"), " ^ print_vale_loc_buff q

let rec print_buff_readable = function
  | [] -> ""
  | (a, _)::q -> "        buffer_readable(mem, "^a^");\n" ^ print_buff_readable q

//TODO
let print_vale_calling_stack (args:list arg) = ""

let print_calling_args os target (args:list arg) =
  let rec aux regs (args:list arg) =
  match regs, args with
    | [], q -> print_vale_calling_stack q
    | _, [] -> ""
    | r1::rn, (a, _)::q -> "        " ^ r1 ^ " == buffer_addr(" ^ a ^ ");\n" ^ aux rn q
  in aux (calling_registers os target) args

let print_callee_saved os target =
  let rec aux = function
    | [] -> ""
    | a::q -> "        " ^ a ^ " == old(" ^ a ^ ");\n" ^ aux q
  in aux (callee_saved os target)

let translate_vale os target (func:func_ty) =
  let name, args = func in
  let args = ("stack_b", TBuffer TUInt64)::args in
  let buffer_args = List.Tot.Base.filter is_buffer args in
  let nbr_stack_args = List.Tot.Base.length args - 
    List.Tot.Base.length (calling_registers os target) in
  let length_stack = nbr_stack_args `op_Multiply` 8 in
  let stack_needed = nbr_stack_args > 0 in  
  "module Vale_" ^ name ^
  "\n#verbatim{:interface}{:implementation}\n" ^ 
  "\nopen X64.Machine_s\nopen X64.Memory_i_s\nopen X64.Vale.State_i\nopen X64.Vale.Decls_i\n#set-options \"--z3rlimit 20\"\n#endverbatim\n\n" ^
  "procedure " ^ name ^ "(" ^ print_vale_args args ^")\n" ^
  "    requires/ensures\n" ^
  "        locs_disjoint(list(" ^ print_vale_loc_buff args ^ "));\n" ^
  print_buff_readable args ^
  print_calling_args os target args ^
  "    ensures\n" ^ print_callee_saved os target ^ 
  "    modifies\n" ^
  "        rax; rbx; rcx; rdx; rsi; rdi; rbp; rsp; r8; r9; r10; r11; r12; r13; r14; r15;\n" ^
  "        mem;\n"^
  "{\n\n}\n"
