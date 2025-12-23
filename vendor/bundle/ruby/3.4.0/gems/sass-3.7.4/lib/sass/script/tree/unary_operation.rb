module Sass::Script::Tree
  # A SassScript parse node representing a unary operation,
  # such as `-$b` or `not true`.
  #
  # Currently only `-`, `/`, and `not` are unary operators.
  class UnaryOperation < Node
    # @return [Symbol] The operation to perform
    attr_reader :operator

    # @return [Script::Node] The parse-tree node for the object of the operator
    attr_reader :operand

    # @param operand [Script::Node] See \{#operand}
    # @param operator [Symbol] See \{#operator}
    def initialize(operand, operator)
      @operand = operand
      @operator = operator
      super()
    end

    # @return [String] A human-readable s-expression representation of the operation
    def inspect
      "(#{@operator.inspect} #{@operand.inspect})"
    end

    # @see Node#to_sass
    def to_sass(opts = {})
      operand = @operand.to_sass(opts)
      if @operand.is_a?(Operation) ||
          (@operator == :minus &&
           (operand =~ Sass::SCSS::RX::IDENT) == 0)
        operand = "(#{@operand.to_sass(opts)})"
      end
      op = Sass::Script::Lexer::OPERATORS_REVERSE[@operator]
      op + (op =~ /[a-z]/ ? " " : "") + operand
    end

    # Returns the operand of the operation.
    #
    # @return [Array<Node>]
    # @see Node#children
    def children
      [@operand]
    end

    # @see Node#deep_copy
    def deep_copy
      node = dup
      node.instance_variable_set('@operand', @operand.deep_copy)
      node
    end

    protected

    # Evaluates the operation.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value] The SassScript object that is the value of the operation
    # @raise [Sass::SyntaxError] if the operation is undefined for the operand
    def _perform(environment)
      operator = "unary_#{@operator}"
      value = @operand.perform(environment)
      value.send(operator)
    rescue NoMethodError => e
      raise e unless e.name.to_s == operator.to_s
      raise Sass::SyntaxError.new("Undefined unary operation: \"#{@operator} #{value}\".")
    end
  end
end
