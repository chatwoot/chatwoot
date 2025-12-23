# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks if collection can be blank-compacted with `compact_blank`.
      #
      # @safety
      #   It is unsafe by default because false positives may occur in the
      #   blank check of block arguments to the receiver object.
      #
      #   For example, `[[1, 2], [3, nil]].reject { |first, second| second.blank? }` and
      #   `[[1, 2], [3, nil]].compact_blank` are not compatible. The same is true for `blank?`.
      #   This will work fine when the receiver is a hash object.
      #
      #   And `compact_blank!` has different implementations for `Array`, `Hash`, and
      #   `ActionController::Parameters`.
      #   `Array#compact_blank!`, `Hash#compact_blank!` are equivalent to `delete_if(&:blank?)`.
      #   If the cop makes a mistake, autocorrected code may get unexpected behavior.
      #
      # @example
      #
      #   # bad
      #   collection.reject(&:blank?)
      #   collection.reject { |_k, v| v.blank? }
      #   collection.select(&:present?)
      #   collection.select { |_k, v| v.present? }
      #   collection.filter(&:present?)
      #   collection.filter { |_k, v| v.present? }
      #
      #   # good
      #   collection.compact_blank
      #
      #   # bad
      #   collection.delete_if(&:blank?)            # Same behavior as `Array#compact_blank!` and `Hash#compact_blank!`
      #   collection.delete_if { |_k, v| v.blank? } # Same behavior as `Array#compact_blank!` and `Hash#compact_blank!`
      #   collection.keep_if(&:present?)            # Same behavior as `Array#compact_blank!` and `Hash#compact_blank!`
      #   collection.keep_if { |_k, v| v.present? } # Same behavior as `Array#compact_blank!` and `Hash#compact_blank!`
      #
      #   # good
      #   collection.compact_blank!
      #
      class CompactBlank < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `%<preferred_method>s` instead.'
        RESTRICT_ON_SEND = %i[reject delete_if select filter keep_if].freeze
        DESTRUCTIVE_METHODS = %i[delete_if keep_if].freeze

        minimum_target_rails_version 6.1

        def_node_matcher :reject_with_block?, <<~PATTERN
          (block
            (send _ {:reject :delete_if})
            $(args ...)
            (send
              $(lvar _) :blank?))
        PATTERN

        def_node_matcher :reject_with_block_pass?, <<~PATTERN
          (send _ {:reject :delete_if}
            (block_pass
              (sym :blank?)))
        PATTERN

        def_node_matcher :select_with_block?, <<~PATTERN
          (block
            (send _ {:select :filter :keep_if})
            $(args ...)
            (send
              $(lvar _) :present?))
        PATTERN

        def_node_matcher :select_with_block_pass?, <<~PATTERN
          (send _ {:select :filter :keep_if}
            (block-pass
              (sym :present?)))
        PATTERN

        def on_send(node)
          return if target_ruby_version < 2.6 && node.method?(:filter)
          return unless bad_method?(node)

          range = offense_range(node)
          preferred_method = preferred_method(node)
          add_offense(range, message: format(MSG, preferred_method: preferred_method)) do |corrector|
            corrector.replace(range, preferred_method)
          end
        end

        private

        def bad_method?(node)
          return true if reject_with_block_pass?(node)
          return true if select_with_block_pass?(node)

          arguments, receiver_in_block = reject_with_block?(node.parent) || select_with_block?(node.parent)
          if arguments
            return use_single_value_block_argument?(arguments, receiver_in_block) ||
                   use_hash_value_block_argument?(arguments, receiver_in_block)
          end

          false
        end

        def use_single_value_block_argument?(arguments, receiver_in_block)
          arguments.length == 1 && arguments[0].source == receiver_in_block.source
        end

        def use_hash_value_block_argument?(arguments, receiver_in_block)
          arguments.length == 2 && arguments[1].source == receiver_in_block.source
        end

        def offense_range(node)
          end_pos = if node.parent&.block_type? && node.parent&.send_node == node
                      node.parent.source_range.end_pos
                    else
                      node.source_range.end_pos
                    end

          range_between(node.loc.selector.begin_pos, end_pos)
        end

        def preferred_method(node)
          DESTRUCTIVE_METHODS.include?(node.method_name) ? 'compact_blank!' : 'compact_blank'
        end
      end
    end
  end
end
