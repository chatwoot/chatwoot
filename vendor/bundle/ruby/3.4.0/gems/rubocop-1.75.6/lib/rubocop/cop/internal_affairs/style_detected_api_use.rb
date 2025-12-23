# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for correct use of the style_detected API provided by
      # `ConfigurableEnforcedStyle`. If `correct_style_detected` is used
      # then `opposite_style_detected`, `unexpected_style_detected`,
      # `ambiguous_style_detected`, `conflicting_styles_detected`,
      # `unrecognized_style_detected` or `no_acceptable_style!` should be
      # used too, and vice versa.  The `xxx_style_detected` methods
      # should not be used as predicates either.
      #
      # @example
      #
      #   # bad
      #   def on_send(node)
      #     return add_offense(node) if opposite_style_detected
      #
      #     correct_style_detected
      #   end
      #
      #   def on_send(node)
      #     if offense?
      #       add_offense(node)
      #     else
      #       correct_style_detected
      #     end
      #   end
      #
      #   def on_send(node)
      #     return unless offense?
      #
      #     add_offense(node)
      #     opposite_style_detected
      #   end
      #
      #   # good
      #   def on_send(node)
      #     if offense?
      #       add_offense(node)
      #       opposite_style_detected
      #     else
      #       correct_style_detected
      #     end
      #   end
      #
      #   def on_send(node)
      #     add_offense(node) if offense?
      #   end
      #
      class StyleDetectedApiUse < Base
        MSG_FOR_POSITIVE_WITHOUT_NEGATIVE =
          '`correct_style_detected` method called without ' \
          'calling a negative `*_style_detected` method.'
        MSG_FOR_NEGATIVE_WITHOUT_POSITIVE =
          'negative `*_style_detected` methods called without ' \
          'calling `correct_style_detected` method.'
        MSG_FOR_CONDITIONAL_USE = '`*_style_detected` method called in conditional.'
        RESTRICT_ON_SEND = %i[
          correct_style_detected opposite_style_detected
          unexpected_style_detected ambiguous_style_detected
          conflicting_styles_detected unrecognized_style_detected
          no_acceptable_style! style_detected
        ].freeze

        # @!method correct_style_detected_check(node)
        def_node_matcher :correct_style_detected_check, <<~PATTERN
          (send nil? :correct_style_detected)
        PATTERN

        # @!method negative_style_detected_method_check(node)
        def_node_matcher :negative_style_detected_method_check, <<~PATTERN
          (send nil? /(?:opposite|unexpected|ambiguous|unrecognized)_style_detected|conflicting_styles_detected/ ...)
        PATTERN

        # @!method no_acceptable_style_check(node)
        def_node_matcher :no_acceptable_style_check, <<~PATTERN
          (send nil? :no_acceptable_style!)
        PATTERN

        # @!method style_detected_check(node)
        def_node_matcher :style_detected_check, <<~PATTERN
          (send nil? :style_detected ...)
        PATTERN

        def on_new_investigation
          @correct_style_detected_called = false
          @negative_style_detected_methods_called = false
          @style_detected_called = false
        end

        def on_investigation_end
          return if style_detected_called
          return unless correct_style_detected_called ^ negative_style_detected_methods_called

          add_global_offense(MSG_FOR_POSITIVE_WITHOUT_NEGATIVE) if positive_without_negative?
          add_global_offense(MSG_FOR_NEGATIVE_WITHOUT_POSITIVE) if negative_without_positive?
        end

        def on_send(node)
          if correct_style_detected_check(node)
            @correct_style_detected_called = true
          elsif negative_style_detected_method_check(node) || no_acceptable_style_check(node)
            @negative_style_detected_methods_called = true
          elsif style_detected_check(node)
            @style_detected_called = true
          end
        end

        def on_if(node)
          traverse_condition(node.condition) do |cond|
            add_offense(cond, message: MSG_FOR_CONDITIONAL_USE) if style_detected_api_used?(cond)
          end
        end

        private

        attr_reader :correct_style_detected_called,
                    :negative_style_detected_methods_called,
                    :style_detected_called

        def positive_without_negative?
          correct_style_detected_called && !negative_style_detected_methods_called
        end

        def negative_without_positive?
          negative_style_detected_methods_called && !correct_style_detected_called
        end

        def style_detected_api_used?(node)
          correct_style_detected_check(node) ||
            negative_style_detected_method_check(node) ||
            no_acceptable_style_check(node) ||
            style_detected_check(node)
        end

        def traverse_condition(condition, &block)
          yield condition if condition.send_type?

          condition.each_child_node { |child| traverse_condition(child, &block) }
        end
      end
    end
  end
end
