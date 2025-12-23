# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks if the map method is used in a chain.
      #
      # Autocorrection is not supported because an appropriate block variable name cannot be determined automatically.
      #
      # @safety
      #   This cop is unsafe because false positives occur if the number of times the first method is executed
      #   affects the return value of subsequent methods.
      #
      # [source,ruby]
      # ----
      # class X
      #   def initialize
      #     @@num = 0
      #   end
      #
      #   def foo
      #     @@num += 1
      #     self
      #   end
      #
      #   def bar
      #     @@num * 2
      #   end
      # end
      #
      # [X.new, X.new].map(&:foo).map(&:bar) # => [4, 4]
      # [X.new, X.new].map { |x| x.foo.bar } # => [2, 4]
      # ----
      #
      # @example
      #
      #   # bad
      #   array.map(&:foo).map(&:bar)
      #
      #   # good
      #   array.map { |item| item.foo.bar }
      #
      class MapMethodChain < Base
        include IgnoredNode

        MSG = 'Use `%<method_name>s { |x| x.%<map_args>s }` instead of `%<method_name>s` method chain.'
        RESTRICT_ON_SEND = %i[map collect].freeze

        def_node_matcher :block_pass_with_symbol_arg?, <<~PATTERN
          (:block_pass (:sym $_))
        PATTERN

        def on_send(node)
          return if part_of_ignored_node?(node)
          return unless (map_arg = block_pass_with_symbol_arg?(node.first_argument))

          map_args = [map_arg]

          return unless (begin_of_chained_map_method = find_begin_of_chained_map_method(node, map_args))

          range = begin_of_chained_map_method.loc.selector.begin.join(node.source_range.end)
          message = format(MSG, method_name: begin_of_chained_map_method.method_name, map_args: map_args.join('.'))

          add_offense(range, message: message)

          ignore_node(node)
        end

        private

        # rubocop:disable Metrics/CyclomaticComplexity
        def find_begin_of_chained_map_method(node, map_args)
          return unless (chained_map_method = node.receiver)
          return if !chained_map_method.call_type? || !RESTRICT_ON_SEND.include?(chained_map_method.method_name)
          return unless (map_arg = block_pass_with_symbol_arg?(chained_map_method.first_argument))

          map_args.unshift(map_arg)

          receiver = chained_map_method.receiver

          return chained_map_method unless receiver&.call_type? && block_pass_with_symbol_arg?(receiver.first_argument)

          find_begin_of_chained_map_method(chained_map_method, map_args)
        end
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
