# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of precise comparison of floating point numbers.
      #
      # Floating point values are inherently inaccurate, and comparing them for exact equality
      # is almost never the desired semantics. Comparison via the `==/!=` operators checks
      # floating-point value representation to be exactly the same, which is very unlikely
      # if you perform any arithmetic operations involving precision loss.
      #
      # @example
      #   # bad
      #   x == 0.1
      #   x != 0.1
      #
      #   # good - using BigDecimal
      #   x.to_d == 0.1.to_d
      #
      #   # good - comparing against zero
      #   x == 0.0
      #   x != 0.0
      #
      #   # good
      #   (x - 0.1).abs < Float::EPSILON
      #
      #   # good
      #   tolerance = 0.0001
      #   (x - 0.1).abs < tolerance
      #
      #   # good - comparing against nil
      #   Float(x, exception: false) == nil
      #
      #   # Or some other epsilon based type of comparison:
      #   # https://www.embeddeduse.com/2019/08/26/qt-compare-two-floats/
      #
      class FloatComparison < Base
        MSG_EQUALITY = 'Avoid equality comparisons of floats as they are unreliable.'
        MSG_INEQUALITY = 'Avoid inequality comparisons of floats as they are unreliable.'

        EQUALITY_METHODS = %i[== != eql? equal?].freeze
        FLOAT_RETURNING_METHODS = %i[to_f Float fdiv].freeze
        FLOAT_INSTANCE_METHODS = %i[@- abs magnitude modulo next_float prev_float quo].to_set.freeze

        RESTRICT_ON_SEND = EQUALITY_METHODS

        def on_send(node)
          return unless node.arguments.one?

          lhs = node.receiver
          rhs = node.first_argument

          return if literal_safe?(lhs) || literal_safe?(rhs)

          message = node.method?(:!=) ? MSG_INEQUALITY : MSG_EQUALITY
          add_offense(node, message: message) if float?(lhs) || float?(rhs)
        end
        alias on_csend on_send

        private

        def float?(node)
          return false unless node

          case node.type
          when :float
            true
          when :send
            check_send(node)
          when :begin
            float?(node.children.first)
          else
            false
          end
        end

        def literal_safe?(node)
          return false unless node

          (node.numeric_type? && node.value.zero?) || node.nil_type?
        end

        def check_send(node)
          if node.arithmetic_operation?
            float?(node.receiver) || float?(node.first_argument)
          elsif FLOAT_RETURNING_METHODS.include?(node.method_name)
            true
          elsif node.receiver&.float_type?
            FLOAT_INSTANCE_METHODS.include?(node.method_name) ||
              check_numeric_returning_method(node)
          end
        end

        def check_numeric_returning_method(node)
          return false unless node.receiver

          case node.method_name
          when :angle, :arg, :phase
            Float(node.receiver.source).negative?
          when :ceil, :floor, :round, :truncate
            precision = node.first_argument
            precision&.int_type? && Integer(precision.source).positive?
          end
        end
      end
    end
  end
end
