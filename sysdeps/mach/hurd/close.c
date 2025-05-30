/* Copyright (C) 1991-2025 Free Software Foundation, Inc.
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
#include <unistd.h>
#include <hurd.h>
#include <hurd/fd.h>
#include <sysdep-cancel.h>

/* Close the file descriptor FD.  */
int
__close (int fd)
{
  error_t err;
  int cancel_oldtype;

  cancel_oldtype = LIBC_CANCEL_ASYNC();
  err = HURD_FD_USE (fd, _hurd_fd_close (descriptor));
  LIBC_CANCEL_RESET (cancel_oldtype);

  return err ? __hurd_fail (err) : 0;
}
libc_hidden_def (__close)
strong_alias (__close, __libc_close)
weak_alias (__close, close)
