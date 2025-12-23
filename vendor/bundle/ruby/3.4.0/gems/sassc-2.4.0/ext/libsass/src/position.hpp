#ifndef SASS_POSITION_H
#define SASS_POSITION_H

#include <string>
#include <cstring>
#include "source_data.hpp"
#include "ast_fwd_decl.hpp"

namespace Sass {


  class Offset {

    public: // c-tor
      Offset(const char chr);
      Offset(const char* string);
      Offset(const sass::string& text);
      Offset(const size_t line, const size_t column);

      // return new position, incremented by the given string
      Offset add(const char* begin, const char* end);
      Offset inc(const char* begin, const char* end) const;

      // init/create instance from const char substring
      static Offset init(const char* beg, const char* end);

    public: // overload operators for position
      void operator+= (const Offset &pos);
      bool operator== (const Offset &pos) const;
      bool operator!= (const Offset &pos) const;
      Offset operator+ (const Offset &off) const;
      Offset operator- (const Offset &off) const;

    public: // overload output stream operator
      // friend std::ostream& operator<<(std::ostream& strm, const Offset& off);

    public:
      Offset off() { return *this; }

    public:
      size_t line;
      size_t column;

  };

  class Position : public Offset {

    public: // c-tor
      Position(const size_t file); // line(0), column(0)
      Position(const size_t file, const Offset& offset);
      Position(const size_t line, const size_t column); // file(-1)
      Position(const size_t file, const size_t line, const size_t column);

    public: // overload operators for position
      void operator+= (const Offset &off);
      bool operator== (const Position &pos) const;
      bool operator!= (const Position &pos) const;
      const Position operator+ (const Offset &off) const;
      const Offset operator- (const Offset &off) const;
      // return new position, incremented by the given string
      Position add(const char* begin, const char* end);
      Position inc(const char* begin, const char* end) const;

    public: // overload output stream operator
      // friend std::ostream& operator<<(std::ostream& strm, const Position& pos);

    public:
      size_t file;

  };

  // Token type for representing lexed chunks of text
  class Token {
  public:
    const char* prefix;
    const char* begin;
    const char* end;

    Token()
    : prefix(0), begin(0), end(0) { }
    Token(const char* b, const char* e)
    : prefix(b), begin(b), end(e) { }
    Token(const char* str)
    : prefix(str), begin(str), end(str + strlen(str)) { }
    Token(const char* p, const char* b, const char* e)
    : prefix(p), begin(b), end(e) { }

    size_t length()    const { return end - begin; }
    sass::string ws_before() const { return sass::string(prefix, begin); }
    sass::string to_string() const { return sass::string(begin, end); }
    sass::string time_wspace() const {
      sass::string str(to_string());
      sass::string whitespaces(" \t\f\v\n\r");
      return str.erase(str.find_last_not_of(whitespaces)+1);
    }

    operator bool()        { return begin && end && begin >= end; }
    operator sass::string() { return to_string(); }

    bool operator==(Token t)  { return to_string() == t.to_string(); }
  };

  class SourceSpan {

    public:

      SourceSpan(const char* path);

      SourceSpan(SourceDataObj source,
        const Offset& position = Offset(0, 0),
        const Offset& offset = Offset(0, 0));

      const char* getPath() const {
        return source->getPath();
      }

      const char* getRawData() const {
        return source->getRawData();
      }

      Offset getPosition() const {
        return position;
      }

      size_t getLine() const {
        return position.line + 1;
      }

      size_t getColumn() const {
        return position.column + 1;
      }

      size_t getSrcId() const {
        return source == nullptr
          ? std::string::npos
          : source->getSrcId();
      }

      SourceDataObj source;
      Offset position;
      Offset offset;

  };

}

#endif
