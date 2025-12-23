# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for useless method definitions, specifically: empty constructors
      # and methods just delegating to `super`.
      #
      # @safety
      #   This cop is unsafe as it can register false positives for cases when an empty
      #   constructor just overrides the parent constructor, which is bad anyway.
      #
      # @example
      #   # bad
      #   def initialize
      #     super
      #   end
      #
      #   def method
      #     super
      #   end
      #
      #   # good - with default arguments
      #   def initialize(x = Object.new)
      #     super
      #   end
      #
      #   # good
      #   def initialize
      #     super
      #     initialize_internals
      #   end
      #
      #   def method(*args)
      #     super(:extra_arg, *args)
      #   end
      #
      class UselessMethodDefinition < Base
        extend AutoCorrector

        MSG = 'Useless method definition detected.'

        def on_def(node)
          return if method_definition_with_modifier?(node) || use_rest_or_optional_args?(node)
          return unless delegating?(node.body, node)

          add_offense(node) do |corrector|
            range = node.parent&.send_type? ? node.parent : node

            corrector.remove(range)
          end
        end
        alias on_defs on_def

        private

        def method_definition_with_modifier?(node)
          node.parent&.send_type? && !node.parent&.non_bare_access_modifier?
        end

        def use_rest_or_optional_args?(node)
          node.arguments.any? { |arg| arg.type?(:restarg, :optarg, :kwoptarg) }
        end

        def delegating?(node, def_node)
          if node&.zsuper_type?
            true
          elsif node&.super_type?
            node.arguments.map(&:source) == def_node.arguments.map(&:source)
          else
            false
          end
        end
      end
    end
  end
end
