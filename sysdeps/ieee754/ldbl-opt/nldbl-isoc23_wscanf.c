#include "nldbl-compat.h"

int
attribute_hidden
__isoc23_wscanf (const wchar_t *fmt, ...)
{
  va_list arg;
  int done;

  va_start (arg, fmt);
  done = __nldbl___isoc23_vfwscanf (stdin, fmt, arg);
  va_end (arg);

  return done;
}
