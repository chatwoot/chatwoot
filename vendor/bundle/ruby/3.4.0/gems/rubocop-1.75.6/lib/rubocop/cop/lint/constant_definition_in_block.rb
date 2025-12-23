# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Do not define constants within a block, since the block's scope does not
      # isolate or namespace the constant in any way.
      #
      # If you are trying to define that constant once, define it outside of
      # the block instead, or use a variable or method if defining the constant
      # in the outer scope would be problematic.
      #
      # For meta-programming, use `const_set`.
      #
      # @example
      #   # bad
      #   task :lint do
      #     FILES_TO_LINT = Dir['lib/*.rb']
      #   end
      #
      #   # bad
      #   describe 'making a request' do
      #     class TestRequest; end
      #   end
      #
      #   # bad
      #   module M
      #     extend ActiveSupport::Concern
      #     included do
      #       LIST = []
      #     end
      #   end
      #
      #   # good
      #   task :lint do
      #     files_to_lint = Dir['lib/*.rb']
      #   end
      #
      #   # good
      #   describe 'making a request' do
      #     let(:test_request) { Class.new }
      #     # see also `stub_const` for RSpec
      #   end
      #
      #   # good
      #   module M
      #     extend ActiveSupport::Concern
      #     included do
      #       const_set(:LIST, [])
      #     end
      #   end
      #
      # @example AllowedMethods: ['enums'] (default)
      #   # good
      #
      #   # `enums` for Typed Enums via `T::Enum` in Sorbet.
      #   # https://sorbet.org/docs/tenum
      #   class TestEnum < T::Enum
      #     enums do
      #       Foo = new("foo")
      #     end
      #   end
      #
      class ConstantDefinitionInBlock < Base
        include AllowedMethods

        MSG = 'Do not define constants this way within a block.'

        # @!method constant_assigned_in_block?(node)
        def_node_matcher :constant_assigned_in_block?, <<~PATTERN
          ({^any_block [^begin ^^any_block]} nil? ...)
        PATTERN

        # @!method module_defined_in_block?(node)
        def_node_matcher :module_defined_in_block?, <<~PATTERN
          ({^any_block [^begin ^^any_block]} ...)
        PATTERN

        def on_casgn(node)
          return if !constant_assigned_in_block?(node) || allowed_method?(method_name(node))

          add_offense(node)
        end

        def on_class(node)
          return if !module_defined_in_block?(node) || allowed_method?(method_name(node))

          add_offense(node)
        end
        alias on_module on_class

        private

        def method_name(node)
          node.ancestors.find(&:any_block_type?).method_name
        end
      end
    end
  end
end
