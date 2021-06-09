// Dafny program verifier version 1.9.9.40418, Copyright (c) 2003-2017, Microsoft.
// Command Line Options: /trace /compile:3 /dprint:demo.dfy ././demoX86.dfy
// demoX86.vad

function {:opaque} f(i: int): int
{
  i + 1
}

function method {:opaque} va_code_mov(x: va_operand_reg32, y: va_operand_opr32): va_code
{
  Ins(Mov(x, y))
}

lemma va_lemma_mov(va_b0: va_codes, va_s0: va_state, va_sN: va_state, x: va_operand_reg32, y: va_operand_opr32)
    returns (va_bM: va_codes, va_sM: va_state)
  requires va_require(va_b0, va_code_mov(x, y), va_s0, va_sN)
  requires va_is_dst_reg32(x, va_s0)
  requires va_is_src_opr32(y, va_s0)
  requires va_get_ok(va_s0)
  ensures va_ensure(va_b0, va_bM, va_s0, va_sM, va_sN)
  ensures va_get_ok(va_sM)
  ensures va_eval_reg32(va_sM, x) == va_eval_opr32(va_s0, y)
  ensures va_state_eq(va_sM, va_modify_ok(va_sM, va_update_reg32(x, va_sM, va_s0)))
{
  reveal_va_code_mov();
  var va_old_s: va_state := va_s0;
  ghost var va_ltmp1, va_cM: va_code, va_ltmp2 := va_lemma_block(va_b0, va_s0, va_sN);
  va_sM := va_ltmp1;
  va_bM := va_ltmp2;
}

function method {:opaque} va_code_add(x: va_operand_reg32, y: va_operand_opr32): va_code
{
  Ins(Add(x, y))
}

lemma va_lemma_add(va_b0: va_codes, va_s0: va_state, va_sN: va_state, x: va_operand_reg32, y: va_operand_opr32)
    returns (va_bM: va_codes, va_sM: va_state)
  requires va_require(va_b0, va_code_add(x, y), va_s0, va_sN)
  requires va_is_dst_reg32(x, va_s0)
  requires va_is_src_opr32(y, va_s0)
  requires va_get_ok(va_s0)
  requires va_eval_reg32(va_s0, x) + va_eval_opr32(va_s0, y) < 4294967296
  ensures va_ensure(va_b0, va_bM, va_s0, va_sM, va_sN)
  ensures va_get_ok(va_sM)
  ensures va_eval_reg32(va_sM, x) == va_eval_reg32(va_s0, x) + va_eval_opr32(va_s0, y)
  ensures va_state_eq(va_sM, va_modify_ok(va_sM, va_update_reg32(x, va_sM, va_s0)))
{
  reveal_va_code_add();
  var va_old_s: va_state := va_s0;
  ghost var va_ltmp1, va_cM: va_code, va_ltmp2 := va_lemma_block(va_b0, va_s0, va_sN);
  va_sM := va_ltmp1;
  va_bM := va_ltmp2;
}

function method {:opaque} va_code_Demo(i: uint32): va_code
{
  va_Block(va_CCons(va_code_add(va_op_reg32_reg(EBX), va_const_opr32(i)), va_CCons(va_code_add(va_op_reg32_reg(EBX), va_const_opr32(i)), va_CCons(if i > 0 then va_Block(va_CCons(va_code_Demo(i - 1), va_CNil())) else va_Block(va_CNil()), va_CNil()))))
}

