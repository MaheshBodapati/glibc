/* Test case for strcpy inside a transactionally executing RTM region.
   Copyright (C) 2021-2025 Free Software Foundation, Inc.
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

#include <tst-string-rtm.h>

#define LOOP 3000
#define STRING_SIZE 1024
char string1[STRING_SIZE];
char string2[STRING_SIZE];

__attribute_optimization_barrier__
static int
prepare (void)
{
  memset (string1, 'a', STRING_SIZE - 1);
  if (strcpy (string2, string1) == string2
      && strcmp (string2, string1) == 0)
    return EXIT_SUCCESS;
  else
    return EXIT_FAILURE;
}

__attribute_optimization_barrier__
static int
function (void)
{
  if (strcpy (string2, string1) == string2
      && strcmp (string2, string1) == 0)
    return 0;
  else
    return 1;
}

static int
do_test (void)
{
  return do_test_1 ("strcpy", LOOP, prepare, function);
}
