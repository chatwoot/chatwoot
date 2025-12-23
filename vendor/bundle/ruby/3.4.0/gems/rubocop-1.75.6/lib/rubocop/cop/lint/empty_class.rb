# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for classes and metaclasses without a body.
      # Such empty classes and metaclasses are typically an oversight or we should provide a comment
      # to be clearer what we're aiming for.
      #
      # @example
      #   # bad
      #   class Foo
      #   end
      #
      #   class Bar
      #     class << self
      #     end
      #   end
      #
      #   class << obj
      #   end
      #
      #   # good
      #   class Foo
      #     def do_something
      #       # ... code
      #     end
      #   end
      #
      #   class Bar
      #     class << self
      #       attr_reader :bar
      #     end
      #   end
      #
      #   class << obj
      #     attr_reader :bar
      #   end
      #
      # @example AllowComments: false (default)
      #   # bad
      #   class Foo
      #     # TODO: implement later
      #   end
      #
      #   class Bar
      #     class << self
      #       # TODO: implement later
      #     end
      #   end
      #
      #   class << obj
      #     # TODO: implement later
      #   end
      #
      # @example AllowComments: true
      #   # good
      #   class Foo
      #     # TODO: implement later
      #   end
      #
      #   class Bar
      #     class << self
      #       # TODO: implement later
      #     end
      #   end
      #
      #   class << obj
      #     # TODO: implement later
      #   end
      #
      class EmptyClass < Base
        CLASS_MSG = 'Empty class detected.'
        METACLASS_MSG = 'Empty metaclass detected.'

        def on_class(node)
          add_offense(node, message: CLASS_MSG) unless body_or_allowed_comment_lines?(node) ||
                                                       node.parent_class
        end

        def on_sclass(node)
          add_offense(node, message: METACLASS_MSG) unless body_or_allowed_comment_lines?(node)
        end

        private

        def body_or_allowed_comment_lines?(node)
          return true if node.body

          cop_config['AllowComments'] && processed_source.contains_comment?(node.source_range)
        end
      end
    end
  end
end
