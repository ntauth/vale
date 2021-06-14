// Trusted printer for producing MASM code

include "printMasm.s.dfy"
include "printGcc.s.dfy"

module x64_print_s {

import opened x64_def_s
import opened x64_const_time_i

import Masm = x64_printMasm_s 
import Gcc = x64_printGcc_s

datatype AsmTarget = MASM | GCC
datatype PlatformTarget = Win | Linux | MacOS

function method procName(proc_name:seq<char>, suffix:seq<char>, asm:AsmTarget, platform:PlatformTarget):seq<char>
{
    match platform
        case Win => "_" + proc_name + (match asm case MASM => suffix case GCC => "")
        case Linux => proc_name
        case MacOS => "_" + proc_name
}

method printHeader(asm:AsmTarget)
{
    match asm
        case MASM => Masm.printHeader();
        case GCC  => Gcc.printHeader();
}

method printProc(proc_name:seq<char>, code:code, n:int, ret_count:uint32, asm:AsmTarget)
{
    match asm
        case MASM => Masm.printProc(proc_name, code, n, ret_count);
        case GCC  => Gcc.printProc(proc_name, code, n, ret_count);
}

method printProcPlatform(proc_name:seq<char>, code:code, n:int, ret_count:uint32, asm:AsmTarget, platform:PlatformTarget)
{
    printProc(match platform case Win => proc_name case Linux => proc_name case MacOS => "_" + proc_name,
        code, n, ret_count, asm);
}

method printFooter(asm:AsmTarget)
{
    match asm
        case MASM => Masm.printFooter();
        case GCC  => Gcc.printFooter();
}

// runs constant time analysis
method checkConstantTime(proc_name:seq<char>, code:code, ts:taintState) returns (b:bool)
    decreases * 
{
    var constTime, ts' := checkIfCodeConsumesFixedTime(code, ts);
    b := constTime;

    // print code only if the code is constant time and leakage free according to the checker
    if (constTime == false) {
        print(proc_name + ": Constant time check failed\n");
    } else {
        //printProc(proc_name, code, n, ret_count);
        //var n' := printCode(code, n);
    }
}

// runs both leakage analysis and constant time analysis
method checkLeakage(proc_name:seq<char>, code:code, ts:taintState, tsExpected:taintState) returns (b:bool)
    decreases * 
{
    b := checkIfCodeisLeakageFree(code, ts, tsExpected);

    // print code only if the code is constant time and leakage free according to the checker
    if (b == false) {
        print(proc_name + ": Leakage analysis failed\n");
    } else {
        // printProc(proc_name, code, n, ret_count);
        //var n' := printCode(code, n);
    }
}
// runs constant time analysis
method checkConstantTimeAndPrintProc(proc_name:seq<char>, code:code, n:int, ret_count:uint32, ts:taintState, suffix:seq<char>, asm:AsmTarget, platform:PlatformTarget)
    decreases * 
{
    match asm
        case MASM => Masm.checkConstantTimeAndPrintProc(procName(proc_name, suffix, asm, platform), code, n, ret_count, ts);
        case GCC  => Gcc.checkConstantTimeAndPrintProc(procName(proc_name, suffix, asm, platform), code, n, ret_count, ts);
}

// runs both leakage analysis and constant time analysis
method checkConstantTimeAndLeakageBeforePrintProc(proc_name:seq<char>, code:code, n:int, ret_count:uint32, ts:taintState, tsExpected:taintState, suffix:seq<char>, asm:AsmTarget, platform:PlatformTarget)
    decreases * 
{
    match asm
        case MASM => Masm.checkConstantTimeAndLeakageBeforePrintProc(procName(proc_name, suffix, asm, platform), code, n, ret_count, ts, tsExpected);
        case GCC  => Gcc.checkConstantTimeAndLeakageBeforePrintProc(procName(proc_name, suffix, asm, platform), code, n, ret_count, ts, tsExpected);
}

}