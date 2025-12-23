# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for blocks with one argument where `it` block parameter can be used.
      #
      # It provides three `EnforcedStyle` options:
      #
      # 1. `only_numbered_parameters` (default) ... Detects only numbered block parameters.
      # 2. `always` ... Always uses the `it` block parameter.
      # 3. `disallow` ... Disallows the `it` block parameter.
      #
      # A single numbered parameter is detected when `only_numbered_parameters` or `always`.
      #
      # @example EnforcedStyle: only_numbered_parameters (default)
      #   # bad
      #   block { do_something(_1) }
      #
      #   # good
      #   block { do_something(it) }
      #   block { |named_param| do_something(named_param) }
      #
      # @example EnforcedStyle: always
      #   # bad
      #   block { do_something(_1) }
      #   block { |named_param| do_something(named_param) }
      #
      #   # good
      #   block { do_something(it) }
      #
      # @example EnforcedStyle: disallow
      #   # bad
      #   block { do_something(it) }
      #
      #   # good
      #   block { do_something(_1) }
      #   block { |named_param| do_something(named_param) }
      #
      class ItBlockParameter < Base
        include ConfigurableEnforcedStyle
        extend TargetRubyVersion
        extend AutoCorrector

        MSG_USE_IT_BLOCK_PARAMETER = 'Use `it` block parameter.'
        MSG_AVOID_IT_BLOCK_PARAMETER = 'Avoid using `it` block parameter.'

        minimum_target_ruby_version 3.4

        def on_block(node)
          return unless style == :always
          return unless node.arguments.one?

          # `restarg`, `kwrestarg`, `blockarg` nodes can return early.
          return unless node.first_argument.arg_type?

          variables = find_block_variables(node, node.first_argument.source)

          variables.each do |variable|
            add_offense(variable, message: MSG_USE_IT_BLOCK_PARAMETER) do |corrector|
              corrector.remove(node.arguments)
              corrector.replace(variable, 'it')
            end
          end
        end

        def on_numblock(node)
          return if style == :disallow
          return unless node.children[1] == 1

          variables = find_block_variables(node, '_1')

          variables.each do |variable|
            add_offense(variable, message: MSG_USE_IT_BLOCK_PARAMETER) do |corrector|
              corrector.replace(variable, 'it')
            end
          end
        end

        def on_itblock(node)
          return unless style == :disallow

          variables = find_block_variables(node, 'it')

          variables.each do |variable|
            add_offense(variable, message: MSG_AVOID_IT_BLOCK_PARAMETER)
          end
        end

        private

        def find_block_variables(node, block_argument_name)
          node.each_descendant(:lvar).select do |descendant|
            descendant.source == block_argument_name
          end
        end
      end
    end
  end
end
