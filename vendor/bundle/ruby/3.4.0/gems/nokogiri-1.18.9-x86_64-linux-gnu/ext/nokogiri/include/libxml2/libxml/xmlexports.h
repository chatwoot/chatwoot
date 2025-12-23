/*
 * Summary: macros for marking symbols as exportable/importable.
 * Description: macros for marking symbols as exportable/importable.
 *
 * Copy: See Copyright for the status of this software.
 */

#ifndef __XML_EXPORTS_H__
#define __XML_EXPORTS_H__

/** DOC_DISABLE */

/*
 * Symbol visibility
 */

#if defined(_WIN32) || defined(__CYGWIN__)
  #ifdef LIBXML_STATIC
    #define XMLPUBLIC
  #elif defined(IN_LIBXML)
    #define XMLPUBLIC __declspec(dllexport)
  #else
    #define XMLPUBLIC __declspec(dllimport)
  #endif
#else /* not Windows */
  #define XMLPUBLIC
#endif /* platform switch */

#define XMLPUBFUN XMLPUBLIC

#define XMLPUBVAR XMLPUBLIC extern

/* Compatibility */
#define XMLCALL
#define XMLCDECL
#ifndef LIBXML_DLL_IMPORT
  #define LIBXML_DLL_IMPORT XMLPUBVAR
#endif

/*
 * Attributes
 */

#ifndef ATTRIBUTE_UNUSED
  #if __GNUC__ * 100 + __GNUC_MINOR__ >= 207 || defined(__clang__)
    #define ATTRIBUTE_UNUSED __attribute__((unused))
  #else
    #define ATTRIBUTE_UNUSED
  #endif
#endif

#if !defined(__clang__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 403)
  #define LIBXML_ATTR_ALLOC_SIZE(x) __attribute__((alloc_size(x)))
#else
  #define LIBXML_ATTR_ALLOC_SIZE(x)
#endif

#if __GNUC__ * 100 + __GNUC_MINOR__ >= 303
  #define LIBXML_ATTR_FORMAT(fmt,args) \
    __attribute__((__format__(__printf__,fmt,args)))
#else
  #define LIBXML_ATTR_FORMAT(fmt,args)
#endif

#ifndef XML_DEPRECATED
  #if defined(IN_LIBXML)
    #define XML_DEPRECATED
  #elif __GNUC__ * 100 + __GNUC_MINOR__ >= 301
    #define XML_DEPRECATED __attribute__((deprecated))
  #elif defined(_MSC_VER) && _MSC_VER >= 1400
    /* Available since Visual Studio 2005 */
    #define XML_DEPRECATED __declspec(deprecated)
  #else
    #define XML_DEPRECATED
  #endif
#endif

/*
 * Warnings pragmas, should be moved from public headers
 */

#if defined(__LCC__)

  #define XML_IGNORE_FPTR_CAST_WARNINGS
  #define XML_POP_WARNINGS \
    _Pragma("diag_default 1215")

#elif defined(__clang__) || (__GNUC__ * 100 + __GNUC_MINOR__ >= 406)

  #if defined(__clang__) || (__GNUC__ * 100 + __GNUC_MINOR__ >= 800)
    #define XML_IGNORE_FPTR_CAST_WARNINGS \
      _Pragma("GCC diagnostic push") \
      _Pragma("GCC diagnostic ignored \"-Wpedantic\"") \
      _Pragma("GCC diagnostic ignored \"-Wcast-function-type\"")
  #else
    #define XML_IGNORE_FPTR_CAST_WARNINGS \
      _Pragma("GCC diagnostic push") \
      _Pragma("GCC diagnostic ignored \"-Wpedantic\"")
  #endif
  #define XML_POP_WARNINGS \
    _Pragma("GCC diagnostic pop")

#elif defined(_MSC_VER) && _MSC_VER >= 1400

  #define XML_IGNORE_FPTR_CAST_WARNINGS __pragma(warning(push))
  #define XML_POP_WARNINGS __pragma(warning(pop))

#else

  #define XML_IGNORE_FPTR_CAST_WARNINGS
  #define XML_POP_WARNINGS

#endif

/*
 * Accessors for globals
 */

#define XML_NO_ATTR

#ifdef LIBXML_THREAD_ENABLED
  #define XML_DECLARE_GLOBAL(name, type, attrs) \
    attrs XMLPUBFUN type *__##name(void);
  #define XML_GLOBAL_MACRO(name) (*__##name())
#else
  #define XML_DECLARE_GLOBAL(name, type, attrs) \
    attrs XMLPUBVAR type name;
#endif

/*
 * Originally declared in xmlversion.h which is generated
 */

#ifdef __cplusplus
extern "C" {
#endif

XMLPUBFUN void xmlCheckVersion(int version);

#ifdef __cplusplus
}
#endif

#endif /* __XML_EXPORTS_H__ */


