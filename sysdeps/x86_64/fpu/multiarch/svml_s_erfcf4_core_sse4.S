/* Function erfcf vectorized with SSE4.
   Copyright (C) 2021-2025 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   https://www.gnu.org/licenses/.  */

/*
 * ALGORITHM DESCRIPTION:
 *
 *   Approximation formula:
 *   erfc(x) ~ erfc(x0) - 2/sqrt(pi)*exp(-x0^2)*D * [ 1 + (x0*D)*p1(x0*D) + D^2 * p3(x0*D) ]
 *     D = x - x0
 *     erfc(x0) and 2/sqrt(pi)*exp(-x0^2)/(2*x0) are tabulated
 *
 *
 */

/* Offsets for data table __svml_serfc_data_internal
 */
#define _erfc_tbl			0
#define _AbsMask			5168
#define _MaxThreshold			5184
#define _SgnMask			5200
#define _SRound				5216
#define _TwoM48				5232
#define _poly1_0			5248
#define _poly1_1			5264
#define _poly3_0			5280
#define _poly3_1			5296
#define _poly1_2			5312
#define _poly1_3			5328
#define _UF_Threshold			5344
#define _TwoP48				5360

/* Lookup bias for data table __svml_serfc_data_internal.  */
#define Table_Lookup_Bias		-0x40000000

#include <sysdep.h>

	.section .text.sse4, "ax", @progbits
ENTRY(_ZGVbN4v_erfcf_sse4)
	subq	$72, %rsp
	cfi_def_cfa_offset(80)
	movaps	%xmm0, %xmm7
	movups	_AbsMask+__svml_serfc_data_internal(%rip), %xmm6

	/* vector gather: erfc_h(x0), (erfc_l(x0), 2/sqrt(pi)*exp(-x0^2)) */
	lea	Table_Lookup_Bias+__svml_serfc_data_internal(%rip), %rdi
	andps	%xmm7, %xmm6

	/*
	 * erfc(10.125) underflows to 0
	 * can compute all results in the main path
	 */
	minps	_MaxThreshold+__svml_serfc_data_internal(%rip), %xmm6
	movups	_SRound+__svml_serfc_data_internal(%rip), %xmm9
	movaps	%xmm9, %xmm13
	movups	_TwoM48+__svml_serfc_data_internal(%rip), %xmm0
	addps	%xmm6, %xmm13
	maxps	%xmm0, %xmm6
	movaps	%xmm13, %xmm4
	pslld	$3, %xmm13

	/* Start polynomial evaluation */
	movups	_poly1_0+__svml_serfc_data_internal(%rip), %xmm1
	subps	%xmm9, %xmm4
	movd	%xmm13, %eax
	movups	_poly3_0+__svml_serfc_data_internal(%rip), %xmm2
	subps	%xmm4, %xmm6
	mulps	%xmm6, %xmm4

	/* Diff^2 */
	movaps	%xmm6, %xmm9
	mulps	%xmm6, %xmm9
	mulps	%xmm4, %xmm1
	mulps	%xmm4, %xmm2
	addps	_poly1_1+__svml_serfc_data_internal(%rip), %xmm1
	addps	_poly3_1+__svml_serfc_data_internal(%rip), %xmm2
	mulps	%xmm4, %xmm1

	/* P3*D2 */
	mulps	%xmm9, %xmm2
	addps	_poly1_2+__svml_serfc_data_internal(%rip), %xmm1
	mulps	%xmm4, %xmm1
	pshufd	$1, %xmm13, %xmm11
	addps	_poly1_3+__svml_serfc_data_internal(%rip), %xmm1
	movd	%xmm11, %edx
	pshufd	$2, %xmm13, %xmm12
	pshufd	$3, %xmm13, %xmm14
	movd	%xmm12, %ecx
	movd	%xmm14, %esi
	movups	_SgnMask+__svml_serfc_data_internal(%rip), %xmm10
	andps	%xmm7, %xmm10

	/* P1 = P1*T + P3*D2 */
	mulps	%xmm1, %xmm4
	movaps	%xmm10, %xmm5
	movslq	%eax, %rax

	/* 2^(-64) with sign of input */
	orps	%xmm10, %xmm0
	movslq	%edx, %rdx

	/* Special arguments (for flags only) */
	movaps	%xmm7, %xmm1
	movslq	%ecx, %rcx
	addps	%xmm4, %xmm2
	cmpltps	_UF_Threshold+__svml_serfc_data_internal(%rip), %xmm1
	movslq	%esi, %rsi
	movups	_TwoP48+__svml_serfc_data_internal(%rip), %xmm8
	orps	%xmm8, %xmm5
	movq	(%rdi, %rax), %xmm3
	subps	%xmm8, %xmm5
	movq	(%rdi, %rdx), %xmm15
	movq	(%rdi, %rcx), %xmm8
	movq	(%rdi, %rsi), %xmm13
	unpcklps %xmm15, %xmm3
	unpcklps %xmm13, %xmm8
	movaps	%xmm3, %xmm10
	shufps	$238, %xmm8, %xmm3

	/* EXP_X0H * (1+P1) */
	mulps	%xmm3, %xmm2

	/* combine and get argument value range mask */
	movmskps %xmm1, %edx
	movlhps	%xmm8, %xmm10
	addps	%xmm2, %xmm3

	/* erfc_high(x0) - Diff * (2/sqrt(pi)*exp(-x0^2))*(1+P1) */
	mulps	%xmm3, %xmm6
	notl	%edx
	subps	%xmm6, %xmm10
	addps	%xmm10, %xmm5
	mulps	%xmm5, %xmm0
	andl	$15, %edx

	/* Go to special inputs processing branch */
	jne	L(SPECIAL_VALUES_BRANCH)
	# LOE rbx rbp r12 r13 r14 r15 edx xmm0 xmm7

	/* Restore registers
	 * and exit the function
	 */

