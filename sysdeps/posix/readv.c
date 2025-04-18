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

#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <scratch_buffer.h>
#include <stdbool.h>
#include <sys/param.h>
#include <sys/uio.h>
#include <errno.h>


static void
ifree (struct scratch_buffer *sbuf)
{
  scratch_buffer_free (sbuf);
}

/* Read data from file descriptor FD, and put the result in the
   buffers described by VECTOR, which is a vector of COUNT 'struct iovec's.
   The buffers are filled in the order specified.
   Operates just like 'read' (see <unistd.h>) except that data are
   put in VECTOR instead of a contiguous buffer.  */
ssize_t
__readv (int fd, const struct iovec *vector, int count)
{
  /* Find the total number of bytes to be read.  */
  size_t bytes = 0;
  for (int i = 0; i < count; ++i)
    {
      /* Check for ssize_t overflow.  */
      if (SSIZE_MAX - bytes < vector[i].iov_len)
	{
	  __set_errno (EINVAL);
	  return -1;
	}
      bytes += vector[i].iov_len;
    }

  /* Allocate a temporary buffer to hold the data.  Use a scratch_buffer
     since it's faster for small buffer sizes but can handle larger
     allocations as well.  */

  struct scratch_buffer __attribute__ ((__cleanup__ (ifree))) buf;
  scratch_buffer_init (&buf);
  if (!scratch_buffer_set_array_size (&buf, 1, bytes))
    return -1;
  char *buffer = buf.data;

  /* Read the data.  */
  ssize_t bytes_read = __read (fd, buffer, bytes);
  if (bytes_read < 0)
    return -1;

  /* Copy the data from BUFFER into the memory specified by VECTOR.  */
  bytes = bytes_read;
  for (int i = 0; i < count; ++i)
    {
      size_t copy = MIN (vector[i].iov_len, bytes);

      (void) memcpy ((void *) vector[i].iov_base, (void *) buffer, copy);

      buffer += copy;
      bytes -= copy;
      if (bytes == 0)
	break;
    }

  return bytes_read;
}
libc_hidden_def (__readv)
weak_alias (__readv, readv)