lemma {:recursive} va_lemma_Demo(va_b0: va_codes, va_s0: va_state, va_sN: va_state, i: uint32)
    returns (va_bM: va_codes, va_sM: va_state)
  requires va_require(va_b0, va_code_Demo(i), va_s0, va_sN)
  requires va_get_ok(va_s0)
  requires i < 1000
  requires va_get_reg(EBX, va_s0) < 1073741824 - 2000 * i
  ensures va_ensure(va_b0, va_bM, va_s0, va_sM, va_sN)
  ensures va_get_ok(va_sM)
  ensures va_get_reg(EBX, va_sM) >= va_get_reg(EBX, va_s0)
  ensures va_state_eq(va_sM, va_modify_reg(EBX, va_sM, va_modify_ok(va_sM, va_s0)))
{
  reveal_va_code_Demo();
  var va_old_s: va_state := va_s0;
  ghost var va_ltmp1, va_cM: va_code, va_ltmp2 := va_lemma_block(va_b0, va_s0, va_sN);
  va_sM := va_ltmp1;
  va_bM := va_ltmp2;
  var va_b1: va_codes := va_get_block(va_cM);
  ghost var va_b2, va_s2 := va_lemma_add(va_b1, va_s0, va_sM, va_op_reg32_reg(EBX), va_const_opr32(i));
  ghost var va_b3, va_s3 := va_lemma_add(va_b2, va_s2, va_sM, va_op_reg32_reg(EBX), va_const_opr32(i));
  ghost var va_s4, va_c4, va_b4 := va_lemma_block(va_b3, va_s3, va_sM);
  if i > 0 {
    ghost var va_b5 := va_get_block(va_c4);
    ghost var va_b6, va_s6 := va_lemma_Demo(va_b5, va_s3, va_s4, i - 1);
    va_s4 := va_lemma_empty(va_s6, va_s4);
  } else {
    ghost var va_b7 := va_get_block(va_c4);
    va_s4 := va_lemma_empty(va_s3, va_s4);
  }
  va_sM := va_lemma_empty(va_s4, va_sM);
}

function method {:opaque} va_code_TestCalc(): va_code
{
  va_Block(va_CNil())
}

lemma va_lemma_TestCalc(va_b0: va_codes, va_s0: va_state, va_sN: va_state)
    returns (va_bM: va_codes, va_sM: va_state)
  requires va_require(va_b0, va_code_TestCalc(), va_s0, va_sN)
  requires va_get_ok(va_s0)
  ensures va_ensure(va_b0, va_bM, va_s0, va_sM, va_sN)
  ensures va_get_ok(va_sM)
  ensures f(f(0)) == 2
  ensures va_state_eq(va_sM, va_modify_ok(va_sM, va_s0))
{
  reveal_va_code_TestCalc();
  var va_old_s: va_state := va_s0;
  ghost var va_ltmp1, va_cM: va_code, va_ltmp2 := va_lemma_block(va_b0, va_s0, va_sN);
  va_sM := va_ltmp1;
  va_bM := va_ltmp2;
  var va_b1: va_codes := va_get_block(va_cM);
  calc == {
    f(f(0));
  ==
    {
      reveal_f();
    }
    f(0) + 1;
  ==
    {
      reveal_f();
    }
    2;
  }
  va_sM := va_lemma_empty(va_s0, va_sM);
}

method PrintDemo(asm: AsmTarget, platform: PlatformTarget)
{
  printHeader(asm);
  printProc("demo", va_code_Demo(999), 0, 0, "", asm, platform);
  printFooter(asm);
}

method Main()
{
  PrintDemo(GCC, Linux);
}

function {:opaque} empty_reg(): uint32
{
  0
}

function eval_reg(r: reg, s: state): uint32
{
  if r in s.regs then
    s.regs[r]
  else
    empty_reg()
}

function eval_mem(ptr: int, s: state): uint32
{
  if ptr in s.mem then
    s.mem[ptr]
  else
    empty_reg()
}

function update_reg(r: reg, s: state, i: uint32): state
{
  s.(regs := s.regs[r := i])
}

function update_mem(ptr: int, s: state, i: uint32): state
{
  s.(mem := s.mem[ptr := i])
}

function eval_opr(o: opr, s: state): uint32
{
  match o
  case OReg(r) =>
    eval_reg(r, s)
  case OConst(n) =>
    n
}

function update_opr(o: opr, s: state, i: uint32): state
{
  match o
  case OReg(r) =>
    update_reg(r, s, i)
  case OConst(o) =>
    s.(ok := false)
}

function eval_mem_opr(o: mem_opr, s: state): uint32
{
  match o
  case OMem(base, offset) =>
    eval_mem(eval_reg(base, s) + offset, s)
  case OOpr(o) =>
    eval_opr(o, s)
}

function update_mem_opr(o: mem_opr, s: state, i: uint32): state
{
  match o
  case OMem(base, offset) =>
    update_mem(eval_reg(base, s) + offset, s, i)
  case OOpr(o) =>
    update_opr(o, s, i)
}

predicate mem_opr_ok(o: mem_opr, s: state)
{
  match o
  case OMem(base, offset) =>
    eval_reg(base, s) + offset in s.mem
  case OOpr(o) =>
    true
}

