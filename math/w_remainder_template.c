/* Wrapper to set errno for remainder.
   Copyright (C) 2017-2025 Free Software Foundation, Inc.
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

/* Only build wrappers from the templates for the types that define the macro
   below.  This macro is set in math-type-macros-<type>.h in sysdeps/generic
   for each floating-point type.  */
#if __USE_WRAPPER_TEMPLATE

# include <errno.h>
# include <fenv.h>
# include <math.h>
# include <math_private.h>

FLOAT
M_DECL_FUNC (__remainder) (FLOAT x, FLOAT y)
{
  if (__glibc_unlikely (isinf (x) || y == 0) && !isnan (y) && !isnan (x))
    /* Domain error: remainder(+-Inf,y) or remainder(x,0).
       If x or y are nan, these conditions should not be considered.  */
    __set_errno (EDOM);
  return M_SUF (__ieee754_remainder) (x, y);
}
declare_mgen_alias (__remainder, remainder)

#endif /* __USE_WRAPPER_TEMPLATE.  */
