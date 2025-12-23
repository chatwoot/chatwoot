#ifndef SASS_ERROR_HANDLING_H
#define SASS_ERROR_HANDLING_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <string>
#include <sstream>
#include <stdexcept>
#include "units.hpp"
#include "position.hpp"
#include "backtrace.hpp"
#include "ast_fwd_decl.hpp"
#include "sass/functions.h"

namespace Sass {

  struct Backtrace;

  namespace Exception {

    const sass::string def_msg = "Invalid sass detected";
    const sass::string def_op_msg = "Undefined operation";
    const sass::string def_op_null_msg = "Invalid null operation";
    const sass::string def_nesting_limit = "Code too deeply nested";

    class Base : public std::runtime_error {
      protected:
        sass::string msg;
        sass::string prefix;
      public:
        SourceSpan pstate;
        Backtraces traces;
      public:
        Base(SourceSpan pstate, sass::string msg, Backtraces traces);
        virtual const char* errtype() const { return prefix.c_str(); }
        virtual const char* what() const throw() { return msg.c_str(); }
        virtual ~Base() throw() {};
    };

    class InvalidSass : public Base {
      public:
        InvalidSass(SourceSpan pstate, Backtraces traces, sass::string msg);
        virtual ~InvalidSass() throw() {};
    };

    class InvalidParent : public Base {
      protected:
        Selector* parent;
        Selector* selector;
      public:
        InvalidParent(Selector* parent, Backtraces traces, Selector* selector);
        virtual ~InvalidParent() throw() {};
    };

    class MissingArgument : public Base {
      protected:
        sass::string fn;
        sass::string arg;
        sass::string fntype;
      public:
        MissingArgument(SourceSpan pstate, Backtraces traces, sass::string fn, sass::string arg, sass::string fntype);
        virtual ~MissingArgument() throw() {};
    };

    class InvalidArgumentType : public Base {
      protected:
        sass::string fn;
        sass::string arg;
        sass::string type;
        const Value* value;
      public:
        InvalidArgumentType(SourceSpan pstate, Backtraces traces, sass::string fn, sass::string arg, sass::string type, const Value* value = 0);
        virtual ~InvalidArgumentType() throw() {};
    };

    class InvalidVarKwdType : public Base {
      protected:
        sass::string name;
        const Argument* arg;
      public:
        InvalidVarKwdType(SourceSpan pstate, Backtraces traces, sass::string name, const Argument* arg = 0);
        virtual ~InvalidVarKwdType() throw() {};
    };

    class InvalidSyntax : public Base {
      public:
        InvalidSyntax(SourceSpan pstate, Backtraces traces, sass::string msg);
        virtual ~InvalidSyntax() throw() {};
    };

    class NestingLimitError : public Base {
      public:
        NestingLimitError(SourceSpan pstate, Backtraces traces, sass::string msg = def_nesting_limit);
        virtual ~NestingLimitError() throw() {};
    };

    class DuplicateKeyError : public Base {
      protected:
        const Map& dup;
        const Expression& org;
      public:
        DuplicateKeyError(Backtraces traces, const Map& dup, const Expression& org);
        virtual const char* errtype() const { return "Error"; }
        virtual ~DuplicateKeyError() throw() {};
    };

    class TypeMismatch : public Base {
      protected:
        const Expression& var;
        const sass::string type;
      public:
        TypeMismatch(Backtraces traces, const Expression& var, const sass::string type);
        virtual const char* errtype() const { return "Error"; }
        virtual ~TypeMismatch() throw() {};
    };

    class InvalidValue : public Base {
      protected:
        const Expression& val;
      public:
        InvalidValue(Backtraces traces, const Expression& val);
        virtual const char* errtype() const { return "Error"; }
        virtual ~InvalidValue() throw() {};
    };

    class StackError : public Base {
      protected:
        const AST_Node& node;
      public:
        StackError(Backtraces traces, const AST_Node& node);
        virtual const char* errtype() const { return "SystemStackError"; }
        virtual ~StackError() throw() {};
    };

    /* common virtual base class (has no pstate or trace) */
    class OperationError : public std::runtime_error {
      protected:
        sass::string msg;
      public:
        OperationError(sass::string msg = def_op_msg)
        : std::runtime_error(msg.c_str()), msg(msg)
        {};
      public:
        virtual const char* errtype() const { return "Error"; }
        virtual const char* what() const throw() { return msg.c_str(); }
        virtual ~OperationError() throw() {};
    };

    class ZeroDivisionError : public OperationError {
      protected:
        const Expression& lhs;
        const Expression& rhs;
      public:
        ZeroDivisionError(const Expression& lhs, const Expression& rhs);
        virtual const char* errtype() const { return "ZeroDivisionError"; }
        virtual ~ZeroDivisionError() throw() {};
    };

    class IncompatibleUnits : public OperationError {
      protected:
        // const Sass::UnitType lhs;
        // const Sass::UnitType rhs;
      public:
        IncompatibleUnits(const Units& lhs, const Units& rhs);
        IncompatibleUnits(const UnitType lhs, const UnitType rhs);
        virtual ~IncompatibleUnits() throw() {};
    };

    class UndefinedOperation : public OperationError {
      protected:
        const Expression* lhs;
        const Expression* rhs;
        const Sass_OP op;
      public:
        UndefinedOperation(const Expression* lhs, const Expression* rhs, enum Sass_OP op);
        // virtual const char* errtype() const { return "Error"; }
        virtual ~UndefinedOperation() throw() {};
    };

    class InvalidNullOperation : public UndefinedOperation {
      public:
        InvalidNullOperation(const Expression* lhs, const Expression* rhs, enum Sass_OP op);
        virtual ~InvalidNullOperation() throw() {};
    };

    class AlphaChannelsNotEqual : public OperationError {
      protected:
        const Expression* lhs;
        const Expression* rhs;
        const Sass_OP op;
      public:
        AlphaChannelsNotEqual(const Expression* lhs, const Expression* rhs, enum Sass_OP op);
        // virtual const char* errtype() const { return "Error"; }
        virtual ~AlphaChannelsNotEqual() throw() {};
    };

    class SassValueError : public Base {
    public:
      SassValueError(Backtraces traces, SourceSpan pstate, OperationError& err);
      virtual ~SassValueError() throw() {};
    };

    class TopLevelParent : public Base {
    public:
      TopLevelParent(Backtraces traces, SourceSpan pstate);
      virtual ~TopLevelParent() throw() {};
    };

    class UnsatisfiedExtend : public Base {
    public:
      UnsatisfiedExtend(Backtraces traces, Extension extension);
      virtual ~UnsatisfiedExtend() throw() {};
    };

    class ExtendAcrossMedia : public Base {
    public:
      ExtendAcrossMedia(Backtraces traces, Extension extension);
      virtual ~ExtendAcrossMedia() throw() {};
    };

  }

  void warn(sass::string msg, SourceSpan pstate);
  void warn(sass::string msg, SourceSpan pstate, Backtrace* bt);
  void warning(sass::string msg, SourceSpan pstate);

  void deprecated_function(sass::string msg, SourceSpan pstate);
  void deprecated(sass::string msg, sass::string msg2, bool with_column, SourceSpan pstate);
  void deprecated_bind(sass::string msg, SourceSpan pstate);
  // void deprecated(sass::string msg, SourceSpan pstate, Backtrace* bt);

  void coreError(sass::string msg, SourceSpan pstate);
  void error(sass::string msg, SourceSpan pstate, Backtraces& traces);

}

#endif
