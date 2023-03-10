/* We have to irritate the compiler a bit.  */
#define __strtoull_internal __strtoull_internal_XXX
#define strtoull strtoull_XXX
#define strtouq strtouq_XXX
#define __isoc23_strtoull __isoc23_strtoull_XXX

#include <stdlib/strtoul.c>

#undef __strtoull_internal
#undef strtoull
#undef strtouq
#undef __isoc23_strtoull
strong_alias (__strtoul_internal, __strtoull_internal)
libc_hidden_ver (__strtoul_internal, __strtoull_internal)
weak_alias (strtoul, strtoull)
weak_alias (strtoul, strtouq)
weak_alias (strtoul, strtoumax)
weak_alias (__isoc23_strtoul, __isoc23_strtoull)
libc_hidden_ver (__isoc23_strtoul, __isoc23_strtoull)
weak_alias (__isoc23_strtoul, __isoc23_strtoumax)
