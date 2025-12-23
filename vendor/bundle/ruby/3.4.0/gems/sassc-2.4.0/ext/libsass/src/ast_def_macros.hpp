#ifndef SASS_AST_DEF_MACROS_H
#define SASS_AST_DEF_MACROS_H

// Helper class to switch a flag and revert once we go out of scope
template <class T>
class LocalOption {
  private:
    T* var; // pointer to original variable
    T orig; // copy of the original option
  public:
    LocalOption(T& var)
    {
      this->var = &var;
      this->orig = var;
    }
    LocalOption(T& var, T orig)
    {
      this->var = &var;
      this->orig = var;
      *(this->var) = orig;
    }
    void reset()
    {
      *(this->var) = this->orig;
    }
    ~LocalOption() {
      *(this->var) = this->orig;
    }
};

#define LOCAL_FLAG(name,opt) LocalOption<bool> flag_##name(name, opt)
#define LOCAL_COUNT(name,opt) LocalOption<size_t> cnt_##name(name, opt)

#define NESTING_GUARD(name) \
  LocalOption<size_t> cnt_##name(name, name + 1); \
  if (name > MAX_NESTING) throw Exception::NestingLimitError(pstate, traces); \

#define ADD_PROPERTY(type, name)\
protected:\
  type name##_;\
public:\
  type name() const        { return name##_; }\
  type name(type name##__) { return name##_ = name##__; }\
private:

#define HASH_PROPERTY(type, name)\
protected:\
  type name##_;\
public:\
  type name() const        { return name##_; }\
  type name(type name##__) { hash_ = 0; return name##_ = name##__; }\
private:

#define ADD_CONSTREF(type, name) \
protected: \
  type name##_; \
public: \
  const type& name() const { return name##_; } \
  void name(type name##__) { name##_ = name##__; } \
private:

#define HASH_CONSTREF(type, name) \
protected: \
  type name##_; \
public: \
  const type& name() const { return name##_; } \
  void name(type name##__) { hash_ = 0; name##_ = name##__; } \
private:

#ifdef DEBUG_SHARED_PTR

#define ATTACH_ABSTRACT_AST_OPERATIONS(klass) \
  virtual klass* copy(sass::string, size_t) const = 0; \
  virtual klass* clone(sass::string, size_t) const = 0; \

#define ATTACH_VIRTUAL_AST_OPERATIONS(klass) \
  klass(const klass* ptr); \
  virtual klass* copy(sass::string, size_t) const override = 0; \
  virtual klass* clone(sass::string, size_t) const override = 0; \

#define ATTACH_AST_OPERATIONS(klass) \
  klass(const klass* ptr); \
  virtual klass* copy(sass::string, size_t) const override; \
  virtual klass* clone(sass::string, size_t) const override; \

#else

#define ATTACH_ABSTRACT_AST_OPERATIONS(klass) \
  virtual klass* copy() const = 0; \
  virtual klass* clone() const = 0; \

#define ATTACH_VIRTUAL_AST_OPERATIONS(klass) \
  klass(const klass* ptr); \
  virtual klass* copy() const override = 0; \
  virtual klass* clone() const override = 0; \

#define ATTACH_AST_OPERATIONS(klass) \
  klass(const klass* ptr); \
  virtual klass* copy() const override; \
  virtual klass* clone() const override; \

#endif

#define ATTACH_VIRTUAL_CMP_OPERATIONS(klass) \
  virtual bool operator==(const klass& rhs) const = 0; \
  virtual bool operator!=(const klass& rhs) const { return !(*this == rhs); }; \

#define ATTACH_CMP_OPERATIONS(klass) \
  virtual bool operator==(const klass& rhs) const; \
  virtual bool operator!=(const klass& rhs) const { return !(*this == rhs); }; \

#ifdef DEBUG_SHARED_PTR

  #define IMPLEMENT_AST_OPERATORS(klass) \
    klass* klass::copy(sass::string file, size_t line) const { \
      klass* cpy = SASS_MEMORY_NEW(klass, this); \
      cpy->trace(file, line); \
      return cpy; \
    } \
    klass* klass::clone(sass::string file, size_t line) const { \
      klass* cpy = copy(file, line); \
      cpy->cloneChildren(); \
      return cpy; \
    } \

#else

  #define IMPLEMENT_AST_OPERATORS(klass) \
    klass* klass::copy() const { \
      return SASS_MEMORY_NEW(klass, this); \
    } \
    klass* klass::clone() const { \
      klass* cpy = copy(); \
      cpy->cloneChildren(); \
      return cpy; \
    } \

#endif

#endif
