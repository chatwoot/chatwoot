#ifndef CMARK_CONFIG_H
#define CMARK_CONFIG_H

#ifdef __cplusplus
extern "C" {
#endif

#define HAVE_STDBOOL_H

#ifdef HAVE_STDBOOL_H
  #include <stdbool.h>
#elif !defined(__cplusplus)
  typedef char bool;
#endif

#define HAVE___BUILTIN_EXPECT

#define HAVE___ATTRIBUTE__

#ifdef HAVE___ATTRIBUTE__
  #define CMARK_ATTRIBUTE(list) __attribute__ (list)
#else
  #define CMARK_ATTRIBUTE(list)
#endif

#ifndef CMARK_INLINE
  #if defined(_MSC_VER) && !defined(__cplusplus)
    #define CMARK_INLINE __inline
  #else
    #define CMARK_INLINE inline
  #endif
#endif

/* snprintf and vsnprintf fallbacks for MSVC before 2015,
   due to Valentin Milea http://stackoverflow.com/questions/2915672/
*/

#if defined(_MSC_VER) && _MSC_VER < 1900

#include <stdio.h>
#include <stdarg.h>

#define snprintf c99_snprintf
#define vsnprintf c99_vsnprintf

CMARK_INLINE int c99_vsnprintf(char *outBuf, size_t size, const char *format, va_list ap)
{
    int count = -1;

    if (size != 0)
        count = _vsnprintf_s(outBuf, size, _TRUNCATE, format, ap);
    if (count == -1)
        count = _vscprintf(format, ap);

    return count;
}

CMARK_INLINE int c99_snprintf(char *outBuf, size_t size, const char *format, ...)
{
    int count;
    va_list ap;

    va_start(ap, format);
    count = c99_vsnprintf(outBuf, size, format, ap);
    va_end(ap);

    return count;
}

#endif

#ifdef __cplusplus
}
#endif

#endif
