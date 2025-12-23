#ifndef SASS_AST_VALUES_H
#define SASS_AST_VALUES_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"

namespace Sass {

  //////////////////////////////////////////////////////////////////////
  // Still just an expression, but with a to_string method
  //////////////////////////////////////////////////////////////////////
  class PreValue : public Expression {
  public:
    PreValue(SourceSpan pstate, bool d = false, bool e = false, bool i = false, Type ct = NONE);
    ATTACH_VIRTUAL_AST_OPERATIONS(PreValue);
    virtual ~PreValue() { }
  };

  //////////////////////////////////////////////////////////////////////
  // base class for values that support operations
  //////////////////////////////////////////////////////////////////////
  class Value : public PreValue {
  public:
    Value(SourceSpan pstate, bool d = false, bool e = false, bool i = false, Type ct = NONE);

    // Some obects are not meant to be compared
    // ToDo: maybe fallback to pointer comparison?
    virtual bool operator< (const Expression& rhs) const override = 0;
    virtual bool operator== (const Expression& rhs) const override = 0;

    // We can give some reasonable implementations by using
    // inverst operators on the specialized implementations
    virtual bool operator> (const Expression& rhs) const {
      return rhs < *this;
    }
    virtual bool operator!= (const Expression& rhs) const {
      return !(*this == rhs);
    }

    ATTACH_VIRTUAL_AST_OPERATIONS(Value);

  };

  ///////////////////////////////////////////////////////////////////////
  // Lists of values, both comma- and space-separated (distinguished by a
  // type-tag.) Also used to represent variable-length argument lists.
  ///////////////////////////////////////////////////////////////////////
  class List : public Value, public Vectorized<ExpressionObj> {
    void adjust_after_pushing(ExpressionObj e) override { is_expanded(false); }
  private:
    ADD_PROPERTY(enum Sass_Separator, separator)
    ADD_PROPERTY(bool, is_arglist)
    ADD_PROPERTY(bool, is_bracketed)
    ADD_PROPERTY(bool, from_selector)
  public:
    List(SourceSpan pstate, size_t size = 0, enum Sass_Separator sep = SASS_SPACE, bool argl = false, bool bracket = false);
    sass::string type() const override { return is_arglist_ ? "arglist" : "list"; }
    static sass::string type_name() { return "list"; }
    const char* sep_string(bool compressed = false) const {
      return separator() == SASS_SPACE ?
        " " : (compressed ? "," : ", ");
    }
    bool is_invisible() const override { return empty() && !is_bracketed(); }
    ExpressionObj value_at_index(size_t i);

    virtual size_t hash() const override;
    virtual size_t size() const;
    virtual void set_delayed(bool delayed) override;

    virtual bool operator< (const Expression& rhs) const override;
    virtual bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(List)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////////////////////////////////
  // Key value paris.
  ///////////////////////////////////////////////////////////////////////
  class Map : public Value, public Hashed<ExpressionObj, ExpressionObj, Map_Obj> {
    void adjust_after_pushing(std::pair<ExpressionObj, ExpressionObj> p) override { is_expanded(false); }
  public:
    Map(SourceSpan pstate, size_t size = 0);
    sass::string type() const override { return "map"; }
    static sass::string type_name() { return "map"; }
    bool is_invisible() const override { return empty(); }
    List_Obj to_list(SourceSpan& pstate);

    virtual size_t hash() const override;

    virtual bool operator< (const Expression& rhs) const override;
    virtual bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Map)
    ATTACH_CRTP_PERFORM_METHODS()
  };


  //////////////////////////////////////////////////////////////////////////
  // Binary expressions. Represents logical, relational, and arithmetic
  // operations. Templatized to avoid large switch statements and repetitive
  // subclassing.
  //////////////////////////////////////////////////////////////////////////
  class Binary_Expression : public PreValue {
  private:
    HASH_PROPERTY(Operand, op)
    HASH_PROPERTY(ExpressionObj, left)
    HASH_PROPERTY(ExpressionObj, right)
    mutable size_t hash_;
  public:
    Binary_Expression(SourceSpan pstate,
                      Operand op, ExpressionObj lhs, ExpressionObj rhs);

    const sass::string type_name();
    const sass::string separator();
    bool is_left_interpolant(void) const override;
    bool is_right_interpolant(void) const override;
    bool has_interpolant() const override;

    virtual void set_delayed(bool delayed) override;

    virtual bool operator< (const Expression& rhs) const override;
    virtual bool operator==(const Expression& rhs) const override;

    virtual size_t hash() const override;
    enum Sass_OP optype() const { return op_.operand; }
    ATTACH_AST_OPERATIONS(Binary_Expression)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////
  // Function reference.
  ////////////////////////////////////////////////////
  class Function final : public Value {
  public:
    ADD_PROPERTY(Definition_Obj, definition)
    ADD_PROPERTY(bool, is_css)
  public:
    Function(SourceSpan pstate, Definition_Obj def, bool css);

    sass::string type() const override { return "function"; }
    static sass::string type_name() { return "function"; }
    bool is_invisible() const override { return true; }

