/* Function cbrtf vectorized in AVX ISA as wrapper to SSE4 ISA version.
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
   <https://www.gnu.org/licenses/>.  */

#include <sysdep.h>
#include "svml_s_wrapper_impl.h"

	.section .text.avx2, "ax", @progbits
ENTRY (_ZGVcN8v_cbrtf)
WRAPPER_IMPL_AVX _ZGVbN4v_cbrtf
END (_ZGVcN8v_cbrtf)
