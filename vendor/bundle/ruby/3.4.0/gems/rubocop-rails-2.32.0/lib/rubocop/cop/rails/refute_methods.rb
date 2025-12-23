# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Use `assert_not` methods instead of `refute` methods.
      #
      # @example EnforcedStyle: assert_not (default)
      #   # bad
      #   refute false
      #   refute_empty [1, 2, 3]
      #   refute_equal true, false
      #
      #   # good
      #   assert_not false
      #   assert_not_empty [1, 2, 3]
      #   assert_not_equal true, false
      #
      # @example EnforcedStyle: refute
      #   # bad
      #   assert_not false
      #   assert_not_empty [1, 2, 3]
      #   assert_not_equal true, false
      #
      #   # good
      #   refute false
      #   refute_empty [1, 2, 3]
      #   refute_equal true, false
      #
      class RefuteMethods < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Prefer `%<good_method>s` over `%<bad_method>s`.'

        CORRECTIONS = {
          refute:             :assert_not,
          refute_empty:       :assert_not_empty,
          refute_equal:       :assert_not_equal,
          refute_in_delta:    :assert_not_in_delta,
          refute_in_epsilon:  :assert_not_in_epsilon,
          refute_includes:    :assert_not_includes,
          refute_instance_of: :assert_not_instance_of,
          refute_kind_of:     :assert_not_kind_of,
          refute_nil:         :assert_not_nil,
          refute_operator:    :assert_not_operator,
          refute_predicate:   :assert_not_predicate,
          refute_respond_to:  :assert_not_respond_to,
          refute_same:        :assert_not_same,
          refute_match:       :assert_no_match
        }.freeze

        REFUTE_METHODS = CORRECTIONS.keys.freeze
        ASSERT_NOT_METHODS = CORRECTIONS.values.freeze

        RESTRICT_ON_SEND = REFUTE_METHODS + ASSERT_NOT_METHODS

        def_node_matcher :offensive?, '(send nil? #bad_method? ...)'

        def on_send(node)
          return unless offensive?(node)

          method_name = node.method_name
          message = offense_message(method_name)
          range = node.loc.selector

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, convert_good_method(method_name))
          end
        end

        private

        def bad_method?(method_name)
          if style == :assert_not
            REFUTE_METHODS.include?(method_name)
          else
            ASSERT_NOT_METHODS.include?(method_name)
          end
        end

        def offense_message(method_name)
          format(MSG, bad_method: method_name, good_method: convert_good_method(method_name))
        end

        def convert_good_method(bad_method)
          if style == :assert_not
            CORRECTIONS.fetch(bad_method)
          else
            CORRECTIONS.invert.fetch(bad_method)
          end
        end
      end
    end
  end
end
