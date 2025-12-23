#ifndef SASS_UTIL_H
#define SASS_UTIL_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "sass/base.h"
#include "ast_fwd_decl.hpp"

#include <cmath>
#include <cstring>
#include <vector>
#include <string>
#include <assert.h>

#define SASS_ASSERT(cond, msg) assert(cond && msg)

namespace Sass {

  template <typename T>
  T clip(const T& n, const T& lower, const T& upper) {
    return std::max(lower, std::min(n, upper));
  }

  template <typename T>
  T absmod(const T& n, const T& r) {
    T m = std::fmod(n, r);
    if (m < 0.0) m += r;
    return m;
  }

  double round(double val, size_t precision = 0);
  double sass_strtod(const char* str);
  const char* safe_str(const char *, const char* = "");
  void free_string_array(char **);
  char **copy_strings(const sass::vector<sass::string>&, char ***, int = 0);
  sass::string read_css_string(const sass::string& str, bool css = true);
  sass::string evacuate_escapes(const sass::string& str);
  sass::string string_to_output(const sass::string& str);
  sass::string comment_to_compact_string(const sass::string& text);
  sass::string read_hex_escapes(const sass::string& str);
  sass::string escape_string(const sass::string& str);
  void newline_to_space(sass::string& str);

  sass::string quote(const sass::string&, char q = 0);
  sass::string unquote(const sass::string&, char* q = 0, bool keep_utf8_sequences = false, bool strict = true);
  char detect_best_quotemark(const char* s, char qm = '"');

  bool is_hex_doublet(double n);
  bool is_color_doublet(double r, double g, double b);

  bool peek_linefeed(const char* start);

  // Returns true iff `elements` ⊆ `container`.
  template <typename C, typename T>
  bool contains_all(C container, T elements) {
    for (const auto &el : elements) {
      if (container.find(el) == container.end()) return false;
    }
    return true;
  }

  // C++20 `starts_with` equivalent.
  // See https://en.cppreference.com/w/cpp/string/basic_string/starts_with
  inline bool starts_with(const sass::string& str, const char* prefix, size_t prefix_len) {
    return str.compare(0, prefix_len, prefix) == 0;
  }

  inline bool starts_with(const sass::string& str, const char* prefix) {
    return starts_with(str, prefix, std::strlen(prefix));
  }

  // C++20 `ends_with` equivalent.
  // See https://en.cppreference.com/w/cpp/string/basic_string/ends_with
  inline bool ends_with(const sass::string& str, const sass::string& suffix) {
    return suffix.size() <= str.size() && std::equal(suffix.rbegin(), suffix.rend(), str.rbegin());
  }

  inline bool ends_with(const sass::string& str, const char* suffix, size_t suffix_len) {
    if (suffix_len > str.size()) return false;
    const char* suffix_it = suffix + suffix_len;
    const char* str_it = str.c_str() + str.size();
    while (suffix_it != suffix) if (*(--suffix_it) != *(--str_it)) return false;
    return true;
  }

  inline bool ends_with(const sass::string& str, const char* suffix) {
    return ends_with(str, suffix, std::strlen(suffix));
  }

  namespace Util {

    bool isPrintable(StyleRule* r, Sass_Output_Style style = NESTED);
    bool isPrintable(SupportsRule* r, Sass_Output_Style style = NESTED);
    bool isPrintable(CssMediaRule* r, Sass_Output_Style style = NESTED);
    bool isPrintable(Comment* b, Sass_Output_Style style = NESTED);
    bool isPrintable(Block_Obj b, Sass_Output_Style style = NESTED);
    bool isPrintable(String_Constant* s, Sass_Output_Style style = NESTED);
    bool isPrintable(String_Quoted* s, Sass_Output_Style style = NESTED);
    bool isPrintable(Declaration* d, Sass_Output_Style style = NESTED);

  }
}
#endif
