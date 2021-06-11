	.file	"hash.c"
	.text
	.globl	djb2
	.type	djb2, @function
djb2:
.LFB0:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	$5381, -8(%rbp)
	movq	$0, -16(%rbp)
	jmp	.L2
.L3:
	movq	-8(%rbp), %rax
	salq	$5, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	leaq	(%rdx,%rax), %rcx
	movq	-24(%rbp), %rdx
	movq	-16(%rbp), %rax
	addq	%rdx, %rax
	movzbl	(%rax), %eax
	movzbl	%al, %eax
	addq	%rcx, %rax
	addq	%rax, -8(%rbp)
	addq	$1, -16(%rbp)
.L2:
	movq	-16(%rbp), %rax
	cmpq	-32(%rbp), %rax
	jb	.L3
	movq	-8(%rbp), %rax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	djb2, .-djb2
	.section	.rodata
.LC0:
	.string	"%lx\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	%edi, -36(%rbp)
	movq	%rsi, -48(%rbp)
	movabsq	$7016996765293437281, %rax
	movq	%rax, -18(%rbp)
	movw	$97, -10(%rbp)
	leaq	-18(%rbp), %rax
	movl	$10, %esi
	movq	%rax, %rdi
	call	djb2
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC0(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	 1f - 0f
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:
