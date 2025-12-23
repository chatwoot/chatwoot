module Regexp::Expression
  module Shared

    # Test if this expression has the given test_type, which can be either
    # a symbol or an array of symbols to check against the expression's type.
    #
    #   # is it a :group expression
    #   exp.type? :group
    #
    #   # is it a :set, or :meta
    #   exp.type? [:set, :meta]
    #
    def type?(test_type)
      test_types = Array(test_type).map(&:to_sym)
      test_types.include?(:*) || test_types.include?(type)
    end

    # Test if this expression has the given test_token, and optionally a given
    # test_type.
    #
    #   # Any expressions
    #   exp.is? :*  # always returns true
    #
    #   # is it a :capture
    #   exp.is? :capture
    #
    #   # is it a :character and a :set
    #   exp.is? :character, :set
    #
    #   # is it a :meta :dot
    #   exp.is? :dot, :meta
    #
    #   # is it a :meta or :escape :dot
    #   exp.is? :dot, [:meta, :escape]
    #
    def is?(test_token, test_type = nil)
      return true if test_token === :*
      token == test_token and (test_type ? type?(test_type) : true)
    end

    # Test if this expression matches an entry in the given scope spec.
    #
    # A scope spec can be one of:
    #
    #   . An array: Interpreted as a set of tokens, tested for inclusion
    #               of the expression's token.
    #
    #   . A hash:   Where the key is interpreted as the expression type
    #               and the value is either a symbol or an array. In this
    #               case, when the scope is a hash, one_of? calls itself to
    #               evaluate the key's value.
    #
    #   . A symbol: matches the expression's token or type, depending on
    #               the level of the call. If one_of? is called directly with
    #               a symbol then it will always be checked against the
    #               type of the expression. If it's being called for a value
    #               from a hash, it will be checked against the token of the
    #               expression.
    #
    #   # any expression
    #   exp.one_of?(:*) # always true
    #
    #   # like exp.type?(:group)
    #   exp.one_of?(:group)
    #
    #   # any expression of type meta
    #   exp.one_of?(:meta => :*)
    #
    #   # meta dots and alternations
    #   exp.one_of?(:meta => [:dot, :alternation])
    #
    #   # meta dots and any set tokens
    #   exp.one_of?({meta: [:dot], set: :*})
    #
    def one_of?(scope, top = true)
      case scope
      when Array
        scope.include?(:*) || scope.include?(token)

      when Hash
        if scope.has_key?(:*)
          test_type = scope.has_key?(type) ? type : :*
          one_of?(scope[test_type], false)
        else
          scope.has_key?(type) && one_of?(scope[type], false)
        end

      when Symbol
        scope.equal?(:*) || (top ? type?(scope) : is?(scope))

      else
        raise ArgumentError,
              "Array, Hash, or Symbol expected, #{scope.class.name} given"
      end
    end

    # Deep-compare two expressions for equality.
    #
    # When changing the conditions, please make sure to update
    # #pretty_print_instance_variables so that it includes all relevant values.
    def ==(other)
      self.class   == other.class &&
        text       == other.text &&
        quantifier == other.quantifier &&
        options    == other.options &&
        (terminal? || expressions == other.expressions)
    end
    alias :=== :==
    alias :eql? :==

    def optional?
      quantified? && quantifier.min == 0
    end

    def quantified?
      !quantifier.nil?
    end
  end

  Shared.class_eval                     { def terminal?; self.class.terminal? end }
  Shared::ClassMethods.class_eval       { def terminal?; true  end }
  Subexpression.instance_eval           { def terminal?; false end }

  Shared.class_eval                     { def capturing?; self.class.capturing? end }
  Shared::ClassMethods.class_eval       { def capturing?; false end }
  Group::Capture.instance_eval          { def capturing?; true  end }

  Shared.class_eval                     { def comment?; self.class.comment? end }
  Shared::ClassMethods.class_eval       { def comment?; false end }
  Comment.instance_eval                 { def comment?; true  end }
  Group::Comment.instance_eval          { def comment?; true  end }

  Shared.class_eval                     { def decorative?; self.class.decorative? end }
  Shared::ClassMethods.class_eval       { def decorative?; false end }
  FreeSpace.instance_eval               { def decorative?; true  end }
  Group::Comment.instance_eval          { def decorative?; true  end }

  Shared.class_eval                     { def referential?; self.class.referential? end }
  Shared::ClassMethods.class_eval       { def referential?; false end }
  Backreference::Base.instance_eval     { def referential?; true  end }
  Conditional::Condition.instance_eval  { def referential?; true  end }
  Conditional::Expression.instance_eval { def referential?; true  end }
end