predicate eval_ocmp(s: state, c: ocmp)
{
  match c
  case OLe(o1, o2) =>
    eval_opr(o1, s) <= eval_opr(o2, s)
}

predicate eval_ins(ins: ins, s0: state, sN: state)
{
  if s0.ok then
    match ins
    case Mov(dst, src) =>
      sN == update_reg(dst, s0, eval_opr(src, s0))
    case Add(dst, src) =>
      sN == update_reg(dst, s0, (eval_reg(dst, s0) + eval_opr(src, s0)) % 4294967296)
  else
    !sN.ok
}

predicate eval_block(block: codes, s0: state, sN: state)
{
  match block
  case CNil =>
    s0 == sN
  case CCons(h, t) =>
    exists s1 :: 
      eval_code(h, s0, s1) &&
      eval_block(t, s1, sN)
}

predicate eval_while(b: ocmp, c: code, n: nat, s0: state, sN: state)
  decreases c, n
{
  if n == 0 then
    !eval_ocmp(s0, b) &&
    s0 == sN
  else
    exists s1: state :: eval_ocmp(s0, b) && eval_code(c, s0, s1) && if s1.ok then eval_while(b, c, n - 1, s1, sN) else s1 == sN
}

predicate eval_code(c: code, s0: state, sN: state)
  decreases c, 0
{
  match c
  case Ins(ins) =>
    eval_ins(ins, s0, sN)
  case Block(block) =>
    eval_block(block, s0, sN)
  case IfElse(cond, ifT, ifF) =>
    if eval_ocmp(s0, cond) then
      eval_code(ifT, s0, sN)
    else
      eval_code(ifF, s0, sN)
  case While(cond, body) =>
    exists n: nat :: 
      eval_while(cond, body, n, s0, sN)
}

function va_get_ok(s: va_state): bool
{
  s.ok
}

function va_get_reg(r: reg, s: va_state): uint32
{
  eval_reg(r, s)
}

function va_get_mem(s: va_state): map<int, int>
{
  s.mem
}

function va_modify_ok(sM: va_state, sK: va_state): va_state
{
  sK.(ok := sM.ok)
}

function va_modify_reg(r: reg, sM: va_state, sK: va_state): va_state
{
  sK.(regs := sK.regs[r := va_get_reg(r, sM)])
}

function va_modify_mem(sM: va_state, sK: va_state): va_state
{
  sK.(mem := sM.mem)
}

function method va_op_register_reg(r: reg): va_register
{
  r
}

function method va_op_reg_reg(r: reg): va_register
{
  r
}

predicate va_is_src_reg32(r: reg, s: va_state)
{
  true
}

predicate va_is_dst_reg32(r: reg, s: va_state)
{
  true
}

function va_update_register(r: reg, sM: va_state, sK: va_state): va_state
{
  va_modify_reg(r, sM, sK)
}

function va_eval_reg32(s: va_state, r: va_register): uint32
{
  eval_reg(r, s)
}

function method va_op_operand_reg(r: reg): va_operand
{
  OReg(r)
}

function method va_op_opr_reg(r: reg): va_operand
{
  OReg(r)
}

predicate va_is_src_opr32(o: opr, s: va_state)
{
  true
}

predicate va_is_dst_opr32(o: opr, s: va_state)
{
  o.OReg?
}

function method va_const_opr32(x: uint32): va_operand
{
  OConst(x)
}

function va_update_opr32(o: opr, sM: va_state, sK: va_state): va_state
  requires o.OReg?
{
  va_modify_reg(o.r, sM, sK)
}

function va_eval_opr32(s: va_state, o: va_operand): uint32
{
  eval_opr(o, s)
}

function method va_op_mem_opr_reg(r: reg): va_mem_operand
{
  OOpr(OReg(r))
}

function method va_op_mem_opr(o: opr): va_mem_operand
{
  OOpr(o)
}

predicate va_is_src_mem32(o: mem_opr, s: va_state)
{
  mem_opr_ok(o, s)
}

predicate va_is_dst_mem32(o: mem_opr, s: va_state)
{
  mem_opr_ok(o, s) &&
  (o.OOpr? ==>
    o.o.OReg?)
}

function method va_mem_const_operand(x: uint32): va_mem_operand
{
  OOpr(OConst(x))
}