    sass::string name();

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Function)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////
  // Function calls.
  //////////////////
  class Function_Call final : public PreValue {
    HASH_CONSTREF(String_Obj, sname)
    HASH_PROPERTY(Arguments_Obj, arguments)
    HASH_PROPERTY(Function_Obj, func)
    ADD_PROPERTY(bool, via_call)
    ADD_PROPERTY(void*, cookie)
    mutable size_t hash_;
  public:
    Function_Call(SourceSpan pstate, sass::string n, Arguments_Obj args, void* cookie);
    Function_Call(SourceSpan pstate, sass::string n, Arguments_Obj args, Function_Obj func);
    Function_Call(SourceSpan pstate, sass::string n, Arguments_Obj args);

    Function_Call(SourceSpan pstate, String_Obj n, Arguments_Obj args, void* cookie);
    Function_Call(SourceSpan pstate, String_Obj n, Arguments_Obj args, Function_Obj func);
    Function_Call(SourceSpan pstate, String_Obj n, Arguments_Obj args);

    sass::string name() const;
    bool is_css();

    bool operator==(const Expression& rhs) const override;

    size_t hash() const override;

    ATTACH_AST_OPERATIONS(Function_Call)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////
  // Variable references.
  ///////////////////////
  class Variable final : public PreValue {
    ADD_CONSTREF(sass::string, name)
  public:
    Variable(SourceSpan pstate, sass::string n);
    virtual bool operator==(const Expression& rhs) const override;
    virtual size_t hash() const override;
    ATTACH_AST_OPERATIONS(Variable)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////
  // Numbers, percentages, dimensions, and colors.
  ////////////////////////////////////////////////
  class Number final : public Value, public Units {
    HASH_PROPERTY(double, value)
    ADD_PROPERTY(bool, zero)
    mutable size_t hash_;
  public:
    Number(SourceSpan pstate, double val, sass::string u = "", bool zero = true);

    bool zero() { return zero_; }

    sass::string type() const override { return "number"; }
    static sass::string type_name() { return "number"; }

    // cancel out unnecessary units
    // result will be in input units
    void reduce();

    // normalize units to defaults
    // needed to compare two numbers
    void normalize();

    size_t hash() const override;

    bool operator< (const Number& rhs) const;
    bool operator== (const Number& rhs) const;
    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;
    ATTACH_AST_OPERATIONS(Number)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////
  // Colors.
  //////////
  class Color : public Value {
    ADD_CONSTREF(sass::string, disp)
    HASH_PROPERTY(double, a)
  protected:
    mutable size_t hash_;
  public:
    Color(SourceSpan pstate, double a = 1, const sass::string disp = "");

    sass::string type() const override { return "color"; }
    static sass::string type_name() { return "color"; }

    virtual size_t hash() const override = 0;

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    virtual Color_RGBA* copyAsRGBA() const = 0;
    virtual Color_RGBA* toRGBA() = 0;

    virtual Color_HSLA* copyAsHSLA() const = 0;
    virtual Color_HSLA* toHSLA() = 0;

    ATTACH_VIRTUAL_AST_OPERATIONS(Color)
  };

  //////////
  // Colors.
  //////////
  class Color_RGBA final : public Color {
    HASH_PROPERTY(double, r)
    HASH_PROPERTY(double, g)
    HASH_PROPERTY(double, b)
  public:
    Color_RGBA(SourceSpan pstate, double r, double g, double b, double a = 1, const sass::string disp = "");

    sass::string type() const override { return "color"; }
    static sass::string type_name() { return "color"; }

    size_t hash() const override;

    Color_RGBA* copyAsRGBA() const override;
    Color_RGBA* toRGBA() override { return this; }

    Color_HSLA* copyAsHSLA() const override;
    Color_HSLA* toHSLA() override { return copyAsHSLA(); }

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Color_RGBA)
    ATTACH_CRTP_PERFORM_METHODS()
  };


  //////////
  // Colors.
  //////////
  class Color_HSLA final : public Color {
    HASH_PROPERTY(double, h)
    HASH_PROPERTY(double, s)
    HASH_PROPERTY(double, l)
  public:
    Color_HSLA(SourceSpan pstate, double h, double s, double l, double a = 1, const sass::string disp = "");

    sass::string type() const override { return "color"; }
    static sass::string type_name() { return "color"; }

    size_t hash() const override;

    Color_RGBA* copyAsRGBA() const override;
    Color_RGBA* toRGBA() override { return copyAsRGBA(); }

