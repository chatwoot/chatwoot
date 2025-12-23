#ifndef SASS_AST_H
#define SASS_AST_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <typeinfo>
#include <unordered_map>

#include "sass/base.h"
#include "ast_helpers.hpp"
#include "ast_fwd_decl.hpp"
#include "ast_def_macros.hpp"

#include "file.hpp"
#include "position.hpp"
#include "operation.hpp"
#include "environment.hpp"
#include "fn_utils.hpp"

namespace Sass {

  // ToDo: where does this fit best?
  // We don't share this with C-API?
  class Operand {
    public:
      Operand(Sass_OP operand, bool ws_before = false, bool ws_after = false)
      : operand(operand), ws_before(ws_before), ws_after(ws_after)
      { }
    public:
      enum Sass_OP operand;
      bool ws_before;
      bool ws_after;
  };

  //////////////////////////////////////////////////////////
  // `hash_combine` comes from boost (functional/hash):
  // http://www.boost.org/doc/libs/1_35_0/doc/html/hash/combine.html
  // Boost Software License - Version 1.0
  // http://www.boost.org/users/license.html
  template <typename T>
  void hash_combine (std::size_t& seed, const T& val)
  {
    seed ^= std::hash<T>()(val) + 0x9e3779b9
             + (seed<<6) + (seed>>2);
  }
  //////////////////////////////////////////////////////////

  const char* sass_op_to_name(enum Sass_OP op);

  const char* sass_op_separator(enum Sass_OP op);

  //////////////////////////////////////////////////////////
  // Abstract base class for all abstract syntax tree nodes.
  //////////////////////////////////////////////////////////
  class AST_Node : public SharedObj {
    ADD_PROPERTY(SourceSpan, pstate)
  public:
    AST_Node(SourceSpan pstate)
    : pstate_(pstate)
    { }
    AST_Node(const AST_Node* ptr)
    : pstate_(ptr->pstate_)
    { }

    // allow implicit conversion to string
    // needed for by SharedPtr implementation
    operator sass::string() {
      return to_string();
    }

    // AST_Node(AST_Node& ptr) = delete;

    virtual ~AST_Node() = 0;
    virtual size_t hash() const { return 0; }
    virtual sass::string inspect() const { return to_string({ INSPECT, 5 }); }
    virtual sass::string to_sass() const { return to_string({ TO_SASS, 5 }); }
    virtual sass::string to_string(Sass_Inspect_Options opt) const;
    virtual sass::string to_css(Sass_Inspect_Options opt) const;
    virtual sass::string to_string() const;
    virtual void cloneChildren() {};
    // generic find function (not fully implemented yet)
    // ToDo: add specific implementations to all children
    virtual bool find ( bool (*f)(AST_Node_Obj) ) { return f(this); };
    void update_pstate(const SourceSpan& pstate);

    // Some objects are not meant to be compared
    // ToDo: maybe fall-back to pointer comparison?
    virtual bool operator== (const AST_Node& rhs) const {
      throw std::runtime_error("operator== not implemented");
    }

    // We can give some reasonable implementations by using
    // invert operators on the specialized implementations
    virtual bool operator!= (const AST_Node& rhs) const {
      // Unequal if not equal
      return !(*this == rhs);
    }

    ATTACH_ABSTRACT_AST_OPERATIONS(AST_Node);
    ATTACH_ABSTRACT_CRTP_PERFORM_METHODS()
  };
  inline AST_Node::~AST_Node() { }

  //////////////////////////////////////////////////////////////////////
  // define cast template now (need complete type)
  //////////////////////////////////////////////////////////////////////

  template<class T>
  T* Cast(AST_Node* ptr) {
    return ptr && typeid(T) == typeid(*ptr) ?
           static_cast<T*>(ptr) : NULL;
  };

  template<class T>
  const T* Cast(const AST_Node* ptr) {
    return ptr && typeid(T) == typeid(*ptr) ?
           static_cast<const T*>(ptr) : NULL;
  };

