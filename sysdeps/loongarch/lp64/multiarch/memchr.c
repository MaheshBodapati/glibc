/* Multiple versions of memchr.
   All versions must be listed in ifunc-impl-list.c.
   Copyright (C) 2023-2025 Free Software Foundation, Inc.
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

/* Define multiple versions only for the definition in libc.  */
#if IS_IN (libc)
# define memchr __redirect_memchr
# include <string.h>
# undef memchr

# define SYMBOL_NAME memchr
# include "ifunc-memchr.h"

libc_ifunc_redirected (__redirect_memchr, memchr,
		       IFUNC_SELECTOR ());

# ifdef SHARED
__hidden_ver1 (memchr, __GI_memchr, __redirect_memchr)
  __attribute__ ((visibility ("hidden"))) __attribute_copy__ (memchr);
# endif

#endif
