#ifndef fsevent_watch_defines_h
#define fsevent_watch_defines_h

#define _str(s) #s
#define _xstr(s) _str(s)

#define COMPILED_AT __DATE__ " " __TIME__

#if defined (__clang__)
#define COMPILER "clang " __clang_version__
#elif defined (__GNUC__)
#define COMPILER "gcc " __VERSION__
#else
#define COMPILER "unknown"
#endif

#if defined(__ppc__)
#define TARGET_CPU "ppc"
#elif defined(__ppc64__)
#define TARGET_CPU "ppc64"
#elif defined(__i386__)
#define TARGET_CPU "i386"
#elif defined(__x86_64__)
#define TARGET_CPU "x86_64"
#elif defined(__arm64__)
#define TARGET_CPU "arm64"
#else
#define TARGET_CPU "unknown"
#endif

#define FLAG_CHECK(flags, flag) ((flags) & (flag))

#define FPRINTF_FLAG_CHECK(flags, flag, msg, fd)  \
  do {                                            \
    if (FLAG_CHECK(flags, flag)) {                \
      fprintf(fd, "%s", msg "\n"); } }            \
  while (0)

#define FLAG_CHECK_STDERR(flags, flag, msg)       \
        FPRINTF_FLAG_CHECK(flags, flag, msg, stderr)

#endif /* fsevent_watch_defines_h */
