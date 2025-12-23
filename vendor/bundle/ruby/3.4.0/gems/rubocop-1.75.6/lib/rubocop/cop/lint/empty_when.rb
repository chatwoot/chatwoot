# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of `when` branches without a body.
      #
      # @example
      #
      #   # bad
      #   case foo
      #   when bar
      #     do_something
      #   when baz
      #   end
      #
      #   # good
      #   case condition
      #   when foo
      #     do_something
      #   when bar
      #     nil
      #   end
      #
      # @example AllowComments: true (default)
      #
      #   # good
      #   case condition
      #   when foo
      #     do_something
      #   when bar
      #     # noop
      #   end
      #
      # @example AllowComments: false
      #
      #   # bad
      #   case condition
      #   when foo
      #     do_something
      #   when bar
      #     # do nothing
      #   end
      #
      class EmptyWhen < Base
        include CommentsHelp

        MSG = 'Avoid `when` branches without a body.'

        def on_case(node)
          node.when_branches.each do |when_node|
            next if when_node.body
            next if cop_config['AllowComments'] && contains_comments?(when_node)

            add_offense(when_node)
          end
        end
      end
    end
  end
end
