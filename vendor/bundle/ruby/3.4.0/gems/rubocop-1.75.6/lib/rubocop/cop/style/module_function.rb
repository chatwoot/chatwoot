# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for use of `extend self` or `module_function` in a module.
      #
      # Supported styles are: `module_function` (default), `extend_self` and `forbidden`.
      #
      # A couple of things to keep in mind:
      #
      # - `forbidden` style prohibits the usage of both styles
      # - in default mode (`module_function`), the cop won't be activated when the module
      #   contains any private methods
      #
      # @safety
      #   Autocorrection is unsafe (and is disabled by default) because `extend self`
      #   and `module_function` do not behave exactly the same.
      #
      # @example EnforcedStyle: module_function (default)
      #   # bad
      #   module Test
      #     extend self
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     module_function
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     extend self
      #     # ...
      #     private
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     class << self
      #       # ...
      #     end
      #   end
      #
      # @example EnforcedStyle: extend_self
      #   # bad
      #   module Test
      #     module_function
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     extend self
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     class << self
      #       # ...
      #     end
      #   end
      #
      # @example EnforcedStyle: forbidden
      #   # bad
      #   module Test
      #     module_function
      #     # ...
      #   end
      #
      #   # bad
      #   module Test
      #     extend self
      #     # ...
      #   end
      #
      #   # bad
      #   module Test
      #     extend self
      #     # ...
      #     private
      #     # ...
      #   end
      #
      #   # good
      #   module Test
      #     class << self
      #       # ...
      #     end
      #   end
      class ModuleFunction < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MODULE_FUNCTION_MSG = 'Use `module_function` instead of `extend self`.'
        EXTEND_SELF_MSG = 'Use `extend self` instead of `module_function`.'
        FORBIDDEN_MSG = 'Do not use `module_function` or `extend self`.'

        # @!method module_function_node?(node)
        def_node_matcher :module_function_node?, '(send nil? :module_function)'

        # @!method extend_self_node?(node)
        def_node_matcher :extend_self_node?, '(send nil? :extend self)'

        # @!method private_directive?(node)
        def_node_matcher :private_directive?, '(send nil? :private ...)'

        def on_module(node)
          return unless node.body&.begin_type?

          each_wrong_style(node.body.children) do |child_node|
            add_offense(child_node) do |corrector|
              next if style == :forbidden

              if extend_self_node?(child_node)
                corrector.replace(child_node, 'module_function')
              else
                corrector.replace(child_node, 'extend self')
              end
            end
          end
        end

        private

        def each_wrong_style(nodes, &block)
          case style
          when :module_function
            check_module_function(nodes, &block)
          when :extend_self
            check_extend_self(nodes, &block)
          when :forbidden
            check_forbidden(nodes, &block)
          end
        end

        def check_module_function(nodes)
          return if nodes.any? { |node| private_directive?(node) }

          nodes.each do |node|
            yield node if extend_self_node?(node)
          end
        end

        def check_extend_self(nodes)
          nodes.each do |node|
            yield node if module_function_node?(node)
          end
        end

        def check_forbidden(nodes)
          nodes.each do |node|
            yield node if extend_self_node?(node)
            yield node if module_function_node?(node)
          end
        end

        def message(_range)
          return FORBIDDEN_MSG if style == :forbidden

          style == :module_function ? MODULE_FUNCTION_MSG : EXTEND_SELF_MSG
        end
      end
    end
  end
end