function va_update_mem_opr(o: mem_opr, sM: va_state, sK: va_state): va_state
  requires o.OOpr? ==> o.o.OReg?
{
  match o
  case OMem(base, offset) =>
    sK.(mem := sK.mem[eval_reg(base, sK) + offset := eval_mem_opr(o, sM)])
  case OOpr(o) =>
    va_modify_reg(o.r, sM, sK)
}

function va_eval_mem32(s: va_state, o: va_mem_operand): uint32
{
  eval_mem_opr(o, s)
}

function method va_op_cmp_reg(r: reg): va_cmp
{
  OReg(r)
}

function method va_const_cmp(x: uint32): va_cmp
{
  OConst(x)
}

function va_eval_cmp_uint32(s: va_state, r: va_cmp): uint32
{
  eval_opr(r, s)
}

function method va_coerce_register_to_operand(r: va_register): va_operand
{
  OReg(r)
}

function method va_CNil(): va_codes
{
  CNil()
}

function method va_CCons(hd: va_code, tl: va_codes): va_codes
{
  CCons(hd, tl)
}

function method va_Block(block: va_codes): va_code
{
  Block(block)
}

function method va_IfElse(ifCond: ocmp, ifTrue: va_code, ifFalse: va_code): va_code
{
  IfElse(ifCond, ifTrue, ifFalse)
}

function method va_While(whileCond: ocmp, whileBody: va_code): va_code
{
  While(whileCond, whileBody)
}

function method va_cmp_le(a: va_operand, b: va_operand): ocmp
{
  OLe(a, b)
}

function va_get_block(c: va_code): va_codes
  requires c.Block?
{
  c.block
}

function va_get_ifCond(c: code): ocmp
  requires c.IfElse?
{
  c.ifCond
}

function va_get_ifTrue(c: code): code
  requires c.IfElse?
{
  c.ifTrue
}

function va_get_ifFalse(c: code): code
  requires c.IfElse?
{
  c.ifFalse
}

function va_get_whileCond(c: code): ocmp
  requires c.While?
{
  c.whileCond
}

function va_get_whileBody(c: code): code
  requires c.While?
{
  c.whileBody
}

predicate va_state_eq(s0: va_state, s1: va_state)
{
  s0.ok == s1.ok &&
  s0.regs == s1.regs &&
  s0.mem == s1.mem
}

predicate va_require(block0: va_codes, c: va_code, s0: va_state, sN: va_state)
{
  block0.CCons? &&
  block0.hd == c &&
  eval_code(va_Block(block0), s0, sN) &&
  forall r: reg :: 
    r in s0.regs
}

predicate va_ensure(b0: va_codes, b1: va_codes, s0: va_state, s1: va_state, sN: va_state)
{
  b0.CCons? &&
  b0.tl == b1 &&
  eval_code(b0.hd, s0, s1) &&
  eval_code(va_Block(b1), s1, sN) &&
  forall r: reg :: 
    r in s1.regs
}

lemma va_lemma_block(b0: va_codes, s0: state, sN: state)
    returns (s1: state, c1: va_code, b1: va_codes)
  requires b0.CCons?
  requires eval_code(va_Block(b0), s0, sN)
  ensures b0 == va_CCons(c1, b1)
  ensures eval_code(c1, s0, s1)
  ensures eval_code(va_Block(b1), s1, sN)
{
}

lemma va_lemma_empty(s0: va_state, sN: va_state) returns (sM: va_state)
  requires eval_code(va_Block(va_CNil()), s0, sN)
  ensures s0 == sM == sN
{
}

lemma va_lemma_ifElse(ifb: ocmp, ct: code, cf: code, s0: va_state, sN: va_state)
    returns (cond: bool, sM: va_state)
  requires eval_code(IfElse(ifb, ct, cf), s0, sN)
  ensures cond == eval_ocmp(s0, ifb)
  ensures sM == s0
  ensures if cond then eval_code(ct, sM, sN) else eval_code(cf, sM, sN)
{
}

predicate va_whileInv(b: ocmp, c: code, n: int, s0: va_state, sN: va_state)
{
  n >= 0 &&
  (forall r: reg :: 
    r in s0.regs) &&
  eval_while(b, c, n, s0, sN)
}

