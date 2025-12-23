# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the use of a method, the result of which
      # would be a literal, like an empty array, hash, or string.
      #
      # NOTE: When frozen string literals are enabled, `String.new`
      # isn't corrected to an empty string since the former is
      # mutable and the latter would be frozen.
      #
      # @example
      #   # bad
      #   a = Array.new
      #   a = Array[]
      #   h = Hash.new
      #   h = Hash[]
      #   s = String.new
      #
      #   # good
      #   a = []
      #   h = {}
      #   s = ''
      class EmptyLiteral < Base
        include FrozenStringLiteral
        include RangeHelp
        include StringLiteralsHelp
        extend AutoCorrector

        ARR_MSG = 'Use array literal `[]` instead of `%<current>s`.'
        HASH_MSG = 'Use hash literal `{}` instead of `%<current>s`.'
        STR_MSG = 'Use string literal `%<prefer>s` instead of `String.new`.'

        RESTRICT_ON_SEND = %i[new [] Array Hash].freeze

        # @!method array_node(node)
        def_node_matcher :array_node, '(send (const {nil? cbase} :Array) :new (array)?)'

        # @!method hash_node(node)
        def_node_matcher :hash_node, '(send (const {nil? cbase} :Hash) :new)'

        # @!method str_node(node)
        def_node_matcher :str_node, '(send (const {nil? cbase} :String) :new)'

        # @!method array_with_block(node)
        def_node_matcher :array_with_block, '(block (send (const {nil? cbase} :Array) :new) args _)'

        # @!method hash_with_block(node)
        def_node_matcher :hash_with_block, <<~PATTERN
          {
            (block (send (const {nil? cbase} :Hash) :new) args _)
            (numblock (send (const {nil? cbase} :Hash) :new) ...)
          }
        PATTERN

        # @!method array_with_index(node)
        def_node_matcher :array_with_index, <<~PATTERN
          {
            (send (const {nil? cbase} :Array) :[])
            (send nil? :Array (array))
          }
        PATTERN

        # @!method hash_with_index(node)
        def_node_matcher :hash_with_index, <<~PATTERN
          {
            (send (const {nil? cbase} :Hash) :[])
            (send nil? :Hash (array))
          }
        PATTERN

        def on_send(node)
          return unless (message = offense_message(node))

          add_offense(node, message: message) do |corrector|
            corrector.replace(replacement_range(node), correction(node))
          end
        end

        private

        def offense_message(node)
          if offense_array_node?(node)
            format(ARR_MSG, current: node.source)
          elsif offense_hash_node?(node)
            format(HASH_MSG, current: node.source)
          elsif str_node(node) && !frozen_strings?
            format(STR_MSG, prefer: preferred_string_literal)
          end
        end

        def first_argument_unparenthesized?(node)
          parent = node.parent
          return false unless parent && %i[send super zsuper].include?(parent.type)

          node.equal?(parent.first_argument) && !parentheses?(node.parent)
        end

        def replacement_range(node)
          if hash_node(node) && first_argument_unparenthesized?(node)
            # `some_method {}` is not same as `some_method Hash.new`
            # because the braces are interpreted as a block. We will have
            # to rewrite the arguments to wrap them in parenthesis.
            args = node.parent.arguments

            range_between(args[0].source_range.begin_pos - 1, args[-1].source_range.end_pos)
          else
            node.source_range
          end
        end

        def offense_array_node?(node)
          (array_node(node) && !array_with_block(node.parent)) || array_with_index(node)
        end

        def offense_hash_node?(node)
          # If Hash.new takes a block, it can't be changed to {}.
          (hash_node(node) && !hash_with_block(node.parent)) || hash_with_index(node)
        end

        def correction(node)
          if offense_array_node?(node)
            '[]'
          elsif str_node(node)
            preferred_string_literal
          elsif offense_hash_node?(node)
            if first_argument_unparenthesized?(node)
              # `some_method {}` is not same as `some_method Hash.new`
              # because the braces are interpreted as a block. We will have
              # to rewrite the arguments to wrap them in parenthesis.
              args = node.parent.arguments
              "(#{args[1..].map(&:source).unshift('{}').join(', ')})"
            else
              '{}'
            end
          end
        end

        def frozen_strings?
          return true if frozen_string_literals_enabled?

          frozen_string_cop_enabled = config.cop_enabled?('Style/FrozenStringLiteralComment')
          frozen_string_cop_enabled &&
            !frozen_string_literals_disabled? &&
            string_literals_frozen_by_default?.nil?
        end
      end
    end
  end
end
