module Sass::Script::Tree
  # A SassScript parse node representing a binary operation,
  # such as `$a + $b` or `"foo" + 1`.
  class Operation < Node
    @@color_arithmetic_deprecation = Sass::Deprecation.new
    @@unitless_equals_deprecation = Sass::Deprecation.new

    attr_reader :operand1
    attr_reader :operand2
    attr_reader :operator

    # @param operand1 [Sass::Script::Tree::Node] The parse-tree node
    #   for the right-hand side of the operator
    # @param operand2 [Sass::Script::Tree::Node] The parse-tree node
    #   for the left-hand side of the operator
    # @param operator [Symbol] The operator to perform.
    #   This should be one of the binary operator names in {Sass::Script::Lexer::OPERATORS}
    def initialize(operand1, operand2, operator)
      @operand1 = operand1
      @operand2 = operand2
      @operator = operator
      super()
    end

    # @return [String] A human-readable s-expression representation of the operation
    def inspect
      "(#{@operator.inspect} #{@operand1.inspect} #{@operand2.inspect})"
    end

    # @see Node#to_sass
    def to_sass(opts = {})
      o1 = operand_to_sass @operand1, :left, opts
      o2 = operand_to_sass @operand2, :right, opts
      sep =
        case @operator
        when :comma; ", "
        when :space; " "
        else; " #{Sass::Script::Lexer::OPERATORS_REVERSE[@operator]} "
        end
      "#{o1}#{sep}#{o2}"
    end

    # Returns the operands for this operation.
    #
    # @return [Array<Node>]
    # @see Node#children
    def children
      [@operand1, @operand2]
    end

    # @see Node#deep_copy
    def deep_copy
      node = dup
      node.instance_variable_set('@operand1', @operand1.deep_copy)
      node.instance_variable_set('@operand2', @operand2.deep_copy)
      node
    end

    protected

    # Evaluates the operation.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value] The SassScript object that is the value of the operation
    # @raise [Sass::SyntaxError] if the operation is undefined for the operands
    def _perform(environment)
      value1 = @operand1.perform(environment)

      # Special-case :and and :or to support short-circuiting.
      if @operator == :and
        return value1.to_bool ? @operand2.perform(environment) : value1
      elsif @operator == :or
        return value1.to_bool ? value1 : @operand2.perform(environment)
      end

      value2 = @operand2.perform(environment)

      if (value1.is_a?(Sass::Script::Value::Null) || value2.is_a?(Sass::Script::Value::Null)) &&
          @operator != :eq && @operator != :neq
        raise Sass::SyntaxError.new(
          "Invalid null operation: \"#{value1.inspect} #{@operator} #{value2.inspect}\".")
      end

      begin
        result = opts(value1.send(@operator, value2))
      rescue NoMethodError => e
        raise e unless e.name.to_s == @operator.to_s
        raise Sass::SyntaxError.new("Undefined operation: \"#{value1} #{@operator} #{value2}\".")
      end

      warn_for_color_arithmetic(value1, value2)
      warn_for_unitless_equals(value1, value2, result)

      result
    end

    private

    def warn_for_color_arithmetic(value1, value2)
      return unless @operator == :plus || @operator == :times || @operator == :minus ||
                    @operator == :div || @operator == :mod

      if value1.is_a?(Sass::Script::Value::Number)
        return unless value2.is_a?(Sass::Script::Value::Color)
      elsif value1.is_a?(Sass::Script::Value::Color)
        return unless value2.is_a?(Sass::Script::Value::Color) || value2.is_a?(Sass::Script::Value::Number)
      else
        return
      end

      @@color_arithmetic_deprecation.warn(filename, line, <<WARNING)
The operation `#{value1} #{@operator} #{value2}` is deprecated and will be an error in future versions.
Consider using Sass's color functions instead.
https://sass-lang.com/documentation/Sass/Script/Functions.html#other_color_functions
WARNING
    end

    def warn_for_unitless_equals(value1, value2, result)
      return unless @operator == :eq || @operator == :neq
      return unless value1.is_a?(Sass::Script::Value::Number)
      return unless value2.is_a?(Sass::Script::Value::Number)
      return unless value1.unitless? != value2.unitless?
      return unless result == (if @operator == :eq
                                 Sass::Script::Value::Bool::TRUE
                               else
                                 Sass::Script::Value::Bool::FALSE
                               end)

      operation = "#{value1.to_sass} #{@operator == :eq ? '==' : '!='} #{value2.to_sass}"
      future_value = @operator == :neq
      @@unitless_equals_deprecation.warn(filename, line, <<WARNING)
The result of `#{operation}` will be `#{future_value}` in future releases of Sass.
Unitless numbers will no longer be equal to the same numbers with units.
WARNING
    end

    def operand_to_sass(op, side, opts)
      return "(#{op.to_sass(opts)})" if op.is_a?(Sass::Script::Tree::ListLiteral)
      return op.to_sass(opts) unless op.is_a?(Operation)

      pred = Sass::Script::Parser.precedence_of(@operator)
      sub_pred = Sass::Script::Parser.precedence_of(op.operator)
      assoc = Sass::Script::Parser.associative?(@operator)
      return "(#{op.to_sass(opts)})" if sub_pred < pred ||
        (side == :right && sub_pred == pred && !assoc)
      op.to_sass(opts)
    end
  end
end