  //////////////////////////////////////////////////////////////////////
  // Abstract base class for expressions. This side of the AST hierarchy
  // represents elements in value contexts, which exist primarily to be
  // evaluated and returned.
  //////////////////////////////////////////////////////////////////////
  class Expression : public AST_Node {
  public:
    enum Type {
      NONE,
      BOOLEAN,
      NUMBER,
      COLOR,
      STRING,
      LIST,
      MAP,
      SELECTOR,
      NULL_VAL,
      FUNCTION_VAL,
      C_WARNING,
      C_ERROR,
      FUNCTION,
      VARIABLE,
      PARENT,
      NUM_TYPES
    };
  private:
    // expressions in some contexts shouldn't be evaluated
    ADD_PROPERTY(bool, is_delayed)
    ADD_PROPERTY(bool, is_expanded)
    ADD_PROPERTY(bool, is_interpolant)
    ADD_PROPERTY(Type, concrete_type)
  public:
    Expression(SourceSpan pstate, bool d = false, bool e = false, bool i = false, Type ct = NONE);
    virtual operator bool() { return true; }
    virtual ~Expression() { }
    virtual bool is_invisible() const { return false; }

    virtual sass::string type() const { return ""; }
    static sass::string type_name() { return ""; }

    virtual bool is_false() { return false; }
    // virtual bool is_true() { return !is_false(); }
    virtual bool operator< (const Expression& rhs) const { return false; }
    virtual bool operator== (const Expression& rhs) const { return false; }
    inline bool operator>(const Expression& rhs) const { return rhs < *this; }
    inline bool operator!=(const Expression& rhs) const { return !(rhs == *this); }
    virtual bool eq(const Expression& rhs) const { return *this == rhs; };
    virtual void set_delayed(bool delayed) { is_delayed(delayed); }
    virtual bool has_interpolant() const { return is_interpolant(); }
    virtual bool is_left_interpolant() const { return is_interpolant(); }
    virtual bool is_right_interpolant() const { return is_interpolant(); }
    ATTACH_VIRTUAL_AST_OPERATIONS(Expression);
    size_t hash() const override { return 0; }
  };

}

/////////////////////////////////////////////////////////////////////////////////////
// Hash method specializations for std::unordered_map to work with Sass::Expression
/////////////////////////////////////////////////////////////////////////////////////

namespace std {
  template<>
  struct hash<Sass::ExpressionObj>
  {
    size_t operator()(Sass::ExpressionObj s) const
    {
      return s->hash();
    }
  };
  template<>
  struct equal_to<Sass::ExpressionObj>
  {
    bool operator()( Sass::ExpressionObj lhs,  Sass::ExpressionObj rhs) const
    {
      return lhs->hash() == rhs->hash();
    }
  };
}

namespace Sass {

  /////////////////////////////////////////////////////////////////////////////
  // Mixin class for AST nodes that should behave like vectors. Uses the
  // "Template Method" design pattern to allow subclasses to adjust their flags
  // when certain objects are pushed.
  /////////////////////////////////////////////////////////////////////////////
  template <typename T>
  class Vectorized {
    sass::vector<T> elements_;
  protected:
    mutable size_t hash_;
    void reset_hash() { hash_ = 0; }
    virtual void adjust_after_pushing(T element) { }
  public:
    Vectorized(size_t s = 0) : hash_(0)
    { elements_.reserve(s); }
    Vectorized(sass::vector<T> vec) :
      elements_(std::move(vec)),
      hash_(0)
    {}
    virtual ~Vectorized() = 0;
    size_t length() const   { return elements_.size(); }
    bool empty() const      { return elements_.empty(); }
    void clear()            { return elements_.clear(); }
    T& last()               { return elements_.back(); }
    T& first()              { return elements_.front(); }
    const T& last() const   { return elements_.back(); }
    const T& first() const  { return elements_.front(); }

    bool operator== (const Vectorized<T>& rhs) const {
      // Abort early if sizes do not match
      if (length() != rhs.length()) return false;
      // Otherwise test each node for object equalicy in order
      return std::equal(begin(), end(), rhs.begin(), ObjEqualityFn<T>);
    }

    bool operator!= (const Vectorized<T>& rhs) const {
      return !(*this == rhs);
    }

    T& operator[](size_t i) { return elements_[i]; }
    virtual const T& at(size_t i) const { return elements_.at(i); }
    virtual T& at(size_t i) { return elements_.at(i); }
    const T& get(size_t i) const { return elements_[i]; }
    const T& operator[](size_t i) const { return elements_[i]; }

    // Implicitly get the sass::vector from our object
    // Makes the Vector directly assignable to sass::vector
    // You are responsible to make a copy if needed
    // Note: since this returns the real object, we can't
    // Note: guarantee that the hash will not get out of sync
    operator sass::vector<T>&() { return elements_; }
    operator const sass::vector<T>&() const { return elements_; }

