#ifndef SASS_UTIL_STRING_H
#define SASS_UTIL_STRING_H

#include "sass.hpp"
#include <string>

namespace Sass {
  namespace Util {

    // ##########################################################################
    // Special case insensitive string matcher. We can optimize
    // the more general compare case quite a bit by requiring
    // consumers to obey some rules (lowercase and no space).
    // - `literal` must only contain lower case ascii characters
    // there is one edge case where this could give false positives
    // test could contain a (non-ascii) char exactly 32 below literal
    // ##########################################################################
    bool equalsLiteral(const char* lit, const sass::string& test);

    // ###########################################################################
    // Returns [name] without a vendor prefix.
    // If [name] has no vendor prefix, it's returned as-is.
    // ###########################################################################
    sass::string unvendor(const sass::string& name);

    sass::string rtrim(sass::string str);
    sass::string normalize_newlines(const sass::string& str);
    sass::string normalize_underscores(const sass::string& str);
    sass::string normalize_decimals(const sass::string& str);
    char opening_bracket_for(char closing_bracket);
    char closing_bracket_for(char opening_bracket);

    // Locale-independent ASCII character routines.

    inline bool ascii_isalpha(unsigned char c) {
      return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
    }

    inline bool ascii_isdigit(unsigned char c) {
      return (c >= '0' && c <= '9');
    }

    inline bool ascii_isalnum(unsigned char c) {
      return ascii_isalpha(c) || ascii_isdigit(c);
    }

    inline bool ascii_isascii(unsigned char c) { return c < 128; }

    inline bool ascii_isxdigit(unsigned char c) {
      return ascii_isdigit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
    }

    inline bool ascii_isspace(unsigned char c) {
      return c == ' ' || c == '\t' || c == '\v' || c == '\f' || c == '\r' || c == '\n';
    }

    inline char ascii_tolower(unsigned char c) {
      if (c >= 'A' && c <= 'Z') return c + 32;
      return c;
    }

    void ascii_str_tolower(sass::string* s);

    inline char ascii_toupper(unsigned char c) {
      if (c >= 'a' && c <= 'z') return c - 32;
      return c;
    }

    void ascii_str_toupper(sass::string* s);

  }  // namespace Sass
}  // namespace Util
#endif  // SASS_UTIL_STRING_H
