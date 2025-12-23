# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for nested example groups.
      #
      # This cop is configurable using the `Max` option
      # and supports `--auto-gen-config`.
      #
      # @example
      #   # bad
      #   context 'when using some feature' do
      #     let(:some)    { :various }
      #     let(:feature) { :setup   }
      #
      #     context 'when user is signed in' do  # flagged by rubocop
      #       let(:user) do
      #         UserCreate.call(user_attributes)
      #       end
      #
      #       let(:user_attributes) do
      #         {
      #           name: 'John',
      #           age:  22,
      #           role: role
      #         }
      #       end
      #
      #       context 'when user is an admin' do # flagged by rubocop
      #         let(:role) { 'admin' }
      #
      #         it 'blah blah'
      #         it 'yada yada'
      #       end
      #     end
      #   end
      #
      #   # good
      #   context 'using some feature as an admin' do
      #     let(:some)    { :various }
      #     let(:feature) { :setup   }
      #
      #     let(:user) do
      #       UserCreate.call(
      #         name: 'John',
      #         age:  22,
      #         role: 'admin'
      #       )
      #     end
      #
      #     it 'blah blah'
      #     it 'yada yada'
      #   end
      #
      # @example `Max: 3` (default)
      #   # bad
      #   describe Foo do
      #     context 'foo' do
      #       context 'bar' do
      #         context 'baz' do # flagged by rubocop
      #         end
      #       end
      #     end
      #   end
      #
      # @example `Max: 2`
      #   # bad
      #   describe Foo do
      #     context 'foo' do
      #       context 'bar' do # flagged by rubocop
      #         context 'baz' do # flagged by rubocop
      #         end
      #       end
      #     end
      #   end
      #
      # @example `AllowedGroups: [] (default)`
      #   describe Foo do # <-- nested groups 1
      #     context 'foo' do # <-- nested groups 2
      #       context 'bar' do # <-- nested groups 3
      #       end
      #     end
      #   end
      #
      # @example `AllowedGroups: [path]`
      #   describe Foo do # <-- nested groups 1
      #     path '/foo' do # <-- nested groups 1 (not counted)
      #       context 'bar' do # <-- nested groups 2
      #       end
      #     end
      #   end
      #
      class NestedGroups < Base
        include TopLevelGroup

        MSG = 'Maximum example group nesting exceeded [%<total>d/%<max>d].'

        DEPRECATED_MAX_KEY = 'MaxNesting'

        DEPRECATION_WARNING =
          "Configuration key `#{DEPRECATED_MAX_KEY}` for #{cop_name} is " \
          'deprecated in favor of `Max`. Please use that instead.'

        exclude_limit 'Max'

        def on_top_level_group(node)
          find_nested_example_groups(node) do |example_group, nesting|
            self.max = nesting
            add_offense(
              example_group.send_node,
              message: message(nesting)
            )
          end
        end

        private

        def find_nested_example_groups(node, nesting: 1, &block)
          example_group = example_group?(node)
          yield node, nesting if example_group && nesting > max_nesting

          next_nesting = if count_up_nesting?(node, example_group)
                           nesting + 1
                         else
                           nesting
                         end

          node.each_child_node(:block, :begin) do |child|
            find_nested_example_groups(child, nesting: next_nesting, &block)
          end
        end

        def count_up_nesting?(node, example_group)
          example_group &&
            node.block_type? &&
            !allowed_groups.include?(node.method_name.to_s)
        end

        def message(nesting)
          format(MSG, total: nesting, max: max_nesting)
        end

        def max_nesting
          @max_nesting ||= Integer(max_nesting_config)
        end

        def max_nesting_config
          if cop_config.key?(DEPRECATED_MAX_KEY)
            warn DEPRECATION_WARNING
            cop_config.fetch(DEPRECATED_MAX_KEY)
          else
            cop_config.fetch('Max', 3)
          end
        end

        def allowed_groups
          @allowed_groups ||= cop_config.fetch('AllowedGroups', [])
        end
      end
    end
  end
end
