# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks whether the block parameters of a single-line
      # method accepting a block match the names specified via configuration.
      #
      # For instance one can configure `reduce`(`inject`) to use |a, e| as
      # parameters.
      #
      # Configuration option: Methods
      # Should be set to use this cop. `Array` of hashes, where each key is the
      # method name and value - array of argument names.
      #
      # @example Methods: [{reduce: %w[a b]}]
      #   # bad
      #   foo.reduce { |c, d| c + d }
      #   foo.reduce { |_, _d| 1 }
      #
      #   # good
      #   foo.reduce { |a, b| a + b }
      #   foo.reduce { |a, _b| a }
      #   foo.reduce { |a, (id, _)| a + id }
      #   foo.reduce { true }
      #
      #   # good
      #   foo.reduce do |c, d|
      #     c + d
      #   end
      class SingleLineBlockParams < Base
        extend AutoCorrector

        MSG = 'Name `%<method>s` block params `|%<params>s|`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless node.single_line?

          return unless eligible_method?(node)
          return unless eligible_arguments?(node)

          method_name = node.method_name
          return if args_match?(method_name, node.arguments)

          preferred_block_arguments = build_preferred_arguments_map(node, target_args(method_name))
          joined_block_arguments = preferred_block_arguments.values.join(', ')

          message = format(MSG, method: method_name, params: joined_block_arguments)

          add_offense(node.arguments, message: message) do |corrector|
            autocorrect(corrector, node, preferred_block_arguments, joined_block_arguments)
          end
        end

        private

        def build_preferred_arguments_map(node, preferred_arguments)
          preferred_arguments_map = {}
          node.arguments.each_with_index do |current_lvar, index|
            preferred_argument = preferred_arguments[index]
            current_argument = current_lvar.source
            preferred_argument = "_#{preferred_argument}" if current_argument.start_with?('_')
            preferred_arguments_map[current_argument] = preferred_argument
          end

          preferred_arguments_map
        end

        def autocorrect(corrector, node, preferred_block_arguments, joined_block_arguments)
          corrector.replace(node.arguments, "|#{joined_block_arguments}|")

          node.each_descendant(:lvar) do |lvar|
            if (preferred_lvar = preferred_block_arguments[lvar.source])
              corrector.replace(lvar, preferred_lvar)
            end
          end
        end

        def eligible_arguments?(node)
          node.arguments? && node.arguments.to_a.all?(&:arg_type?)
        end

        def eligible_method?(node)
          node.receiver && method_names.include?(node.method_name)
        end

        def methods
          cop_config['Methods']
        end

        def method_names
          methods.map { |method| method_name(method).to_sym }
        end

        def method_name(method)
          method.keys.first
        end

        def target_args(method_name)
          method_name = method_name.to_s
          method_hash = methods.find { |m| method_name(m) == method_name }
          method_hash[method_name]
        end

        def args_match?(method_name, args)
          actual_args = args.to_a.flat_map(&:to_a)

          # Prepending an underscore to mark an unused parameter is allowed, so
          # we remove any leading underscores before comparing.
          actual_args_no_underscores = actual_args.map { |arg| arg.to_s.sub(/^_+/, '') }

          # Allow the arguments if the names match but not all are given
          expected_args = target_args(method_name).first(actual_args_no_underscores.size)
          actual_args_no_underscores == expected_args
        end
      end
    end
  end
end
