/* futimes -- change access and modification times of open file.  Stub version.
   Copyright (C) 2002-2025 Free Software Foundation, Inc.
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

#include <sys/time.h>
#include <errno.h>

/* Change the access time of FILE to TVP[0] and
   the modification time of FILE to TVP[1], but do not follow symlinks.  */
int
__futimes (int fd, const struct timeval tvp[2])
{
  __set_errno (ENOSYS);
  return -1;
}
weak_alias (__futimes, futimes)

stub_warning (futimes)
