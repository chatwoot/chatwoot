# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if example groups contain too many `let` and `subject` calls.
      #
      # This cop is configurable using the `Max` option and the `AllowSubject`
      # which will configure the cop to only register offenses on calls to
      # `let` and not calls to `subject`.
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #     let(:quuz) { {} }
      #   end
      #
      #   describe MyClass do
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #
      #     context 'when stuff' do
      #       let(:qux) { [] }
      #       let(:quux) { [] }
      #       let(:quuz) { {} }
      #     end
      #   end
      #
      #   # good
      #   describe MyClass do
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #     let(:quuz) { {} }
      #   end
      #
      #   describe MyClass do
      #     context 'when stuff' do
      #       let(:foo) { [] }
      #       let(:bar) { [] }
      #       let!(:booger) { [] }
      #     end
      #
      #     context 'when other stuff' do
      #       let(:qux) { [] }
      #       let(:quux) { [] }
      #       let(:quuz) { {} }
      #     end
      #   end
      #
      # @example when disabling AllowSubject configuration
      #   # rubocop.yml
      #   # RSpec/MultipleMemoizedHelpers:
      #   #   AllowSubject: false
      #
      #   # bad - `subject` counts towards memoized helpers
      #   describe MyClass do
      #     subject { {} }
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #   end
      #
      # @example with Max configuration
      #   # rubocop.yml
      #   # RSpec/MultipleMemoizedHelpers:
      #   #   Max: 1
      #
      #   # bad
      #   describe MyClass do
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #   end
      #
      class MultipleMemoizedHelpers < Base
        include Variable

        MSG = 'Example group has too many memoized helpers [%<count>d/%<max>d]'

        exclude_limit 'Max'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless spec_group?(node)

          count = all_helpers(node).uniq.count

          return if count <= max

          self.max = count
          add_offense(node, message: format(MSG, count: count, max: max))
        end

        def on_new_investigation
          super
          @example_group_memoized_helpers = {}
        end

        private

        attr_reader :example_group_memoized_helpers

        def all_helpers(node)
          helpers(node) +
            node.each_ancestor(:block).flat_map { |ancestor| helpers(ancestor) }
        end

        def helpers(node)
          @example_group_memoized_helpers[node] ||=
            variable_nodes(node).map do |variable_node|
              if variable_node.block_type?
                variable_definition?(variable_node.send_node)
              else # block-pass (`let(:foo, &bar)`)
                variable_definition?(variable_node)
              end
            end
        end

        def variable_nodes(node)
          example_group = RuboCop::RSpec::ExampleGroup.new(node)

          if allow_subject?
            example_group.lets
          else
            example_group.lets + example_group.subjects
          end
        end

        def max
          cop_config['Max']
        end

        def allow_subject?
          cop_config['AllowSubject']
        end
      end
    end
  end
end
