/* Optimized strncpy implementation for POWER8.
   Copyright (C) 2015-2025 Free Software Foundation, Inc.
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

#define STRNCPY __strncpy_power8

#undef libc_hidden_builtin_def
#define libc_hidden_builtin_def(name)

/* memset is used to pad the end of the string.  */
#define MEMSET __memset_power8
#ifdef SHARED
#define MEMSET_is_local
#endif

#include <sysdeps/powerpc/powerpc64/power8/strncpy.S>
