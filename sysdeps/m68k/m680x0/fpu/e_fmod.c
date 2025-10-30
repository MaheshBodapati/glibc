/* Copyright (C) 1996-2025 Free Software Foundation, Inc.
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
   License along with the GNU C Library.  If not, see
   <https://www.gnu.org/licenses/>.  */

#include <libm-alias-double.h>
#include <libm-alias-finite.h>
#include <math.h>
#include "mathimpl.h"
#include "math_config.h"

double
__fmod (double x, double y)
{
  uint64_t hx = asuint64 (x);
  uint64_t hy = asuint64 (y);

  /* fmod(+-Inf,y) or fmod(x,0) */
  if (__glibc_unlikely ((is_inf (hx) || y == 0.0)
			&& !is_nan (hy)
			&& !is_nan (hx)))
    return __math_invalid (x);

  return __m81_u(fmod)(x, y);
}
strong_alias (__fmod, __ieee754_fmod)
libm_alias_finite (__ieee754_fmod, __fmod)
versioned_symbol (libm, __fmod, fmod, GLIBC_2_43);
libm_alias_double_other (__fmod, fmod)
