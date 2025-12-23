# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the use of a return with a value in a context
      # where the value will be ignored. (initialize and setter methods)
      #
      # @example
      #
      #   # bad
      #   def initialize
      #     foo
      #     return :qux if bar?
      #     baz
      #   end
      #
      #   def foo=(bar)
      #     return 42
      #   end
      #
      #   # good
      #   def initialize
      #     foo
      #     return if bar?
      #     baz
      #   end
      #
      #   def foo=(bar)
      #     return
      #   end
      class ReturnInVoidContext < Base
        MSG = 'Do not return a value in `%<method>s`.'

        # Returning out of these methods only exits the block itself.
        SCOPE_CHANGING_METHODS = %i[lambda define_method define_singleton_method].freeze

        def on_return(return_node)
          return unless return_node.descendants.any?

          def_node = return_node.each_ancestor(:any_def).first
          return unless def_node&.void_context?
          return if return_node.each_ancestor(:any_block).any? do |block_node|
            SCOPE_CHANGING_METHODS.include?(block_node.method_name)
          end

          add_offense(
            return_node.loc.keyword,
            message: format(message, method: def_node.method_name)
          )
        end
      end
    end
  end
end