    // Explicitly request all elements as a real sass::vector
    // You are responsible to make a copy if needed
    // Note: since this returns the real object, we can't
    // Note: guarantee that the hash will not get out of sync
    sass::vector<T>& elements() { return elements_; }
    const sass::vector<T>& elements() const { return elements_; }

    // Insert all items from compatible vector
    void concat(const sass::vector<T>& v)
    {
      if (!v.empty()) reset_hash();
      elements().insert(end(), v.begin(), v.end());
    }

    // Syntatic sugar for pointers
    void concat(const Vectorized<T>* v)
    {
      if (v != nullptr) {
        return concat(*v);
      }
    }

    // Insert one item on the front
    void unshift(T element)
    {
      reset_hash();
      elements_.insert(begin(), element);
    }

    // Remove and return item on the front
    // ToDo: handle empty vectors
    T shift() {
      reset_hash();
      T first = get(0);
      elements_.erase(begin());
      return first;
    }

    // Insert one item on the back
    // ToDo: rename this to push
    void append(T element)
    {
      reset_hash();
      elements_.insert(end(), element);
      // ToDo: Mostly used by parameters and arguments
      // ToDo: Find a more elegant way to support this
      adjust_after_pushing(element);
    }

    // Check if an item already exists
    // Uses underlying object `operator==`
    // E.g. compares the actual objects
    bool contains(const T& el) const {
      for (const T& rhs : elements_) {
        // Test the underlying objects for equality
        // A std::find checks for pointer equality
        if (ObjEqualityFn(el, rhs)) {
          return true;
        }
      }
      return false;
    }

    // This might be better implemented as `operator=`?
    void elements(sass::vector<T> e) {
      reset_hash();
      elements_ = std::move(e);
    }

    virtual size_t hash() const
    {
      if (hash_ == 0) {
        for (const T& el : elements_) {
          hash_combine(hash_, el->hash());
        }
      }
      return hash_;
    }

    template <typename P, typename V>
    typename sass::vector<T>::iterator insert(P position, const V& val) {
      reset_hash();
      return elements_.insert(position, val);
    }

    typename sass::vector<T>::iterator end() { return elements_.end(); }
    typename sass::vector<T>::iterator begin() { return elements_.begin(); }
    typename sass::vector<T>::const_iterator end() const { return elements_.end(); }
    typename sass::vector<T>::const_iterator begin() const { return elements_.begin(); }
    typename sass::vector<T>::iterator erase(typename sass::vector<T>::iterator el) { reset_hash(); return elements_.erase(el); }
    typename sass::vector<T>::const_iterator erase(typename sass::vector<T>::const_iterator el) { reset_hash(); return elements_.erase(el); }

  };
  template <typename T>
  inline Vectorized<T>::~Vectorized() { }

  /////////////////////////////////////////////////////////////////////////////
  // Mixin class for AST nodes that should behave like a hash table. Uses an
  // extra <sass::vector> internally to maintain insertion order for interation.
  /////////////////////////////////////////////////////////////////////////////
  template <typename K, typename T, typename U>
  class Hashed {
  private:
    std::unordered_map<
      K, T, ObjHash, ObjEquality
    > elements_;

    sass::vector<K> _keys;
    sass::vector<T> _values;
  protected:
    mutable size_t hash_;
    K duplicate_key_;
    void reset_hash() { hash_ = 0; }
    void reset_duplicate_key() { duplicate_key_ = {}; }
    virtual void adjust_after_pushing(std::pair<K, T> p) { }
  public:
    Hashed(size_t s = 0)
    : elements_(),
      _keys(),
      _values(),
      hash_(0), duplicate_key_({})
    {
      _keys.reserve(s);
      _values.reserve(s);
      elements_.reserve(s);
    }
    virtual ~Hashed();
    size_t length() const                  { return _keys.size(); }
    bool empty() const                     { return _keys.empty(); }
    bool has(K k) const          {
      return elements_.find(k) != elements_.end();
    }
    T at(K k) const {
      if (elements_.count(k))
      {
        return elements_.at(k);
      }
      else { return {}; }
    }
    bool has_duplicate_key() const         { return duplicate_key_ != nullptr; }
    K get_duplicate_key() const  { return duplicate_key_; }
    const std::unordered_map<
      K, T, ObjHash, ObjEquality
    >& elements() { return elements_; }
    Hashed& operator<<(std::pair<K, T> p)
    {
      reset_hash();

      if (!has(p.first)) {
        _keys.push_back(p.first);
        _values.push_back(p.second);
      }
      else if (!duplicate_key_) {
        duplicate_key_ = p.first;
      }

      elements_[p.first] = p.second;

      adjust_after_pushing(p);
      return *this;
    }
    Hashed& operator+=(Hashed* h)
    {
      if (length() == 0) {
        this->elements_ = h->elements_;
        this->_values = h->_values;
        this->_keys = h->_keys;
        return *this;
      }

      for (auto key : h->keys()) {
        *this << std::make_pair(key, h->at(key));
      }

      reset_duplicate_key();
      return *this;
    }
    const std::unordered_map<
      K, T, ObjHash, ObjEquality
    >& pairs() const { return elements_; }

