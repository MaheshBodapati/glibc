/* Copyright (C) 1997-2025 Free Software Foundation, Inc.
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

#include <sys/types.h>
#include <errno.h>
#include <unistd.h>

/* Truncate the file referenced by FD to LENGTH bytes.  */
int
__ftruncate64 (int fd, off64_t length)
{
  if ((off_t) length != length)
    {
      __set_errno (EINVAL);
      return -1;
    }
  return __ftruncate (fd, (off_t) length);
}
weak_alias (__ftruncate64, ftruncate64)
