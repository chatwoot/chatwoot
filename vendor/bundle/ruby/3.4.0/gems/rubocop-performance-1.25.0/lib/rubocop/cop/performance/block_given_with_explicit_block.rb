# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies unnecessary use of a `block_given?` where explicit check
      # of block argument would suffice.
      #
      # NOTE: This cop produces code with significantly worse performance when a
      # block is being passed to the method and as such should not be enabled.
      #
      # @example
      #   # bad
      #   def method(&block)
      #     do_something if block_given?
      #   end
      #
      #   # good
      #   def method(&block)
      #     do_something if block
      #   end
      #
      #   # good - block is reassigned
      #   def method(&block)
      #     block ||= -> { do_something }
      #     warn "Using default ..." unless block_given?
      #     # ...
      #   end
      #
      class BlockGivenWithExplicitBlock < Base
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[block_given?].freeze
        MSG = 'Check block argument explicitly instead of using `block_given?`.'

        def_node_matcher :reassigns_block_arg?, '`(lvasgn %1 ...)'

        def on_send(node)
          def_node = node.each_ancestor(:def, :defs).first
          return unless def_node

          block_arg = def_node.arguments.find(&:blockarg_type?)
          return unless block_arg
          return unless (block_arg_name = block_arg.loc.name)

          block_arg_name = block_arg_name.source.to_sym
          return if reassigns_block_arg?(def_node, block_arg_name)

          add_offense(node) do |corrector|
            corrector.replace(node, block_arg_name)
          end
        end

        def self.autocorrect_incompatible_with
          [Lint::UnusedMethodArgument]
        end
      end
    end
  end
end
