// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <iostream>
#include <iomanip>
#include "lexer.hpp"
#include "constants.hpp"
#include "util_string.hpp"


namespace Sass {
  using namespace Constants;

  namespace Prelexer {

    //####################################
    // BASIC CHARACTER MATCHERS
    //####################################

    // Match standard control chars
    const char* kwd_at(const char* src) { return exactly<'@'>(src); }
    const char* kwd_dot(const char* src) { return exactly<'.'>(src); }
    const char* kwd_comma(const char* src) { return exactly<','>(src); };
    const char* kwd_colon(const char* src) { return exactly<':'>(src); };
    const char* kwd_star(const char* src) { return exactly<'*'>(src); };
    const char* kwd_plus(const char* src) { return exactly<'+'>(src); };
    const char* kwd_minus(const char* src) { return exactly<'-'>(src); };
    const char* kwd_slash(const char* src) { return exactly<'/'>(src); };

    bool is_number(char chr) {
      return Util::ascii_isdigit(static_cast<unsigned char>(chr)) ||
        chr == '-' || chr == '+';
    }

    // check if char is within a reduced ascii range
    // valid in a uri (copied from Ruby Sass)
    bool is_uri_character(char chr)
    {
      unsigned int cmp = unsigned(chr);
      return (cmp > 41 && cmp < 127) ||
             cmp == ':' || cmp == '/';
    }

    // check if char is within a reduced ascii range
    // valid for escaping (copied from Ruby Sass)
    bool is_escapable_character(char chr)
    {
      unsigned int cmp = unsigned(chr);
      return cmp > 31 && cmp < 127;
    }

    // Match word character (look ahead)
    bool is_character(char chr)
    {
      // valid alpha, numeric or unicode char (plus hyphen)
      return Util::ascii_isalnum(static_cast<unsigned char>(chr)) ||
        !Util::ascii_isascii(static_cast<unsigned char>(chr)) ||
        chr == '-';
    }

    //####################################
    // BASIC CLASS MATCHERS
    //####################################

    // create matchers that advance the position
    const char* space(const char* src) { return Util::ascii_isspace(static_cast<unsigned char>(*src)) ? src + 1 : nullptr; }
    const char* alpha(const char* src) { return Util::ascii_isalpha(static_cast<unsigned char>(*src)) ? src + 1 : nullptr; }
    const char* nonascii(const char* src) { return Util::ascii_isascii(static_cast<unsigned char>(*src)) ? nullptr : src + 1; }
    const char* digit(const char* src) { return Util::ascii_isdigit(static_cast<unsigned char>(*src)) ? src + 1 : nullptr; }
    const char* xdigit(const char* src) { return Util::ascii_isxdigit(static_cast<unsigned char>(*src)) ? src + 1 : nullptr; }
    const char* alnum(const char* src) { return Util::ascii_isalnum(static_cast<unsigned char>(*src)) ? src + 1 : nullptr; }
    const char* hyphen(const char* src) { return *src == '-' ? src + 1 : 0; }
    const char* uri_character(const char* src) { return is_uri_character(*src) ? src + 1 : 0; }
    const char* escapable_character(const char* src) { return is_escapable_character(*src) ? src + 1 : 0; }

    // Match multiple ctype characters.
    const char* spaces(const char* src) { return one_plus<space>(src); }
    const char* digits(const char* src) { return one_plus<digit>(src); }
    const char* hyphens(const char* src) { return one_plus<hyphen>(src); }

    // Whitespace handling.
    const char* no_spaces(const char* src) { return negate< space >(src); }
    const char* optional_spaces(const char* src) { return zero_plus< space >(src); }

    // Match any single character.
    const char* any_char(const char* src) { return *src ? src + 1 : src; }

    // Match word boundary (zero-width lookahead).
    const char* word_boundary(const char* src) { return is_character(*src) || *src == '#' ? 0 : src; }

    // Match linefeed /(?:\n|\r\n?|\f)/
    const char* re_linebreak(const char* src)
    {
      // end of file or unix linefeed return here
      if (*src == 0) return src;
      // end of file or unix linefeed return here
      if (*src == '\n' || *src == '\f') return src + 1;
      // a carriage return may optionally be followed by a linefeed
      if (*src == '\r') return *(src + 1) == '\n' ? src + 2 : src + 1;
      // no linefeed
      return 0;
    }

    // Assert string boundaries (/\Z|\z|\A/)
    // This is a zero-width positive lookahead
    const char* end_of_line(const char* src)
    {
      // end of file or unix linefeed return here
      return *src == 0 || *src == '\n' || *src == '\r' || *src == '\f' ? src : 0;
    }

    // Assert end_of_file boundary (/\z/)
    // This is a zero-width positive lookahead
    const char* end_of_file(const char* src)
    {
      // end of file or unix linefeed return here
      return *src == 0 ? src : 0;
    }

  }
}
