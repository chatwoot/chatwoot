# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies usages of `any?`, `empty?` or `none?` predicate methods
      # chained to `select`/`filter`/`find_all` and change them to use predicate method instead.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `array.select.any?` evaluates all elements
      #   through the `select` method, while `array.any?` uses short-circuit evaluation.
      #   In other words, `array.select.any?` guarantees the evaluation of every element,
      #   but `array.any?` does not necessarily evaluate all of them.
      #
      # @example
      #   # bad
      #   arr.select { |x| x > 1 }.any?
      #
      #   # good
      #   arr.any? { |x| x > 1 }
      #
      #   # bad
      #   arr.select { |x| x > 1 }.empty?
      #   arr.select { |x| x > 1 }.none?
      #
      #   # good
      #   arr.none? { |x| x > 1 }
      #
      #   # good
      #   relation.select(:name).any?
      #   arr.select { |x| x > 1 }.any?(&:odd?)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #   # good
      #   arr.select { |x| x > 1 }.many?
      #
      #   # good
      #   arr.select { |x| x > 1 }.present?
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #   # bad
      #   arr.select { |x| x > 1 }.many?
      #
      #   # good
      #   arr.many? { |x| x > 1 }
      #
      #   # bad
      #   arr.select { |x| x > 1 }.present?
      #
      #   # good
      #   arr.any? { |x| x > 1 }
      #
      class RedundantFilterChain < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<first_method>s.%<second_method>s`.'

        RAILS_METHODS = %i[many? present?].freeze
        RESTRICT_ON_SEND = (%i[any? empty? none? one?] + RAILS_METHODS).freeze

        # @!method select_predicate?(node)
        def_node_matcher :select_predicate?, <<~PATTERN
          (call
            {
              (block $(call _ {:select :filter :find_all}) ...)
              $(call _ {:select :filter :find_all} block_pass_type?)
            }
            ${:#{RESTRICT_ON_SEND.join(' :')}})
        PATTERN

        REPLACEMENT_METHODS = {
          any?: :any?,
          empty?: :none?,
          none?: :none?,
          one?: :one?,
          many?: :many?,
          present?: :any?
        }.freeze
        private_constant :REPLACEMENT_METHODS

        def on_send(node)
          return if node.arguments? || node.block_literal?

          select_predicate?(node) do |select_node, filter_method|
            return if RAILS_METHODS.include?(filter_method) && !active_support_extensions_enabled?

            register_offense(select_node, node)
          end
        end
        alias on_csend on_send

        private

        def register_offense(select_node, predicate_node)
          replacement = REPLACEMENT_METHODS[predicate_node.method_name]
          message = format(MSG, prefer: replacement,
                                first_method: select_node.method_name,
                                second_method: predicate_node.method_name)

          offense_range = offense_range(select_node, predicate_node)

          add_offense(offense_range, message: message) do |corrector|
            corrector.remove(predicate_range(predicate_node))
            corrector.replace(select_node.loc.selector, replacement)
          end
        end

        def offense_range(select_node, predicate_node)
          select_node.loc.selector.join(predicate_node.loc.selector)
        end

        def predicate_range(predicate_node)
          predicate_node.receiver.source_range.end.join(predicate_node.loc.selector)
        end
      end
    end
  end
end
