/* getsockname with error checking.
   Copyright (C) 2016-2025 Free Software Foundation, Inc.
   Copyright The GNU Toolchain Authors.
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

#include <support/xsocket.h>

#include <stdio.h>
#include <stdlib.h>
#include <support/check.h>

void
xgetsockname (int fd, struct sockaddr *sa, socklen_t *plen)
{
  if (getsockname (fd, sa, plen) != 0)
    FAIL_EXIT1 ("getsockname (%d): %m", fd);
}
