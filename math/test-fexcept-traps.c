/* Test fegetexceptflag and fesetexceptflag: exception traps enabled.
   Copyright (C) 2016-2025 Free Software Foundation, Inc.
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

#include <fenv.h>
#include <stdio.h>
#include <math-tests.h>
#include <math-barriers.h>

static int
do_test (void)
{
  int result = 0;

  fedisableexcept (FE_ALL_EXCEPT);
  int ret = feraiseexcept (FE_ALL_EXCEPT);
  if (ret != 0)
    {
      if (EXCEPTION_TESTS (float))
	{
	  puts ("feraiseexcept (FE_ALL_EXCEPT) failed");
	  result = 1;
	  return result;
	}
      else
	{
	  puts ("feraiseexcept (FE_ALL_EXCEPT) unsupported, cannot test");
	  return 77;
	}
    }
  fexcept_t saved;
  ret = fegetexceptflag (&saved, FE_ALL_EXCEPT);
  if (ret != 0)
    {
      puts ("fegetexceptflag failed");
      result = 1;
      return result;
    }
  feclearexcept (FE_ALL_EXCEPT);

  ret = feenableexcept (FE_ALL_EXCEPT);
  if (!EXCEPTION_ENABLE_SUPPORTED (FE_ALL_EXCEPT) && (ret == -1))
    {
      puts ("feenableexcept (FE_ALL_EXCEPT) not supported, cannot test");
      return 77;
    }
  else if (ret != 0)
    {
      puts ("feenableexcept (FE_ALL_EXCEPT) failed");
      result = 1;
    }

  /* The test is that this does not cause exception traps.  For architectures
     where setting the exception might result in traps the function should
     return a nonzero value.
     Also check if the function does not alter the exception mask.  */
  ret = fesetexceptflag (&saved, FE_ALL_EXCEPT);

  _Static_assert (!(EXCEPTION_SET_FORCES_TRAP && !EXCEPTION_TESTS(float)),
		  "EXCEPTION_SET_FORCES_TRAP only makes sense if the "
		  "architecture supports exceptions");
  {
    int exc_before = fegetexcept ();
    ret = fesetexceptflag (&saved, FE_ALL_EXCEPT);
    int exc_after = fegetexcept ();
    if (exc_before != exc_after)
      {
	puts ("fesetexceptflag (FE_ALL_EXCEPT) changed the exceptions mask");
	return 1;
      }
  }

  /* Execute some floating-point operations, since on some CPUs exceptions
     triggers a trap only at the next floating-point instruction.  */
  volatile double a = 1.0;
  volatile double b = a + a;
  math_force_eval (b);
  volatile long double al = 1.0L;
  volatile long double bl = al + al;
  math_force_eval (bl);

  if (ret != 0 && !EXCEPTION_SET_FORCES_TRAP)
    {
      puts ("fesetexceptflag failed");
      result = 1;
    }
  feclearexcept (FE_ALL_EXCEPT);

  return result;
}

#define TEST_FUNCTION do_test ()
#include "../test-skeleton.c"
