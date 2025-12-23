# A namespace for the `@supports` condition parse tree.
module Sass::Supports
  # The abstract superclass of all Supports conditions.
  class Condition
    # Runs the SassScript in the supports condition.
    #
    # @param environment [Sass::Environment] The environment in which to run the script.
    def perform(environment); Sass::Util.abstract(self); end

    # Returns the CSS for this condition.
    #
    # @return [String]
    def to_css; Sass::Util.abstract(self); end

    # Returns the Sass/CSS code for this condition.
    #
    # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize}).
    # @return [String]
    def to_src(options); Sass::Util.abstract(self); end

    # Returns a deep copy of this condition and all its children.
    #
    # @return [Condition]
    def deep_copy; Sass::Util.abstract(self); end

    # Sets the options hash for the script nodes in the supports condition.
    #
    # @param options [{Symbol => Object}] The options has to set.
    def options=(options); Sass::Util.abstract(self); end
  end

  # An operator condition (e.g. `CONDITION1 and CONDITION2`).
  class Operator < Condition
    # The left-hand condition.
    #
    # @return [Sass::Supports::Condition]
    attr_accessor :left

    # The right-hand condition.
    #
    # @return [Sass::Supports::Condition]
    attr_accessor :right

    # The operator ("and" or "or").
    #
    # @return [String]
    attr_accessor :op

    def initialize(left, right, op)
      @left = left
      @right = right
      @op = op
    end

    def perform(env)
      @left.perform(env)
      @right.perform(env)
    end

    def to_css
      "#{parens @left, @left.to_css} #{op} #{parens @right, @right.to_css}"
    end

    def to_src(options)
      "#{parens @left, @left.to_src(options)} #{op} #{parens @right, @right.to_src(options)}"
    end

    def deep_copy
      copy = dup
      copy.left = @left.deep_copy
      copy.right = @right.deep_copy
      copy
    end

    def options=(options)
      @left.options = options
      @right.options = options
    end

    private

    def parens(condition, str)
      if condition.is_a?(Negation) || (condition.is_a?(Operator) && condition.op != op)
        return "(#{str})"
      else
        return str
      end
    end
  end

  # A negation condition (`not CONDITION`).
  class Negation < Condition
    # The condition being negated.
    #
    # @return [Sass::Supports::Condition]
    attr_accessor :condition

    def initialize(condition)
      @condition = condition
    end

    def perform(env)
      @condition.perform(env)
    end

    def to_css
      "not #{parens @condition.to_css}"
    end

    def to_src(options)
      "not #{parens @condition.to_src(options)}"
    end

    def deep_copy
      copy = dup
      copy.condition = condition.deep_copy
      copy
    end

    def options=(options)
      condition.options = options
    end

    private

    def parens(str)
      return "(#{str})" if @condition.is_a?(Negation) || @condition.is_a?(Operator)
      str
    end
  end

  # A declaration condition (e.g. `(feature: value)`).
  class Declaration < Condition
    # @return [Sass::Script::Tree::Node] The feature name.
    attr_accessor :name

    # @!attribute resolved_name
    #   The name of the feature after any SassScript has been resolved.
    #   Only set once \{Tree::Visitors::Perform} has been run.
    #
    #   @return [String]
    attr_accessor :resolved_name

    # The feature value.
    #
    # @return [Sass::Script::Tree::Node]
    attr_accessor :value

    # The value of the feature after any SassScript has been resolved.
    # Only set once \{Tree::Visitors::Perform} has been run.
    #
    # @return [String]
    attr_accessor :resolved_value

    def initialize(name, value)
      @name = name
      @value = value
    end

    def perform(env)
      @resolved_name = name.perform(env)
      @resolved_value = value.perform(env)
    end

    def to_css
      "(#{@resolved_name}: #{@resolved_value})"
    end

    def to_src(options)
      "(#{@name.to_sass(options)}: #{@value.to_sass(options)})"
    end

    def deep_copy
      copy = dup
      copy.name = @name.deep_copy
      copy.value = @value.deep_copy
      copy
    end

    def options=(options)
      @name.options = options
      @value.options = options
    end
  end

  # An interpolation condition (e.g. `#{$var}`).
  class Interpolation < Condition
    # The SassScript expression in the interpolation.
    #
    # @return [Sass::Script::Tree::Node]
    attr_accessor :value

    # The value of the expression after it's been resolved.
    # Only set once \{Tree::Visitors::Perform} has been run.
    #
    # @return [String]
    attr_accessor :resolved_value

    def initialize(value)
      @value = value
    end

    def perform(env)
      @resolved_value = value.perform(env).to_s(:quote => :none)
    end

    def to_css
      @resolved_value
    end

    def to_src(options)
      @value.to_sass(options)
    end

    def deep_copy
      copy = dup
      copy.value = @value.deep_copy
      copy
    end

    def options=(options)
      @value.options = options
    end
  end
end