    Color_HSLA* copyAsHSLA() const override;
    Color_HSLA* toHSLA() override { return this; }

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Color_HSLA)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////
  // Errors from Sass_Values.
  //////////////////////////////
  class Custom_Error final : public Value {
    ADD_CONSTREF(sass::string, message)
  public:
    Custom_Error(SourceSpan pstate, sass::string msg);
    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;
    ATTACH_AST_OPERATIONS(Custom_Error)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////
  // Warnings from Sass_Values.
  //////////////////////////////
  class Custom_Warning final : public Value {
    ADD_CONSTREF(sass::string, message)
  public:
    Custom_Warning(SourceSpan pstate, sass::string msg);
    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;
    ATTACH_AST_OPERATIONS(Custom_Warning)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////
  // Booleans.
  ////////////
  class Boolean final : public Value {
    HASH_PROPERTY(bool, value)
    mutable size_t hash_;
  public:
    Boolean(SourceSpan pstate, bool val);
    operator bool() override { return value_; }

    sass::string type() const override { return "bool"; }
    static sass::string type_name() { return "bool"; }

    size_t hash() const override;

    bool is_false() override { return !value_; }

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Boolean)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////
  // Abstract base class for Sass string values. Includes interpolated and
  // "flat" strings.
  ////////////////////////////////////////////////////////////////////////
  class String : public Value {
  public:
    String(SourceSpan pstate, bool delayed = false);
    static sass::string type_name() { return "string"; }
    virtual ~String() = 0;
    virtual void rtrim() = 0;
    virtual bool operator<(const Expression& rhs) const override {
      return this->to_string() < rhs.to_string();
    };
    virtual bool operator==(const Expression& rhs) const override {
      return this->to_string() == rhs.to_string();
    };
    ATTACH_VIRTUAL_AST_OPERATIONS(String);
    ATTACH_CRTP_PERFORM_METHODS()
  };
  inline String::~String() { };

  ///////////////////////////////////////////////////////////////////////
  // Interpolated strings. Meant to be reduced to flat strings during the
  // evaluation phase.
  ///////////////////////////////////////////////////////////////////////
  class String_Schema final : public String, public Vectorized<PreValueObj> {
    ADD_PROPERTY(bool, css)
    mutable size_t hash_;
  public:
    String_Schema(SourceSpan pstate, size_t size = 0, bool css = true);

    sass::string type() const override { return "string"; }
    static sass::string type_name() { return "string"; }

    bool is_left_interpolant(void) const override;
    bool is_right_interpolant(void) const override;

    bool has_interpolants();
    void rtrim() override;
    size_t hash() const override;
    virtual void set_delayed(bool delayed) override;

    bool operator< (const Expression& rhs) const override;
    bool operator==(const Expression& rhs) const override;
    ATTACH_AST_OPERATIONS(String_Schema)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////
  // Flat strings -- the lowest level of raw textual data.
  ////////////////////////////////////////////////////////
  class String_Constant : public String {
    ADD_PROPERTY(char, quote_mark)
    HASH_CONSTREF(sass::string, value)
  protected:
    mutable size_t hash_;
  public:
    String_Constant(SourceSpan pstate, sass::string val, bool css = true);
    String_Constant(SourceSpan pstate, const char* beg, bool css = true);
    String_Constant(SourceSpan pstate, const char* beg, const char* end, bool css = true);
    String_Constant(SourceSpan pstate, const Token& tok, bool css = true);
    sass::string type() const override { return "string"; }
    static sass::string type_name() { return "string"; }
    bool is_invisible() const override;
    virtual void rtrim() override;
    size_t hash() const override;
    bool operator< (const Expression& rhs) const override;
    bool operator==(const Expression& rhs) const override;
    // quotes are forced on inspection
    virtual sass::string inspect() const override;
    ATTACH_AST_OPERATIONS(String_Constant)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////
  // Possibly quoted string (unquote on instantiation)
  ////////////////////////////////////////////////////////
  class String_Quoted final : public String_Constant {
  public:
    String_Quoted(SourceSpan pstate, sass::string val, char q = 0,
      bool keep_utf8_escapes = false, bool skip_unquoting = false,
      bool strict_unquoting = true, bool css = true);
    bool operator< (const Expression& rhs) const override;
    bool operator==(const Expression& rhs) const override;
    // quotes are forced on inspection
    sass::string inspect() const override;
    ATTACH_AST_OPERATIONS(String_Quoted)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////
  // The null value.
  //////////////////
  class Null final : public Value {
  public:
    Null(SourceSpan pstate);
    sass::string type() const override { return "null"; }
    static sass::string type_name() { return "null"; }
    bool is_invisible() const override { return true; }
    operator bool() override { return false; }
    bool is_false() override { return true; }

    size_t hash() const override;

    bool operator< (const Expression& rhs) const override;
    bool operator== (const Expression& rhs) const override;

    ATTACH_AST_OPERATIONS(Null)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////////
  // The Parent Reference Expression.
  //////////////////////////////////
  class Parent_Reference final : public Value {
  public:
    Parent_Reference(SourceSpan pstate);
    sass::string type() const override { return "parent"; }
    static sass::string type_name() { return "parent"; }
    bool operator< (const Expression& rhs) const override {
      return false; // they are always equal
    }
    bool operator==(const Expression& rhs) const override {
      return true; // they are always equal
    };
    ATTACH_AST_OPERATIONS(Parent_Reference)
    ATTACH_CRTP_PERFORM_METHODS()
  };

}

#endif