L(EXIT):
	addq	$72, %rsp
	cfi_def_cfa_offset(8)
	ret
	cfi_def_cfa_offset(80)

	/* Branch to process
	 * special inputs
	 */

L(SPECIAL_VALUES_BRANCH):
	movups	%xmm7, 32(%rsp)
	movups	%xmm0, 48(%rsp)
	# LOE rbx rbp r12 r13 r14 r15 edx xmm0

	xorl	%eax, %eax
	movq	%r12, 16(%rsp)
	cfi_offset(12, -64)
	movl	%eax, %r12d
	movq	%r13, 8(%rsp)
	cfi_offset(13, -72)
	movl	%edx, %r13d
	movq	%r14, (%rsp)
	cfi_offset(14, -80)
	# LOE rbx rbp r15 r12d r13d

	/* Range mask
	 * bits check
	 */

L(RANGEMASK_CHECK):
	btl	%r12d, %r13d

	/* Call scalar math function */
	jc	L(SCALAR_MATH_CALL)
	# LOE rbx rbp r15 r12d r13d

	/* Special inputs
	 * processing loop
	 */

L(SPECIAL_VALUES_LOOP):
	incl	%r12d
	cmpl	$4, %r12d

	/* Check bits in range mask */
	jl	L(RANGEMASK_CHECK)
	# LOE rbx rbp r15 r12d r13d

	movq	16(%rsp), %r12
	cfi_restore(12)
	movq	8(%rsp), %r13
	cfi_restore(13)
	movq	(%rsp), %r14
	cfi_restore(14)
	movups	48(%rsp), %xmm0

	/* Go to exit */
	jmp	L(EXIT)
	cfi_offset(12, -64)
	cfi_offset(13, -72)
	cfi_offset(14, -80)
	# LOE rbx rbp r12 r13 r14 r15 xmm0

	/* Scalar math function call
	 * to process special input
	 */

L(SCALAR_MATH_CALL):
	movl	%r12d, %r14d
	movss	32(%rsp, %r14, 4), %xmm0
	call	erfcf@PLT
	# LOE rbx rbp r14 r15 r12d r13d xmm0

	movss	%xmm0, 48(%rsp, %r14, 4)

	/* Process special inputs in loop */
	jmp	L(SPECIAL_VALUES_LOOP)
	# LOE rbx rbp r15 r12d r13d
END(_ZGVbN4v_erfcf_sse4)

	.section .rodata, "a"
	.align	16