    const sass::vector<K>& keys() const { return _keys; }
    const sass::vector<T>& values() const { return _values; }

//    std::unordered_map<ExpressionObj, ExpressionObj>::iterator end() { return elements_.end(); }
//    std::unordered_map<ExpressionObj, ExpressionObj>::iterator begin() { return elements_.begin(); }
//    std::unordered_map<ExpressionObj, ExpressionObj>::const_iterator end() const { return elements_.end(); }
//    std::unordered_map<ExpressionObj, ExpressionObj>::const_iterator begin() const { return elements_.begin(); }

  };
  template <typename K, typename T, typename U>
  inline Hashed<K, T, U>::~Hashed() { }

  /////////////////////////////////////////////////////////////////////////
  // Abstract base class for statements. This side of the AST hierarchy
  // represents elements in expansion contexts, which exist primarily to be
  // rewritten and macro-expanded.
  /////////////////////////////////////////////////////////////////////////
  class Statement : public AST_Node {
  public:
    enum Type {
      NONE,
      RULESET,
      MEDIA,
      DIRECTIVE,
      SUPPORTS,
      ATROOT,
      BUBBLE,
      CONTENT,
      KEYFRAMERULE,
      DECLARATION,
      ASSIGNMENT,
      IMPORT_STUB,
      IMPORT,
      COMMENT,
      WARNING,
      RETURN,
      EXTEND,
      ERROR,
      DEBUGSTMT,
      WHILE,
      EACH,
      FOR,
      IF
    };
  private:
    ADD_PROPERTY(Type, statement_type)
    ADD_PROPERTY(size_t, tabs)
    ADD_PROPERTY(bool, group_end)
  public:
    Statement(SourceSpan pstate, Type st = NONE, size_t t = 0);
    virtual ~Statement() = 0; // virtual destructor
    // needed for rearranging nested rulesets during CSS emission
    virtual bool bubbles();
    virtual bool has_content();
    virtual bool is_invisible() const;
    ATTACH_VIRTUAL_AST_OPERATIONS(Statement)
  };
  inline Statement::~Statement() { }

  ////////////////////////
  // Blocks of statements.
  ////////////////////////
  class Block final : public Statement, public Vectorized<Statement_Obj> {
    ADD_PROPERTY(bool, is_root)
    // needed for properly formatted CSS emission
  protected:
    void adjust_after_pushing(Statement_Obj s) override {}
  public:
    Block(SourceSpan pstate, size_t s = 0, bool r = false);
    bool isInvisible() const;
    bool has_content() override;
    ATTACH_AST_OPERATIONS(Block)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////
  // Abstract base class for statements that contain blocks of statements.
  ////////////////////////////////////////////////////////////////////////
  class ParentStatement : public Statement {
    ADD_PROPERTY(Block_Obj, block)
  public:
    ParentStatement(SourceSpan pstate, Block_Obj b);
    ParentStatement(const ParentStatement* ptr); // copy constructor
    virtual ~ParentStatement() = 0; // virtual destructor
    virtual bool has_content() override;
  };
  inline ParentStatement::~ParentStatement() { }

