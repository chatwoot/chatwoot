# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Newcomers to ruby applications may write top-level methods,
      # when ideally they should be organized in appropriate classes or modules.
      # This cop looks for definitions of top-level methods and warns about them.
      #
      # However for ruby scripts it is perfectly fine to use top-level methods.
      # Hence this cop is disabled by default.
      #
      # @example
      #   # bad
      #   def some_method
      #   end
      #
      #   # bad
      #   def self.some_method
      #   end
      #
      #   # bad
      #   define_method(:foo) { puts 1 }
      #
      #   # good
      #   module Foo
      #     def some_method
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     def self.some_method
      #     end
      #   end
      #
      #   # good
      #   Struct.new do
      #     def some_method
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     define_method(:foo) { puts 1 }
      #   end
      class TopLevelMethodDefinition < Base
        MSG = 'Do not define methods at the top-level.'

        RESTRICT_ON_SEND = %i[define_method].freeze

        def on_def(node)
          return unless top_level_method_definition?(node)

          add_offense(node)
        end
        alias on_defs on_def
        alias on_send on_def

        def on_block(node)
          return unless define_method_block?(node) && top_level_method_definition?(node)

          add_offense(node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def top_level_method_definition?(node)
          if node.parent&.begin_type?
            node.parent.root?
          else
            node.root?
          end
        end

        # @!method define_method_block?(node)
        def_node_matcher :define_method_block?, <<~PATTERN
          (any_block (send _ :define_method _) ...)
        PATTERN
      end
    end
  end
end