#ifdef __svml_serfc_data_internal_typedef
typedef unsigned int VUINT32;
typedef struct {
	__declspec(align(16)) VUINT32 _erfc_tbl[645*2][1];
	__declspec(align(16)) VUINT32 _AbsMask[4][1];
	__declspec(align(16)) VUINT32 _MaxThreshold[4][1];
	__declspec(align(16)) VUINT32 _SgnMask[4][1];
	__declspec(align(16)) VUINT32 _SRound[4][1];
	__declspec(align(16)) VUINT32 _TwoM48[4][1];
	__declspec(align(16)) VUINT32 _poly1_0[4][1];
	__declspec(align(16)) VUINT32 _poly1_1[4][1];
	__declspec(align(16)) VUINT32 _poly3_0[4][1];
	__declspec(align(16)) VUINT32 _poly3_1[4][1];
	__declspec(align(16)) VUINT32 _poly1_2[4][1];
	__declspec(align(16)) VUINT32 _poly1_3[4][1];
	__declspec(align(16)) VUINT32 _UF_Threshold[4][1];
	__declspec(align(16)) VUINT32 _TwoP48[4][1];
} __svml_serfc_data_internal;
#endif
__svml_serfc_data_internal:
	/* _erfc_tbl */
	.long	0x57800000, 0x57906ebb
	.long	0x577b7ca2, 0x579065b4
	.long	0x5776f9d5, 0x57904aa3
	.long	0x57727828, 0x57901d93
	.long	0x576df82b, 0x578fde94
	.long	0x57697a6e, 0x578f8dbd
	.long	0x5764ff7f, 0x578f2b2e
	.long	0x576087ea, 0x578eb70a
	.long	0x575c143d, 0x578e317d
	.long	0x5757a500, 0x578d9ab9
	.long	0x57533abf, 0x578cf2f5
	.long	0x574ed5fe, 0x578c3a6f
	.long	0x574a7744, 0x578b716c
	.long	0x57461f12, 0x578a9834
	.long	0x5741cdeb, 0x5789af18
	.long	0x573d844a, 0x5788b66c
	.long	0x573942ac, 0x5787ae8b
	.long	0x57350989, 0x578697d3
	.long	0x5730d956, 0x578572a8
	.long	0x572cb284, 0x57843f72
	.long	0x57289583, 0x5782fe9f
	.long	0x572482bd, 0x5781b0a0
	.long	0x57207a9b, 0x578055e8
	.long	0x571c7d80, 0x577ddddf
	.long	0x57188bcb, 0x577af867
	.long	0x5714a5da, 0x5777fc62
	.long	0x5710cc05, 0x5774ead4
	.long	0x570cfe9f, 0x5771c4c4
	.long	0x57093df9, 0x576e8b3e
	.long	0x57058a5e, 0x576b3f51
	.long	0x5701e415, 0x5767e20f
	.long	0x56fc96c6, 0x5764748e
	.long	0x56f5810a, 0x5760f7e5
	.long	0x56ee876d, 0x575d6d2d
	.long	0x56e7aa5a, 0x5759d57e
	.long	0x56e0ea35, 0x575631f4
	.long	0x56da4757, 0x575283a7
	.long	0x56d3c214, 0x574ecbb1
	.long	0x56cd5ab3, 0x574b0b28
	.long	0x56c71175, 0x57474323
	.long	0x56c0e692, 0x574374b5
	.long	0x56bada38, 0x573fa0ee
	.long	0x56b4ec8f, 0x573bc8dc
	.long	0x56af1db3, 0x5737ed89
	.long	0x56a96dbc, 0x57340ff9
	.long	0x56a3dcb7, 0x5730312e
	.long	0x569e6aaa, 0x572c5223
	.long	0x56991793, 0x572873cf
	.long	0x5693e369, 0x57249721
	.long	0x568ece1a, 0x5720bd06
	.long	0x5689d78f, 0x571ce661
	.long	0x5684ffa8, 0x5719140f
	.long	0x56804640, 0x571546e7
	.long	0x56775654, 0x57117fb9
	.long	0x566e5c65, 0x570dbf4c
	.long	0x56659e43, 0x570a0662
	.long	0x565d1b6d, 0x570655b1
	.long	0x5654d35d, 0x5702adeb
	.long	0x564cc57d, 0x56fe1f73
	.long	0x5644f12f, 0x56f6f777
	.long	0x563d55cc, 0x56efe513
	.long	0x5635f2a1, 0x56e8e968
	.long	0x562ec6f6, 0x56e20584
	.long	0x5627d207, 0x56db3a64
	.long	0x5621130b, 0x56d488f8
	.long	0x561a8931, 0x56cdf21c
	.long	0x561433a0, 0x56c7769b
	.long	0x560e117c, 0x56c11733
	.long	0x560821e1, 0x56bad48d
	.long	0x560263e5, 0x56b4af46
	.long	0x55f9ad39, 0x56aea7ea
	.long	0x55eef22b, 0x56a8bef3
	.long	0x55e494b6, 0x56a2f4ce
	.long	0x55da92eb, 0x569d49d9
	.long	0x55d0ead3, 0x5697be62
	.long	0x55c79a75, 0x569252aa
	.long	0x55be9fd3, 0x568d06e3
	.long	0x55b5f8ee, 0x5687db31
	.long	0x55ada3c2, 0x5682cfad
	.long	0x55a59e4c, 0x567bc8c2
	.long	0x559de68a, 0x56723298
	.long	0x55967a77, 0x5668dcc1
	.long	0x558f5812, 0x565fc70e
	.long	0x55887d5c, 0x5656f136
	.long	0x5581e856, 0x564e5adf
	.long	0x55772e0c, 0x56460399
	.long	0x556b0eeb, 0x563deae4
	.long	0x555f6f64, 0x5636102b
	.long	0x55544b9e, 0x562e72cb
	.long	0x55499fc8, 0x5627120f
	.long	0x553f681d, 0x561fed36
	.long	0x5535a0e6, 0x5619036e
	.long	0x552c4679, 0x561253dc
	.long	0x55235539, 0x560bdd96
	.long	0x551ac999, 0x56059fa9
	.long	0x5512a01c, 0x55ff3230
	.long	0x550ad554, 0x55f391b9
	.long	0x550365e5, 0x55e85bd0
	.long	0x54f89d02, 0x55dd8e4c
	.long	0x54eb17df, 0x55d326f3
	.long	0x54de360f, 0x55c92385
	.long	0x54d1f166, 0x55bf81b6
	.long	0x54c643dc, 0x55b63f32
	.long	0x54bb2790, 0x55ad59a1
	.long	0x54b096c5, 0x55a4cea4
	.long	0x54a68be5, 0x559c9bd9
	.long	0x549d0180, 0x5594bedd
	.long	0x5493f24c, 0x558d354b
	.long	0x548b5926, 0x5585fcbf
	.long	0x54833111, 0x557e25af
	.long	0x5476ea69, 0x5570ea68
	.long	0x546841c1, 0x556442f0
	.long	0x545a5f10, 0x55582a98
	.long	0x544d398b, 0x554c9cbd
	.long	0x5440c8ae, 0x554194c7
	.long	0x54350440, 0x55370e2c
	.long	0x5429e44f, 0x552d0474
	.long	0x541f612f, 0x55237336
	.long	0x5415737d, 0x551a561b
	.long	0x540c1417, 0x5511a8e1
	.long	0x54033c22, 0x5509675a
	.long	0x53f5ca07, 0x55018d6b
	.long	0x53e610c3, 0x54f42e22
	.long	0x53d74046, 0x54e600c0
	.long	0x53c94cd8, 0x54d88b05
	.long	0x53bc2b3a, 0x54cbc574
	.long	0x53afd0a5, 0x54bfa8c4
	.long	0x53a432c3, 0x54b42ddb
	.long	0x539947af, 0x54a94dcf
	.long	0x538f05f3, 0x549f01ec
	.long	0x5385647e, 0x549543ae
	.long	0x5378b557, 0x548c0cc2
	.long	0x5367c06a, 0x5483570a
	.long	0x5357da71, 0x54763931
	.long	0x5348f45f, 0x5466af65
	.long	0x533affda, 0x5458059c
	.long	0x532def39, 0x544a3127
	.long	0x5321b57a, 0x543d27b5
	.long	0x5316463d, 0x5430df57
	.long	0x530b95bd, 0x54254e7b
	.long	0x530198cc, 0x541a6bee
	.long	0x52f08999, 0x54102ed6
	.long	0x52df1f58, 0x54068eb5
	.long	0x52cedfb9, 0x53fb06c5
	.long	0x52bfb8a0, 0x53ea0a1d
	.long	0x52b198e5, 0x53da1876
	.long	0x52a4704e, 0x53cb237a
	.long	0x52982f7c, 0x53bd1d6f
	.long	0x528cc7eb, 0x53aff93b
	.long	0x52822be3, 0x53a3aa56
	.long	0x52709cde, 0x539824ce
	.long	0x525e46a9, 0x538d5d3c
	.long	0x524d3e18, 0x538348c6
	.long	0x523d6d6f, 0x5373ba24
	.long	0x522ec035, 0x53622096
	.long	0x52212321, 0x5351b22a
	.long	0x52148413, 0x53425d18
	.long	0x5208d1fc, 0x53341080
	.long	0x51fbf9ac, 0x5326bc5e
	.long	0x51e7eb29, 0x531a5183
	.long	0x51d55c2d, 0x530ec18c
	.long	0x51c43238, 0x5303feda
	.long	0x51b45472, 0x52f3f919
	.long	0x51a5ab93, 0x52e15ce8
	.long	0x519821ce, 0x52d0121b
	.long	0x518ba2bc, 0x52c002f8
	.long	0x51801b49, 0x52b11afe
	.long	0x516af33c, 0x52a346d7
	.long	0x51575a21, 0x5296744c
	.long	0x51454c24, 0x528a9237
	.long	0x5134ac3b, 0x527f20e7
	.long	0x51255f51, 0x526abfa9
	.long	0x51174c27, 0x5257e42f
	.long	0x510a5b3b, 0x524673af
	.long	0x50fced50, 0x52365507
	.long	0x50e7141d, 0x522770a1
	.long	0x50d304fc, 0x5219b066
	.long	0x50c09cb5, 0x520cffa3
	.long	0x50afba92, 0x52014af8
	.long	0x50a04037, 0x51ed0088
	.long	0x50921177, 0x51d91d2d
	.long	0x50851430, 0x51c6cc35
	.long	0x50726058, 0x51b5f011
	.long	0x505c9dfa, 0x51a66d2a
	.long	0x5048b7be, 0x519829c8
	.long	0x50368738, 0x518b0df2
	.long	0x5025e8e0, 0x517e06ab
	.long	0x5016bbdf, 0x5167ea53
	.long	0x5008e1df, 0x5153a034
	.long	0x4ff87dc3, 0x5141045e
	.long	0x4fe1721f, 0x512ff56d
	.long	0x4fcc712a, 0x51205461
	.long	0x4fb94efb, 0x51120475
	.long	0x4fa7e31e, 0x5104eafc
	.long	0x4f980855, 0x50f1de7a
	.long	0x4f899c5c, 0x50dbf4a3
	.long	0x4f78ff60, 0x50c7ee0e
	.long	0x4f612ab5, 0x50b5a381
	.long	0x4f4b8583, 0x50a4f0bc
	.long	0x4f37deef, 0x5095b43b
	.long	0x4f260a27, 0x5087cf0e
	.long	0x4f15de0f, 0x5076494d
	.long	0x4f0734f9, 0x505f355e
	.long	0x4ef3d8c4, 0x504a31bf
	.long	0x4edbc95e, 0x503711b4
	.long	0x4ec601e9, 0x5025ac0e
	.long	0x4eb24d81, 0x5015dae6
	.long	0x4ea07bca, 0x50077b62
	.long	0x4e906098, 0x4ff4daf4
	.long	0x4e81d395, 0x4fdd2782
	.long	0x4e695fe3, 0x4fc7a666
	.long	0x4e51a834, 0x4fb42611
	.long	0x4e3c42e7, 0x4fa2790f
	.long	0x4e28f835, 0x4f9275b9
	.long	0x4e179555, 0x4f83f5e9
	.long	0x4e07ec0b, 0x4f6dad68
	.long	0x4df3a498, 0x4f55f04f
	.long	0x4dda43ba, 0x4f407a1d
	.long	0x4dc37003, 0x4f2d1570
	.long	0x4daeea58, 0x4f1b9188
	.long	0x4d9c7974, 0x4f0bc1e7
	.long	0x4d8be963, 0x4efafbec
	.long	0x4d7a160c, 0x4ee14167
	.long	0x4d5f6759, 0x4eca10ce
	.long	0x4d477955, 0x4eb52cb9
	.long	0x4d3205fb, 0x4ea25d43
	.long	0x4d1ecdf3, 0x4e916f95
	.long	0x4d0d97f2, 0x4e823575
	.long	0x4cfc6061, 0x4e6909cc
	.long	0x4ce0cfd4, 0x4e506f88
	.long	0x4cc829c6, 0x4e3a56e4
	.long	0x4cb221ff, 0x4e268119
	.long	0x4c9e73c2, 0x4e14b538
	.long	0x4c8ce119, 0x4e04bfb1
	.long	0x4c7a6462, 0x4dece39b
	.long	0x4c5e6987, 0x4dd34296
	.long	0x4c457726, 0x4dbc4fdc
	.long	0x4c2f3bdb, 0x4da7c64b
	.long	0x4c1b6e79, 0x4d956771
	.long	0x4c09cd3e, 0x4d84fae8
	.long	0x4bf43a38, 0x4d6c9b8f
	.long	0x4bd85225, 0x4d52644f
	.long	0x4bbf8325, 0x4d3afd47
	.long	0x4ba977f0, 0x4d261be0
	.long	0x4b95e415, 0x4d137cf0
	.long	0x4b848320, 0x4d02e402
	.long	0x4b6a2f8b, 0x4ce8356b
	.long	0x4b4ed659, 0x4ccde050
	.long	0x4b369893, 0x4cb670d5
	.long	0x4b211e8a, 0x4ca19816
	.long	0x4b0e19e7, 0x4c8f0f43
	.long	0x4afa896f, 0x4c7d2da8
	.long	0x4adcc11e, 0x4c5febab
	.long	0x4ac26b7f, 0x4c45f27c
	.long	0x4aab2549, 0x4c2ee6b3
	.long	0x4a969605, 0x4c1a767c
	.long	0x4a846ee9, 0x4c0858a4
	.long	0x4a68d3a8, 0x4bf09770
	.long	0x4a4c90c6, 0x4bd42a75
	.long	0x4a33a635, 0x4bbb01dd
	.long	0x4a1db15b, 0x4ba4c066
	.long	0x4a0a5aa0, 0x4b9112d9
	.long	0x49f2a881, 0x4b7f5e08
	.long	0x49d4b277, 0x4b60a591
	.long	0x49ba58bd, 0x4b45867e
	.long	0x49a32ed5, 0x4b2d97f3
	.long	0x498ed4a2, 0x4b187c9e
	.long	0x4979ea08, 0x4b05e186
	.long	0x495a8951, 0x4aeaf9d4
	.long	0x493f01d9, 0x4ace1a8c
	.long	0x4926ddcc, 0x4ab4b0dc
	.long	0x4911b50d, 0x4a9e558a
	.long	0x48fe574a, 0x4a8aad05
	.long	0x48dde0d0, 0x4a72cc48
	.long	0x48c1776e, 0x4a547203
	.long	0x48a89cd3, 0x4a39cbe3
	.long	0x4892e1aa, 0x4a226937
	.long	0x487fc7c2, 0x4a0de652
	.long	0x485e9a3a, 0x49f7d629
	.long	0x4841a2c3, 0x49d85345
	.long	0x48285bae, 0x49bcba74
	.long	0x48124f79, 0x49a49254
	.long	0x47fe2dc4, 0x498f6fd2
	.long	0x47dcae77, 0x4979e90c
	.long	0x47bf81dd, 0x49599a7d
	.long	0x47a61c4e, 0x493d616c
	.long	0x47900357, 0x4924bcd6
	.long	0x47799750, 0x490f3b3e
	.long	0x47582e7f, 0x48f8f1a9
	.long	0x473b27a3, 0x48d83bc6
	.long	0x4721f2b6, 0x48bbbab7
	.long	0x470c11c0, 0x48a2e733
	.long	0x46f22d4c, 0x488d4a80
	.long	0x46d14266, 0x4874f900
	.long	0x46b4bacb, 0x485443df
	.long	0x469c03d6, 0x4837d5b2
	.long	0x46869d9b, 0x481f2272
	.long	0x46683120, 0x4809af94
	.long	0x46482706, 0x47ee23cf
	.long	0x462c7395, 0x47cdd76a
	.long	0x46148366, 0x47b1d636
	.long	0x45ffac6d, 0x4799912d
	.long	0x45dbf8fa, 0x47848b78
	.long	0x45bd2a88, 0x4764b060
	.long	0x45a298a1, 0x474530ba
	.long	0x458bb0fc, 0x4729f27c
	.long	0x456fe94b, 0x47126579
	.long	0x454deaf8, 0x46fc1860
	.long	0x4530a808, 0x46d8f2d6
	.long	0x45177b00, 0x46ba9c63
	.long	0x4501d48c, 0x46a06fec
	.long	0x44de7135, 0x4689de04
	.long	0x44be77a1, 0x466cd440
	.long	0x44a302b0, 0x464b505a
	.long	0x448b71e5, 0x462e74d6
	.long	0x446e7534, 0x46159f2a
	.long	0x444bca2d, 0x46004280
	.long	0x442e1414, 0x45dbc9bf
	.long	0x4414a0a8, 0x45bc396d
	.long	0x43fdac7d, 0x45a11d60
	.long	0x43d860d4, 0x4589d7a8
	.long	0x43b87a3a, 0x456bbf86
	.long	0x439d3454, 0x45497f9a
	.long	0x4385e630, 0x452c23f7
	.long	0x4363fd06, 0x4512fcf7
	.long	0x434200db, 0x44fae63c
	.long	0x4325014d, 0x44d607b0
	.long	0x430c4623, 0x44b67d4e
	.long	0x42ee627d, 0x449b855c
	.long	0x42ca7603, 0x44847920
	.long	0x42abde4b, 0x44619261
	.long	0x4291d40d, 0x443ff482
	.long	0x4277593c, 0x442344bf
	.long	0x4251abca, 0x440acd1c
	.long	0x4231a5c0, 0x43ebe2ca
	.long	0x42167152, 0x43c85727
	.long	0x41feaf84, 0x43aa1178
	.long	0x41d779e7, 0x43904cc0
	.long	0x41b63731, 0x4374c081
	.long	0x419a03db, 0x434f7703
	.long	0x41821dd0, 0x432fc5c4
	.long	0x415bbf2e, 0x4314d94a
	.long	0x41397862, 0x42fbf99c
	.long	0x411c770c, 0x42d52bb9
	.long	0x4103eeb4, 0x42b4411f
	.long	0x40de62c7, 0x429858a7
	.long	0x40bb5652, 0x4280b23e
	.long	0x409dbc89, 0x4259543f
	.long	0x4084bfc1, 0x42376979
	.long	0x405f551f, 0x421ab66b
	.long	0x403bc5f1, 0x420270af
	.long	0x401dccc2, 0x41dbd820
	.long	0x40048c16, 0x41b92c31
	.long	0x3fde907e, 0x419be496
	.long	0x3fbac490, 0x41832dcb
	.long	0x3f9ca73d, 0x415ca86a
	.long	0x3f8354cb, 0x41397eca
	.long	0x3f5c1947, 0x411bdc1e
	.long	0x3f3857fa, 0x4102e528
	.long	0x3f1a529e, 0x40dbc03f
	.long	0x3f0120ef, 0x40b85f58
	.long	0x3ed7fdc8, 0x409a9d36
	.long	0x3eb48e3e, 0x40819878
	.long	0x3e96dc65, 0x4059250b
	.long	0x3e7bfa7c, 0x4035d48d
	.long	0x3e5255b2, 0x40182f4c
	.long	0x3e2f7d27, 0x3ffe9ef1
	.long	0x3e12586c, 0x3fd4e64a
	.long	0x3df3f750, 0x3fb1ed7c
	.long	0x3dcb4137, 0x3f94a0bb
	.long	0x3da94169, 0x3f782f41
	.long	0x3d8ce028, 0x3f4f1cee
	.long	0x3d6a654e, 0x3f2cc100
	.long	0x3d42e7d6, 0x3f100645
	.long	0x3d21fd99, 0x3ef00749
	.long	0x3d0691c1, 0x3ec7ea70
	.long	0x3cdf78d9, 0x3ea66ce0
	.long	0x3cb976f2, 0x3e8a7a45
	.long	0x3c99d8e5, 0x3e665575
	.long	0x3c7f1de8, 0x3e3f778a
	.long	0x3c536be9, 0x3e1f14b2
	.long	0x3c2f2031, 0x3e041bb4
	.long	0x3c10fdbd, 0x3ddb4f88
	.long	0x3beff7df, 0x3db5f2ba
	.long	0x3bc67c0b, 0x3d96e08d
	.long	0x3ba417d4, 0x3d7a1a1e
	.long	0x3b879862, 0x3d4f30a7
	.long	0x3b5ffc37, 0x3d2b8e9a
	.long	0x3b38e85b, 0x3d0dfba1
	.long	0x3b1892fb, 0x3ceae636
	.long	0x3afbaaf5, 0x3cc2374f
	.long	0x3acf75d5, 0x3ca08024
	.long	0x3aaaef8c, 0x3c8492c0
	.long	0x3a8cc60c, 0x3c5ae75b
	.long	0x3a67c170, 0x3c34a340
	.long	0x3a3ead7b, 0x3c14fcf4
	.long	0x3a1cce14, 0x3bf5a5cf
	.long	0x3a00e32d, 0x3bca68ef
	.long	0x39d3c741, 0x3ba6b383
	.long	0x39ade7c9, 0x3b8939a3
	.long	0x398ebc8e, 0x3b61cfd0
	.long	0x396a31ee, 0x3b39b3ce
	.long	0x394008fe, 0x3b18a48b
	.long	0x391d638e, 0x3afad08d
	.long	0x3900ee61, 0x3acdf654
	.long	0x38d322ce, 0x3aa90c4d
	.long	0x38accb15, 0x3a8aaea4
	.long	0x388d5872, 0x3a636e45
	.long	0x3867216f, 0x3a3a6544
	.long	0x383ce218, 0x3a18b095
	.long	0x381a4894, 0x39fa092d
	.long	0x37fbec07, 0x39cc9f41
	.long	0x37cd9386, 0x39a76003
	.long	0x37a7acfd, 0x3988d758
	.long	0x3788b256, 0x395fa559
	.long	0x375ec64b, 0x3936ab0f
	.long	0x373570b9, 0x39152037
	.long	0x3713b43a, 0x38f35dd3
	.long	0x36f05d69, 0x38c67c0a
	.long	0x36c37bc4, 0x38a1ccfc
	.long	0x369ee7d7, 0x3883d518
	.long	0x36811c14, 0x3856b981
	.long	0x3651b337, 0x382ec87a
	.long	0x362a371c, 0x380e33a7
	.long	0x360a1932, 0x37e74660
	.long	0x35dff98b, 0x37bbfab1
	.long	0x35b589f6, 0x3798b6d4
	.long	0x3593127a, 0x37780230
	.long	0x356e2ef2, 0x37494905
	.long	0x3540c69d, 0x372348d9
	.long	0x351bf310, 0x370464b5
	.long	0x34fc31bf, 0x36d69685
	.long	0x34cbd1ee, 0x36add231
	.long	0x34a4a520, 0x368cbaf0
	.long	0x3484ef72, 0x3663c449
	.long	0x34568fd0, 0x363839e2
	.long	0x342d122f, 0x3614efa4
	.long	0x340b893c, 0x35f0b1df
	.long	0x33e0e3a6, 0x35c265d8
	.long	0x33b5237a, 0x359cede7
	.long	0x3391d42c, 0x357d3dc9
	.long	0x336ab0cb, 0x354c3b50
	.long	0x333cc25b, 0x3524a05e
	.long	0x3317be62, 0x3504a304
	.long	0x32f3db16, 0x34d59f46
	.long	0x32c3d8af, 0x34abf19f
	.long	0x329d3680, 0x348a545b
	.long	0x327c475d, 0x345e76f3
	.long	0x324a5141, 0x3432cc8c
	.long	0x32222c05, 0x340fa24c
	.long	0x3201edfc, 0x33e6a843
	.long	0x31d01833, 0x33b91cba
	.long	0x31a68f97, 0x33947ce5
	.long	0x318540a5, 0x336e1a5b
	.long	0x31551b65, 0x333eced8
	.long	0x312a535b, 0x3318d52b
	.long	0x31081119, 0x32f4b613
	.long	0x30d94acf, 0x32c3d10c
	.long	0x30ad6b36, 0x329c9d69
	.long	0x308a563f, 0x327a666d
	.long	0x305c98dc, 0x32481354
	.long	0x302fcd12, 0x321fc975
	.long	0x300c08aa, 0x31ff1904
	.long	0x2fdefaaf, 0x31cb87d8
	.long	0x2fb17113, 0x31a24ef3
	.long	0x2f8d22bb, 0x31815f38
	.long	0x2f60685f, 0x314e2339
	.long	0x2f3251c3, 0x3124258f
	.long	0x2f0da0c6, 0x3102a54d
	.long	0x2ee0dd25, 0x30cfdcca
	.long	0x2eb26c30, 0x30a54727
	.long	0x2e8d8121, 0x30835a7f
	.long	0x2e605773, 0x3050aec3
	.long	0x2e31bffd, 0x3025afef
	.long	0x2e0cc431, 0x30037c6d
	.long	0x2dded902, 0x2fd09664
	.long	0x2db04f61, 0x2fa55e85
	.long	0x2d8b6c69, 0x2f830aa5
	.long	0x2d5c66c4, 0x2f4f93fd
	.long	0x2d2e1f21, 0x2f2453fe
	.long	0x2d097e36, 0x2f0206a5
	.long	0x2cd908c8, 0x2ecdaaf4
	.long	0x2cab3670, 0x2ea293d6
	.long	0x2c86fff0, 0x2e8073d6
	.long	0x2c54ca13, 0x2e4ae1ac
	.long	0x2c279ec9, 0x2e2023e7
	.long	0x2c03f9af, 0x2dfcaee7
	.long	0x2bcfb860, 0x2dc74167
	.long	0x2ba363bd, 0x2d9d0c41
	.long	0x2b807524, 0x2d7770ea
	.long	0x2b49e3d6, 0x2d42d60c
	.long	0x2b1e92b5, 0x2d195702
	.long	0x2af8fac8, 0x2cf13ec4
	.long	0x2ac35eb5, 0x2cbdaded
	.long	0x2a993aaa, 0x2c95101b
	.long	0x2a703d5a, 0x2c6a2c50
	.long	0x2a3c3cf6, 0x2c37d975
	.long	0x2a136bd8, 0x2c104516
	.long	0x29e6cc51, 0x2be24fc5
	.long	0x29b493e1, 0x2bb16ad5
	.long	0x298d376b, 0x2b8b04c7
	.long	0x295cc356, 0x2b59c147
	.long	0x292c79ad, 0x2b2a759f
	.long	0x2906af30, 0x2b055f07
	.long	0x28d23edb, 0x2ad09a6a
	.long	0x28a4050c, 0x2aa30e6d
	.long	0x287fca72, 0x2a7ec8c1
	.long	0x28475b9c, 0x2a46f5b1
	.long	0x281b4cca, 0x2a1b4a74
	.long	0x27f1d725, 0x29f24b83
	.long	0x27bc361f, 0x29bcee14
	.long	0x27926764, 0x29933f23
	.long	0x2763a7e2, 0x29656858
	.long	0x2730ea36, 0x29329e84
	.long	0x27096aae, 0x290b01c6
	.long	0x26d55ed6, 0x28d840d5
	.long	0x26a59297, 0x28a82171
	.long	0x26806b7c, 0x2882a722
	.long	0x26471c70, 0x284af596
	.long	0x261a4874, 0x281d9063
	.long	0x25eefab5, 0x27f4865b
	.long	0x25b8fef0, 0x27bda5bb
	.long	0x258f232d, 0x27930395
	.long	0x255d6497, 0x2763d176
	.long	0x252b220e, 0x27306e78
	.long	0x25043806, 0x270891a3
	.long	0x24cc3533, 0x26d35285
	.long	0x249d9eab, 0x26a36ab9
	.long	0x247333ed, 0x267c9e87
	.long	0x243b895c, 0x2643294f
	.long	0x24108aa2, 0x2616b2d7
	.long	0x23deb305, 0x25e89e19
	.long	0x23ab79f7, 0x25b3722d
	.long	0x2383f8a5, 0x258a5c5b
	.long	0x234b094e, 0x255542a6
	.long	0x231c1be0, 0x252445ca
	.long	0x22eff061, 0x24fcf3b9
	.long	0x22b84dad, 0x24c2a818
	.long	0x228d7fe9, 0x2495b90c
	.long	0x22592b20, 0x246635db
	.long	0x222691fd, 0x2430e58d
	.long	0x21ff65e8, 0x2407dd07
	.long	0x21c3b3ec, 0x23d09839
	.long	0x2195e33f, 0x23a00d5e
	.long	0x21657c23, 0x23757e16
	.long	0x212f973d, 0x233c2e00
	.long	0x210649d6, 0x23102d3f
	.long	0x20cd4d83, 0x22dcd18d
	.long	0x209cdbfe, 0x22a904b4
	.long	0x206f93bd, 0x22814e73
	.long	0x2036de68, 0x2245c0eb
	.long	0x200b8405, 0x22172479
	.long	0x1fd4c713, 0x21e6ec36
	.long	0x1fa22d35, 0x21b0523d
	.long	0x1f771927, 0x21869086
	.long	0x1f3c2718, 0x214d4b0f
	.long	0x1f0f32ff, 0x211c85ba
	.long	0x1ed9ddc3, 0x20ee8f29
	.long	0x1ea5a71b, 0x20b5b53d
	.long	0x1e7bc87b, 0x208a5661
	.long	0x1e3f4167, 0x205288d5
	.long	0x1e11353d, 0x2020208a
	.long	0x1ddc631a, 0x1ff3754b
	.long	0x1da729d6, 0x1fb8fcbd
	.long	0x1d7d76ae, 0x1f8c7d97
	.long	0x1d4010bf, 0x1f554a3f
	.long	0x1d117833, 0x1f21d3cb
	.long	0x1cdc3fc3, 0x1ef57178
	.long	0x1ca6a764, 0x1eba0a73
	.long	0x1c7c141f, 0x1e8cf23a
	.long	0x1c3e8d91, 0x1e5575bf
	.long	0x1c0ff968, 0x1e218fb3
	.long	0x1bd974f4, 0x1df47139
	.long	0x1ba4246f, 0x1db8d48f
	.long	0x1b77ad8b, 0x1d8bb00a
	.long	0x1b3ac5c9, 0x1d5309be
	.long	0x1b0cc6a1, 0x1d1f56ba
	.long	0x1ad41c58, 0x1cf07de1
	.long	0x1a9fb806, 0x1cb56657
	.long	0x1a706b47, 0x1c88c2bc
	.long	0x1a34dbfa, 0x1c4e1cba
	.long	0x1a07fd09, 0x1c1b3d7d
	.long	0x19cc668e, 0x1be9bbfd
	.long	0x19998a40, 0x1bafdf73
	.long	0x19668edd, 0x1b844540
	.long	0x192d054e, 0x1b46dbe6
	.long	0x1901c77a, 0x1b156976
	.long	0x18c29845, 0x1ae0691f
	.long	0x1891d1e0, 0x1aa8720d
	.long	0x185a6f34, 0x1a7cc054
	.long	0x18238672, 0x1a3d887f
	.long	0x17f4b806, 0x1a0e0ecc
	.long	0x17b70648, 0x19d4d840
	.long	0x1788d12d, 0x199f5fda
	.long	0x174c739d, 0x196e8e9b
	.long	0x1718afac, 0x193273f8
	.long	0x16e3f1ae, 0x19056d4a
	.long	0x16aa10bb, 0x18c76cf4
	.long	0x167da48f, 0x1894f659
	.long	0x163d0e1a, 0x185e6d9a
	.long	0x160cd879, 0x1825fb65
	.long	0x15d1c1e5, 0x17f7998c
	.long	0x159c1df9, 0x17b895e1
	.long	0x1568466d, 0x17898a88
	.long	0x152cb568, 0x174cdf9b
	.long	0x15005b01, 0x1718826b
	.long	0x14beb151, 0x16e2f29a
	.long	0x148d955e, 0x16a8c6d9
	.long	0x14522407, 0x167ae8e3
	.long	0x141bdf21, 0x163a6a2d
	.long	0x13e71f72, 0x160a6e25
	.long	0x13ab44c3, 0x15cd7e87
	.long	0x137db4e3, 0x15987319
	.long	0x133bd23f, 0x156215a4
	.long	0x130afa70, 0x15278fa9
	.long	0x12cd92ee, 0x14f840ab
	.long	0x1297f777, 0x14b7cfb1
	.long	0x1260915e, 0x148807fd
	.long	0x1225d8aa, 0x14493e73
	.long	0x11f4d72b, 0x1414c97a
	.long	0x11b4a474, 0x13dbe665
	.long	0x11853669, 0x13a26be2
	.long	0x11446065, 0x136fd110
	.long	0x1110acc4, 0x1330f593
	.long	0x10d51115, 0x13028371
	.long	0x109cd187, 0x12c06c14
	.long	0x1066ba07, 0x128dc782
	.long	0x1029a6c1, 0x1250d3f6
	.long	0x0ff95d83, 0x1219b798
	.long	0x0fb72d9a, 0x11e230b9
	.long	0x0f867e41, 0x11a655c1
	.long	0x0f456641, 0x117484a6
	.long	0x0f10cb43, 0x1133a328
	.long	0x0ed44fd3, 0x1103e85c
	.long	0x0e9b94c1, 0x10c19ffd
	.long	0x0e63e84a, 0x108e0a3d
	.long	0x0e26d8e4, 0x10504b66
	.long	0x0df42c6c, 0x1018a6f6
	.long	0x0db294f0, 0x0fdfa367
	.long	0x0d828bdd, 0x0fa3bcb5
	.long	0x0d3ec540, 0x0f6fa4d1
	.long	0x0d0b5230, 0x0f2f48cc
	.long	0x0ccb653b, 0x0f00259a
	.long	0x0c946596, 0x0ebb479f
	.long	0x00000000, 0x00000000
	.align	16
	.long	0x7fffffff, 0x7fffffff, 0x7fffffff, 0x7fffffff /* _AbsMask */
	.align	16
	.long	0x41210000, 0x41210000, 0x41210000, 0x41210000 /* _MaxThreshold=644.0/64.0 */
	.align	16
	.long	0x80000000, 0x80000000, 0x80000000, 0x80000000 /* sign mask */
	.align	16
	.long	0x48000000, 0x48000000, 0x48000000, 0x48000000 /* SRound */
	.align	16
	.long	0x27800000, 0x27800000, 0x27800000, 0x27800000 /* _TwoM48 */
	// polynomial coefficients
	.align	16
	.long	0x3e08a7ca, 0x3e08a7ca, 0x3e08a7ca, 0x3e08a7ca // poly1[0]
	.align	16
	.long	0xbeaacf22, 0xbeaacf22, 0xbeaacf22, 0xbeaacf22 // poly1[1]
	.align	16
	.long	0x3f005b36, 0x3f005b36, 0x3f005b36, 0x3f005b36 // poly3[0]
	.align	16
	.long	0xbeab4edb, 0xbeab4edb, 0xbeab4edb, 0xbeab4edb // poly3[1]
	.align	16
	.long	0x3f2aaaa6, 0x3f2aaaa6, 0x3f2aaaa6, 0x3f2aaaa6 // poly1[2]
	.align	16
	.long	0xbf7ffffc, 0xbf7ffffc, 0xbf7ffffc, 0xbf7ffffc // poly1[3]
	.align	16
	.long	0x4120DDFB, 0x4120DDFB, 0x4120DDFB, 0x4120DDFB /* UF_Threshold */
	.align	16
	.long	0x57800000, 0x57800000, 0x57800000, 0x57800000 /* 2^48 */
	.align	16
	.type	__svml_serfc_data_internal, @object
	.size	__svml_serfc_data_internal, .-__svml_serfc_data_internal
