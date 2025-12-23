# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `rescue` blocks with no body.
      #
      # @example
      #
      #   # bad
      #   def some_method
      #     do_something
      #   rescue
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue
      #   end
      #
      #   # good
      #   def some_method
      #     do_something
      #   rescue
      #     handle_exception
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue
      #     handle_exception
      #   end
      #
      # @example AllowComments: true (default)
      #
      #   # good
      #   def some_method
      #     do_something
      #   rescue
      #     # do nothing
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue
      #     # do nothing
      #   end
      #
      # @example AllowComments: false
      #
      #   # bad
      #   def some_method
      #     do_something
      #   rescue
      #     # do nothing
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue
      #     # do nothing
      #   end
      #
      # @example AllowNil: true (default)
      #
      #   # good
      #   def some_method
      #     do_something
      #   rescue
      #     nil
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue
      #     # do nothing
      #   end
      #
      #   # good
      #   do_something rescue nil
      #
      # @example AllowNil: false
      #
      #   # bad
      #   def some_method
      #     do_something
      #   rescue
      #     nil
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue
      #     nil
      #   end
      #
      #   # bad
      #   do_something rescue nil
      class SuppressedException < Base
        MSG = 'Do not suppress exceptions.'

        def on_resbody(node)
          return if node.body && !nil_body?(node)
          return if cop_config['AllowComments'] && comment_between_rescue_and_end?(node)
          return if cop_config['AllowNil'] && nil_body?(node)

          add_offense(node)
        end

        private

        def comment_between_rescue_and_end?(node)
          ancestor = node.each_ancestor(:kwbegin, :any_def, :any_block).first
          return false unless ancestor

          end_line = ancestor.loc.end&.line || ancestor.loc.last_line
          processed_source[node.first_line...end_line].any? { |line| comment_line?(line) }
        end

        def nil_body?(node)
          node.body&.nil_type?
        end
      end
    end
  end
end