lemma va_lemma_while(b: ocmp, c: code, s0: va_state, sN: va_state)
    returns (n: nat, s1: va_state)
  requires eval_code(While(b, c), s0, sN)
  ensures eval_while(b, c, n, s0, sN)
  ensures s1 == s0
{
}

lemma va_lemma_whileTrue(b: ocmp, c: code, n: nat, s0: va_state, sN: va_state)
    returns (s0': va_state, s1: va_state)
  requires n > 0
  requires eval_while(b, c, n, s0, sN)
  ensures s0' == s0
  ensures eval_ocmp(s0, b)
  ensures eval_code(c, s0', s1)
  ensures if s1.ok then eval_while(b, c, n - 1, s1, sN) else s1 == sN
{
}

lemma va_lemma_whileFalse(b: ocmp, c: code, s0: va_state, sN: va_state)
    returns (s1: va_state)
  requires eval_while(b, c, 0, s0, sN)
  ensures s1 == s0 == sN
  ensures !eval_ocmp(s0, b)
{
}

method masm_printReg(r: reg)
{
  match r
  case EAX =>
    print "eax";
  case EBX =>
    print "ebx";
}

method gcc_printReg(r: reg)
{
  print "%";
  match r
  case EAX =>
    print "eax";
  case EBX =>
    print "ebx";
}

method masm_printOpr(o: opr)
{
  match o
  case OConst(n) =>
    print n;
  case OReg(r) =>
    masm_printReg(r);
}

method gcc_printOpr(o: opr)
{
  match o
  case OConst(n) =>
    print "$";
    print n;
  case OReg(r) =>
    gcc_printReg(r);
}

method masm_printIns(ins: ins)
{
  match ins
  case Mov(dst, src) =>
    print "  mov ";
    masm_printReg(dst);
    print ", ";
    masm_printOpr(src);
    print "\n";
  case Add(dst, src) =>
    print "  add ";
    masm_printReg(dst);
    print ", ";
    masm_printOpr(src);
    print "\n";
}

method gcc_printIns(ins: ins)
{
  match ins
  case Mov(dst, src) =>
    print "  mov ";
    gcc_printOpr(src);
    print ", ";
    gcc_printReg(dst);
    print "\n";
  case Add(dst, src) =>
    print "  add ";
    gcc_printOpr(src);
    print ", ";
    gcc_printReg(dst);
    print "\n";
}

method masm_printBlock(b: codes, n: int) returns (n': int)
{
  n' := n;
  var i := b;
  while i.CCons?
    decreases i
  {
    n' := masm_printCode(i.hd, n');
    i := i.tl;
  }
}

method gcc_printBlock(b: codes, n: int) returns (n': int)
{
  n' := n;
  var i := b;
  while i.CCons?
    decreases i
  {
    n' := gcc_printCode(i.hd, n');
    i := i.tl;
  }
}

method masm_printCode(c: code, n: int) returns (n': int)
{
  match c
  case Ins(ins) =>
    masm_printIns(ins);
    n' := n;
  case Block(block) =>
    n' := masm_printBlock(block, n);
  case IfElse(ifb, ift, iff) =>
    {
      var n1 := n;
      var n2 := n + 1;
      print "  cmp ";
      masm_printOpr(ifb.o1);
      print ", ";
      masm_printOpr(ifb.o2);
      print "\n";
      print "  ja ";
      print "L";
      print n1;
      print "\n";
      n' := masm_printCode(ift, n + 2);
      print "  jmp L";
      print n2;
      print "\n";
      print "L";
      print n1;
      print ":\n";
      n' := masm_printCode(iff, n');
      print "L";
      print n2;
      print ":\n";
    }
  case While(b, loop) =>
    {
      var n1 := n;
      var n2 := n + 1;
      print "  jmp L";
      print n2;
      print "\n";
      print "ALIGN 16\nL";
      print n1;
      print ":\n";
      n' := masm_printCode(loop, n + 2);
      print "ALIGN 16\nL";
      print n2;
      print ":\n";
      print "  cmp ";
      masm_printOpr(b.o1);
      print ", ";
      masm_printOpr(b.o2);
      print "\n";
      print "  jbe ";
      print "L";
      print n1;
      print "\n";
    }
}

method gcc_printCode(c: code, n: int) returns (n': int)
{
  match c
  case Ins(ins) =>
    gcc_printIns(ins);
    n' := n;
  case Block(block) =>
    n' := gcc_printBlock(block, n);
  case IfElse(ifb, ift, iff) =>
    {
      var n1 := n;
      var n2 := n + 1;
      print "  cmp ";
      gcc_printOpr(ifb.o2);
      print ", ";
      gcc_printOpr(ifb.o1);
      print "\n";
      print "  ja ";
      print "L";
      print n1;
      print "\n";
      n' := gcc_printCode(ift, n + 2);
      print "  jmp L";
      print n2;
      print "\n";
      print "L";
      print n1;
      print ":\n";
      n' := gcc_printCode(iff, n');
      print "L";
      print n2;
      print ":\n";
    }
  case While(b, loop) =>
    {
      var n1 := n;
      var n2 := n + 1;
      print "  jmp L";
      print n2;
      print "\n";
      print ".align 16\nL";
      print n1;
      print ":\n";
      n' := gcc_printCode(loop, n + 2);
      print ".align 16\nL";
      print n2;
      print ":\n";
      print "  cmp ";
      gcc_printOpr(b.o2);
      print ", ";
      gcc_printOpr(b.o1);
      print "\n";
      print "  jbe ";
      print "L";
      print n1;
      print "\n";
    }
}

method masm_printHeader()
{
  print ".686p\n";
  print ".model flat\n";
  print ".code\n";
}

method masm_printProc(proc_name: seq<char>, code: code, n: int, ret_count: uint32)
{
  print "ALIGN 16\n";
  print proc_name;
  print " proc\n";
  var _ := masm_printCode(code, n);
  print "  ret ";
  print ret_count;
  print "\n";
  print proc_name;
  print " endp\n";
}

method masm_printFooter()
{
  print "end\n";
}

method gcc_printHeader()
{
  print ".text\n";
}

method gcc_printProc(proc_name: seq<char>, code: code, n: int, ret_count: uint32)
{
  print ".global ";
  print proc_name;
  print "\n";
  print proc_name;
  print ":\n";
  var _ := gcc_printCode(code, n);
  print "  ret ";
  print "\n\n";
}

method gcc_printFooter()
{
  print "\n";
}

function method procName(proc_name: seq<char>, suffix: seq<char>, asm: AsmTarget, platform: PlatformTarget): seq<char>
{
  match platform
  case Win =>
    "_" + proc_name + match asm case MASM => suffix case GCC => ""
  case Linux =>
    proc_name
  case MacOS =>
    "_" + proc_name
}

method printHeader(asm: AsmTarget)
{
  match asm
  case MASM =>
    masm_printHeader();
  case GCC =>
    gcc_printHeader();
}

method printProc(proc_name: seq<char>, code: code, n: int, ret_count: uint32, suffix: seq<char>, asm: AsmTarget, platform: PlatformTarget)
{
  match asm
  case MASM =>
    masm_printProc(procName(proc_name, suffix, asm, platform), code, n, ret_count);
  case GCC =>
    gcc_printProc(procName(proc_name, suffix, asm, platform), code, n, ret_count);
}

method printFooter(asm: AsmTarget)
{
  match asm
  case MASM =>
    masm_printFooter();
  case GCC =>
    gcc_printFooter();
}

type uint32 = i: int | 0 <= i < 4294967296

datatype reg = EAX | EBX

datatype opr = OReg(r: reg) | OConst(n: uint32)

datatype ocmp = OLe(o1: opr, o2: opr)

datatype mem_opr = OMem(base: reg, offset: int) | OOpr(o: opr)

datatype ins = Mov(dstMov: reg, srcMov: opr) | Add(dstAdd: reg, srcAdd: opr)

datatype code = Ins(ins: ins) | Block(block: codes) | IfElse(ifCond: ocmp, ifTrue: code, ifFalse: code) | While(whileCond: ocmp, whileBody: code)

datatype codes = CNil | CCons(hd: code, tl: codes)

datatype state = State(ok: bool, regs: map<reg, uint32>, mem: map<int, uint32>)

type va_bool = bool

type va_int = int

type va_codes = codes

type va_code = code

type va_state = state

type va_register = reg

type va_operand = opr

type va_mem_operand = mem_opr

type va_cmp = opr

datatype AsmTarget = MASM | GCC

datatype PlatformTarget = Win | Linux | MacOS
