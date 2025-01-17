include "vale.dfy"
include "../../lib/util/operations.dfy"

module x64_vale64
{
import opened x64_def
import opened x64_vale
import opened operations

function{:opaque} BitwiseSub64(x:uint64, y:uint64):uint64
{
    (x - y) % 0x1_0000_0000_0000_0000
}

type cmp_operand = operand
function method va_const_cmp(x:uint64):cmp_operand { OConst(x) }
function method va_coerce_operand_to_cmp(o:opr):opr { o }

type mem_operand = operand
type va_value_mem64 = uint64
type va_operand_mem64 = operand
type va_operand_shift64 = operand

predicate va_is_src_mem64(o:opr, s:va_state)
{
    o.OConst? || (o.OReg? && !o.r.X86Xmm?) || (o.OHeap? && Valid64BitSourceOperand(s, o))
}

function va_eval_mem64(s:va_state, o:opr):uint64
    requires va_is_src_mem64(o, s)
{
    eval_op64(s, o)
}

predicate va_is_src_shift64(o:opr, s:va_state) { o.OConst? || o == OReg(X86Ecx) }

function va_eval_shift64(s:va_state, o:opr):uint64
    requires va_is_src_shift64(o, s)
{
    eval_op64(s, o)
}

function method va_op_mem64_reg64(r:x86reg):opr { OReg(r) }
function method va_const_mem64(x:uint64):opr { OConst(x) }

function method va_opr_code_Mem(base:operand, offset:int):mem_operand
{
    MakeHeapOp(base, offset)
}

function method va_opr_lemma_Mem(s:va_state, base:operand, offset:int):mem_operand
    requires x86_ValidState(s)
    requires base.OReg?
    requires ValidMemAddr(MReg(base.r, offset))
    requires ValidSrcAddr(s.heap, va_get_reg64(base.r, s) + offset, 64)
    ensures  Valid64BitSourceOperand(s, OHeap(MReg(base.r, offset)))
    ensures  eval_op64(s, OHeap(MReg(base.r, offset))) == s.heap[va_get_reg64(base.r, s) + offset].v64
{
    reveal_x86_ValidState();
    va_opr_code_Mem(base, offset)
}

}