  /////////////////////////////////////////////////////////////////////////////
  // Rulesets (i.e., sets of styles headed by a selector and containing a block
  // of style declarations.
  /////////////////////////////////////////////////////////////////////////////
  class StyleRule final : public ParentStatement {
    ADD_PROPERTY(SelectorListObj, selector)
    ADD_PROPERTY(Selector_Schema_Obj, schema)
    ADD_PROPERTY(bool, is_root);
  public:
    StyleRule(SourceSpan pstate, SelectorListObj s = {}, Block_Obj b = {});
    bool is_invisible() const override;
    ATTACH_AST_OPERATIONS(StyleRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////
  // Bubble.
  /////////////////
  class Bubble final : public Statement {
    ADD_PROPERTY(Statement_Obj, node)
    ADD_PROPERTY(bool, group_end)
  public:
    Bubble(SourceSpan pstate, Statement_Obj n, Statement_Obj g = {}, size_t t = 0);
    bool bubbles() override;
    ATTACH_AST_OPERATIONS(Bubble)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////
  // Trace.
  /////////////////
  class Trace final : public ParentStatement {
    ADD_CONSTREF(char, type)
    ADD_CONSTREF(sass::string, name)
  public:
    Trace(SourceSpan pstate, sass::string n, Block_Obj b = {}, char type = 'm');
    ATTACH_AST_OPERATIONS(Trace)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////////////////////////////////
  // At-rules -- arbitrary directives beginning with "@" that may have an
  // optional statement block.
  ///////////////////////////////////////////////////////////////////////
  class AtRule final : public ParentStatement {
    ADD_CONSTREF(sass::string, keyword)
    ADD_PROPERTY(SelectorListObj, selector)
    ADD_PROPERTY(ExpressionObj, value)
  public:
    AtRule(SourceSpan pstate, sass::string kwd, SelectorListObj sel = {}, Block_Obj b = {}, ExpressionObj val = {});
    bool bubbles() override;
    bool is_media();
    bool is_keyframes();
    ATTACH_AST_OPERATIONS(AtRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////////////////////////////////
  // Keyframe-rules -- the child blocks of "@keyframes" nodes.
  ///////////////////////////////////////////////////////////////////////
  class Keyframe_Rule final : public ParentStatement {
    // according to css spec, this should be <keyframes-name>
    // <keyframes-name> = <custom-ident> | <string>
    ADD_PROPERTY(SelectorListObj, name)
  public:
    Keyframe_Rule(SourceSpan pstate, Block_Obj b);
    ATTACH_AST_OPERATIONS(Keyframe_Rule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////
  // Declarations -- style rules consisting of a property name and values.
  ////////////////////////////////////////////////////////////////////////
  class Declaration final : public ParentStatement {
    ADD_PROPERTY(String_Obj, property)
    ADD_PROPERTY(ExpressionObj, value)
    ADD_PROPERTY(bool, is_important)
    ADD_PROPERTY(bool, is_custom_property)
    ADD_PROPERTY(bool, is_indented)
  public:
    Declaration(SourceSpan pstate, String_Obj prop, ExpressionObj val, bool i = false, bool c = false, Block_Obj b = {});
    bool is_invisible() const override;
    ATTACH_AST_OPERATIONS(Declaration)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////
  // Assignments -- variable and value.
  /////////////////////////////////////
  class Assignment final : public Statement {
    ADD_CONSTREF(sass::string, variable)
    ADD_PROPERTY(ExpressionObj, value)
    ADD_PROPERTY(bool, is_default)
    ADD_PROPERTY(bool, is_global)
  public:
    Assignment(SourceSpan pstate, sass::string var, ExpressionObj val, bool is_default = false, bool is_global = false);
    ATTACH_AST_OPERATIONS(Assignment)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////////
  // Import directives. CSS and Sass import lists can be intermingled, so it's
  // necessary to store a list of each in an Import node.
  ////////////////////////////////////////////////////////////////////////////
  class Import final : public Statement {
    sass::vector<ExpressionObj> urls_;
    sass::vector<Include>        incs_;
    ADD_PROPERTY(List_Obj,      import_queries);
  public:
    Import(SourceSpan pstate);
    sass::vector<Include>& incs();
    sass::vector<ExpressionObj>& urls();
    ATTACH_AST_OPERATIONS(Import)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  // not yet resolved single import
  // so far we only know requested name
  class Import_Stub final : public Statement {
    Include resource_;
  public:
    Import_Stub(SourceSpan pstate, Include res);
    Include resource();
    sass::string imp_path();
    sass::string abs_path();
    ATTACH_AST_OPERATIONS(Import_Stub)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////
  // The Sass `@warn` directive.
  //////////////////////////////
  class WarningRule final : public Statement {
    ADD_PROPERTY(ExpressionObj, message)
  public:
    WarningRule(SourceSpan pstate, ExpressionObj msg);
    ATTACH_AST_OPERATIONS(WarningRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////
  // The Sass `@error` directive.
  ///////////////////////////////
  class ErrorRule final : public Statement {
    ADD_PROPERTY(ExpressionObj, message)
  public:
    ErrorRule(SourceSpan pstate, ExpressionObj msg);
    ATTACH_AST_OPERATIONS(ErrorRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////
  // The Sass `@debug` directive.
  ///////////////////////////////
  class DebugRule final : public Statement {
    ADD_PROPERTY(ExpressionObj, value)
  public:
    DebugRule(SourceSpan pstate, ExpressionObj val);
    ATTACH_AST_OPERATIONS(DebugRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////
  // CSS comments. These may be interpolated.
  ///////////////////////////////////////////
  class Comment final : public Statement {
    ADD_PROPERTY(String_Obj, text)
    ADD_PROPERTY(bool, is_important)
  public:
    Comment(SourceSpan pstate, String_Obj txt, bool is_important);
    virtual bool is_invisible() const override;
    ATTACH_AST_OPERATIONS(Comment)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////
  // The Sass `@if` control directive.
  ////////////////////////////////////
  class If final : public ParentStatement {
    ADD_PROPERTY(ExpressionObj, predicate)
    ADD_PROPERTY(Block_Obj, alternative)
  public:
    If(SourceSpan pstate, ExpressionObj pred, Block_Obj con, Block_Obj alt = {});
    virtual bool has_content() override;
    ATTACH_AST_OPERATIONS(If)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////
  // The Sass `@for` control directive.
  /////////////////////////////////////
  class ForRule final : public ParentStatement {
    ADD_CONSTREF(sass::string, variable)
    ADD_PROPERTY(ExpressionObj, lower_bound)
    ADD_PROPERTY(ExpressionObj, upper_bound)
    ADD_PROPERTY(bool, is_inclusive)
  public:
    ForRule(SourceSpan pstate, sass::string var, ExpressionObj lo, ExpressionObj hi, Block_Obj b, bool inc);
    ATTACH_AST_OPERATIONS(ForRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////////////
  // The Sass `@each` control directive.
  //////////////////////////////////////
  class EachRule final : public ParentStatement {
    ADD_PROPERTY(sass::vector<sass::string>, variables)
    ADD_PROPERTY(ExpressionObj, list)
  public:
    EachRule(SourceSpan pstate, sass::vector<sass::string> vars, ExpressionObj lst, Block_Obj b);
    ATTACH_AST_OPERATIONS(EachRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////
  // The Sass `@while` control directive.
  ///////////////////////////////////////
  class WhileRule final : public ParentStatement {
    ADD_PROPERTY(ExpressionObj, predicate)
  public:
    WhileRule(SourceSpan pstate, ExpressionObj pred, Block_Obj b);
    ATTACH_AST_OPERATIONS(WhileRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////////////////
  // The @return directive for use inside SassScript functions.
  /////////////////////////////////////////////////////////////
  class Return final : public Statement {
    ADD_PROPERTY(ExpressionObj, value)
  public:
    Return(SourceSpan pstate, ExpressionObj val);
    ATTACH_AST_OPERATIONS(Return)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////////////////////////////////
  // Definitions for both mixins and functions. The two cases are distinguished
  // by a type tag.
  /////////////////////////////////////////////////////////////////////////////
  class Definition final : public ParentStatement {
  public:
    enum Type { MIXIN, FUNCTION };
    ADD_CONSTREF(sass::string, name)
    ADD_PROPERTY(Parameters_Obj, parameters)
    ADD_PROPERTY(Env*, environment)
    ADD_PROPERTY(Type, type)
    ADD_PROPERTY(Native_Function, native_function)
    ADD_PROPERTY(Sass_Function_Entry, c_function)
    ADD_PROPERTY(void*, cookie)
    ADD_PROPERTY(bool, is_overload_stub)
    ADD_PROPERTY(Signature, signature)
  public:
    Definition(SourceSpan pstate,
               sass::string n,
               Parameters_Obj params,
               Block_Obj b,
               Type t);
    Definition(SourceSpan pstate,
               Signature sig,
               sass::string n,
               Parameters_Obj params,
               Native_Function func_ptr,
               bool overload_stub = false);
    Definition(SourceSpan pstate,
               Signature sig,
               sass::string n,
               Parameters_Obj params,
               Sass_Function_Entry c_func);
    ATTACH_AST_OPERATIONS(Definition)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////////////
  // Mixin calls (i.e., `@include ...`).
  //////////////////////////////////////
  class Mixin_Call final : public ParentStatement {
    ADD_CONSTREF(sass::string, name)
    ADD_PROPERTY(Arguments_Obj, arguments)
    ADD_PROPERTY(Parameters_Obj, block_parameters)
  public:
    Mixin_Call(SourceSpan pstate, sass::string n, Arguments_Obj args, Parameters_Obj b_params = {}, Block_Obj b = {});
    ATTACH_AST_OPERATIONS(Mixin_Call)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////////////
  // The @content directive for mixin content blocks.
  ///////////////////////////////////////////////////
  class Content final : public Statement {
    ADD_PROPERTY(Arguments_Obj, arguments)
  public:
    Content(SourceSpan pstate, Arguments_Obj args);
    ATTACH_AST_OPERATIONS(Content)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////////
  // Arithmetic negation (logical negation is just an ordinary function call).
  ////////////////////////////////////////////////////////////////////////////
  class Unary_Expression final : public Expression {
  public:
    enum Type { PLUS, MINUS, NOT, SLASH };
  private:
    HASH_PROPERTY(Type, optype)
    HASH_PROPERTY(ExpressionObj, operand)
    mutable size_t hash_;
  public:
    Unary_Expression(SourceSpan pstate, Type t, ExpressionObj o);
    const sass::string type_name();
    virtual bool operator==(const Expression& rhs) const override;
    size_t hash() const override;
    ATTACH_AST_OPERATIONS(Unary_Expression)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////
  // Individual argument objects for mixin and function calls.
  ////////////////////////////////////////////////////////////
  class Argument final : public Expression {
    HASH_PROPERTY(ExpressionObj, value)
    HASH_CONSTREF(sass::string, name)
    ADD_PROPERTY(bool, is_rest_argument)
    ADD_PROPERTY(bool, is_keyword_argument)
    mutable size_t hash_;
  public:
    Argument(SourceSpan pstate, ExpressionObj val, sass::string n = "", bool rest = false, bool keyword = false);
    void set_delayed(bool delayed) override;
    bool operator==(const Expression& rhs) const override;
    size_t hash() const override;
    ATTACH_AST_OPERATIONS(Argument)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////////////////
  // Argument lists -- in their own class to facilitate context-sensitive
  // error checking (e.g., ensuring that all ordinal arguments precede all
  // named arguments).
  ////////////////////////////////////////////////////////////////////////
  class Arguments final : public Expression, public Vectorized<Argument_Obj> {
    ADD_PROPERTY(bool, has_named_arguments)
    ADD_PROPERTY(bool, has_rest_argument)
    ADD_PROPERTY(bool, has_keyword_argument)
  protected:
    void adjust_after_pushing(Argument_Obj a) override;
  public:
    Arguments(SourceSpan pstate);
    void set_delayed(bool delayed) override;
    Argument_Obj get_rest_argument();
    Argument_Obj get_keyword_argument();
    ATTACH_AST_OPERATIONS(Arguments)
    ATTACH_CRTP_PERFORM_METHODS()
  };


  // A Media StyleRule before it has been evaluated
  // Could be already final or an interpolation
  class MediaRule final : public ParentStatement {
    ADD_PROPERTY(List_Obj, schema)
  public:
    MediaRule(SourceSpan pstate, Block_Obj block = {});

    bool bubbles() override { return true; };
    bool is_invisible() const override { return false; };
    ATTACH_AST_OPERATIONS(MediaRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  // A Media StyleRule after it has been evaluated
  // Representing the static or resulting css
  class CssMediaRule final : public ParentStatement,
    public Vectorized<CssMediaQuery_Obj> {
  public:
    CssMediaRule(SourceSpan pstate, Block_Obj b);
    bool bubbles() override { return true; };
    bool isInvisible() const { return empty(); }
    bool is_invisible() const override { return false; };

  public:
    // Hash and equality implemtation from vector
    size_t hash() const override { return Vectorized::hash(); }
    // Check if two instances are considered equal
    bool operator== (const CssMediaRule& rhs) const {
      return Vectorized::operator== (rhs);
    }
    bool operator!=(const CssMediaRule& rhs) const {
      // Invert from equality
      return !(*this == rhs);
    }

    ATTACH_AST_OPERATIONS(CssMediaRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  // Media Queries after they have been evaluated
  // Representing the static or resulting css
  class CssMediaQuery final : public AST_Node {

    // The modifier, probably either "not" or "only".
    // This may be `null` if no modifier is in use.
    ADD_PROPERTY(sass::string, modifier);

    // The media type, for example "screen" or "print".
    // This may be `null`. If so, [features] will not be empty.
    ADD_PROPERTY(sass::string, type);

    // Feature queries, including parentheses.
    ADD_PROPERTY(sass::vector<sass::string>, features);

  public:
    CssMediaQuery(SourceSpan pstate);

    // Check if two instances are considered equal
    bool operator== (const CssMediaQuery& rhs) const;
    bool operator!=(const CssMediaQuery& rhs) const {
      // Invert from equality
      return !(*this == rhs);
    }

    // Returns true if this query is empty
    // Meaning it has no type and features
    bool empty() const {
      return type_.empty()
        && modifier_.empty()
        && features_.empty();
    }

    // Whether this media query matches all media types.
    bool matchesAllTypes() const {
      return type_.empty() || Util::equalsLiteral("all", type_);
    }

    // Merges this with [other] and adds a query that matches the intersection
    // of both inputs to [result]. Returns false if the result is unrepresentable
    CssMediaQuery_Obj merge(CssMediaQuery_Obj& other);

    ATTACH_AST_OPERATIONS(CssMediaQuery)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////
  // Media queries (replaced by MediaRule at al).
  // ToDo: only used for interpolation case
  ////////////////////////////////////////////////////
  class Media_Query final : public Expression,
                            public Vectorized<Media_Query_ExpressionObj> {
    ADD_PROPERTY(String_Obj, media_type)
    ADD_PROPERTY(bool, is_negated)
    ADD_PROPERTY(bool, is_restricted)
  public:
    Media_Query(SourceSpan pstate, String_Obj t = {}, size_t s = 0, bool n = false, bool r = false);
    ATTACH_AST_OPERATIONS(Media_Query)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////
  // Media expressions (for use inside media queries).
  // ToDo: only used for interpolation case
  ////////////////////////////////////////////////////
  class Media_Query_Expression final : public Expression {
    ADD_PROPERTY(ExpressionObj, feature)
    ADD_PROPERTY(ExpressionObj, value)
    ADD_PROPERTY(bool, is_interpolated)
  public:
    Media_Query_Expression(SourceSpan pstate, ExpressionObj f, ExpressionObj v, bool i = false);
    ATTACH_AST_OPERATIONS(Media_Query_Expression)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////
  // At root expressions (for use inside @at-root).
  /////////////////////////////////////////////////
  class At_Root_Query final : public Expression {
  private:
    ADD_PROPERTY(ExpressionObj, feature)
    ADD_PROPERTY(ExpressionObj, value)
  public:
    At_Root_Query(SourceSpan pstate, ExpressionObj f = {}, ExpressionObj v = {}, bool i = false);
    bool exclude(sass::string str);
    ATTACH_AST_OPERATIONS(At_Root_Query)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////
  // At-root.
  ///////////
  class AtRootRule final : public ParentStatement {
    ADD_PROPERTY(At_Root_Query_Obj, expression)
  public:
    AtRootRule(SourceSpan pstate, Block_Obj b = {}, At_Root_Query_Obj e = {});
    bool bubbles() override;
    bool exclude_node(Statement_Obj s);
    ATTACH_AST_OPERATIONS(AtRootRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////////////
  // Individual parameter objects for mixins and functions.
  /////////////////////////////////////////////////////////
  class Parameter final : public AST_Node {
    ADD_CONSTREF(sass::string, name)
    ADD_PROPERTY(ExpressionObj, default_value)
    ADD_PROPERTY(bool, is_rest_parameter)
  public:
    Parameter(SourceSpan pstate, sass::string n, ExpressionObj def = {}, bool rest = false);
    ATTACH_AST_OPERATIONS(Parameter)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////////////////////////////
  // Parameter lists -- in their own class to facilitate context-sensitive
  // error checking (e.g., ensuring that all optional parameters follow all
  // required parameters).
  /////////////////////////////////////////////////////////////////////////
  class Parameters final : public AST_Node, public Vectorized<Parameter_Obj> {
    ADD_PROPERTY(bool, has_optional_parameters)
    ADD_PROPERTY(bool, has_rest_parameter)
  protected:
    void adjust_after_pushing(Parameter_Obj p) override;
  public:
    Parameters(SourceSpan pstate);
    ATTACH_AST_OPERATIONS(Parameters)
    ATTACH_CRTP_PERFORM_METHODS()
  };

}

#include "ast_values.hpp"
#include "ast_supports.hpp"
#include "ast_selectors.hpp"

#ifdef __clang__

// #pragma clang diagnostic pop
// #pragma clang diagnostic push

#endif

#endif
