/* Copyright (C) 2005-2025 Free Software Foundation, Inc.
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

#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <unistd.h>


/* Make a link to FROM relative to FROMFD called TO relative to TOFD.  */
int
linkat (int fromfd, const char *from, int tofd, const char *to, int flags)
{
  if (from == NULL || to == NULL)
    {
      __set_errno (EINVAL);
      return -1;
    }

  if ((tofd != AT_FDCWD && tofd < 0 && *to != '/')
      || (fromfd != AT_FDCWD && fromfd < 0 && *from != '/'))
    {
      __set_errno (EBADF);
      return -1;
    }

  __set_errno (ENOSYS);
  return -1;
}
stub_warning (linkat)
