# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for cases where exceptions unrelated to the numeric constructors `Integer()`,
      # `Float()`, `BigDecimal()`, `Complex()`, and `Rational()` may be unintentionally swallowed.
      #
      # @safety
      #   The cop is unsafe for autocorrection because unexpected errors occurring in the argument
      #   passed to numeric constructor (e.g., `Integer()`) can lead to incompatible behavior.
      #   For example, changing it to `Integer(potential_exception_method_call, exception: false)`
      #   ensures that exceptions raised by `potential_exception_method_call` are not ignored.
      #
      #   [source,ruby]
      #   ----
      #   Integer(potential_exception_method_call) rescue nil
      #   ----
      #
      # @example
      #
      #   # bad
      #   Integer(arg) rescue nil
      #
      #   # bad
      #   begin
      #     Integer(arg)
      #   rescue
      #     nil
      #   end
      #
      #   # bad
      #   begin
      #     Integer(arg)
      #   rescue
      #   end
      #
      #   # good
      #   Integer(arg, exception: false)
      #
      class SuppressedExceptionInNumberConversion < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use `%<prefer>s` instead.'
        EXPECTED_EXCEPTION_CLASSES = %w[ArgumentError TypeError ::ArgumentError ::TypeError].freeze

        # @!method numeric_constructor_rescue_nil(node)
        def_node_matcher :numeric_constructor_rescue_nil, <<~PATTERN
          (rescue
            $#numeric_method?
            (resbody nil? nil? (nil)) nil?)
        PATTERN

        # @!method begin_numeric_constructor_rescue_nil(node)
        def_node_matcher :begin_numeric_constructor_rescue_nil, <<~PATTERN
          (kwbegin
            (rescue
              $#numeric_method?
              (resbody $_? nil?
                {(nil) nil?}) nil?))
        PATTERN

        # @!method numeric_method?(node)
        def_node_matcher :numeric_method?, <<~PATTERN
          {
            (call #constructor_receiver? {:Integer :BigDecimal :Complex :Rational}
              _ _?)
            (call #constructor_receiver? :Float
              _)
          }
        PATTERN

        # @!method constructor_receiver?(node)
        def_node_matcher :constructor_receiver?, <<~PATTERN
          {nil? (const {nil? cbase} :Kernel)}
        PATTERN

        minimum_target_ruby_version 2.6

        # rubocop:disable Metrics/AbcSize
        def on_rescue(node)
          if (method, exception_classes = begin_numeric_constructor_rescue_nil(node.parent))
            return unless expected_exception_classes_only?(exception_classes)

            node = node.parent
          else
            return unless (method = numeric_constructor_rescue_nil(node))
          end

          arguments = method.arguments.map(&:source) << 'exception: false'
          prefer = "#{method.method_name}(#{arguments.join(', ')})"
          prefer = "#{method.receiver.source}#{method.loc.dot.source}#{prefer}" if method.receiver

          add_offense(node, message: format(MSG, prefer: prefer)) do |corrector|
            corrector.replace(node, prefer)
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def expected_exception_classes_only?(exception_classes)
          return true unless (arguments = exception_classes.first)

          (arguments.values.map(&:source) - EXPECTED_EXCEPTION_CLASSES).none?
        end
      end
    end
  end
end
