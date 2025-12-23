# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if an example group defines `subject` multiple times.
      #
      # @example
      #   # bad
      #   describe Foo do
      #     subject(:user) { User.new }
      #     subject(:post) { Post.new }
      #   end
      #
      #   # good
      #   describe Foo do
      #     let(:user) { User.new }
      #     subject(:post) { Post.new }
      #   end
      #
      #   # bad (does not support autocorrection)
      #   describe Foo do
      #     subject!(:user) { User.new }
      #     subject!(:post) { Post.new }
      #   end
      #
      #   # good
      #   describe Foo do
      #     before do
      #       User.new
      #       Post.new
      #     end
      #   end
      #
      # This cop does not support autocorrection in some cases.
      # The autocorrect behavior for this cop depends on the type of
      # duplication:
      #
      #   - If multiple named subjects are defined then this probably indicates
      #     that the overwritten subjects (all subjects except the last
      #     definition) are effectively being used to define helpers. In this
      #     case they are replaced with `let`.
      #
      #   - If multiple unnamed subjects are defined though then this can *only*
      #     be dead code and we remove the overwritten subject definitions.
      #
      #   - If subjects are defined with `subject!` then we don't autocorrect.
      #     This is enough of an edge case that people can just move this to
      #     a `before` hook on their own
      #
      class MultipleSubjects < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Do not set more than one subject per example group'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)

          subjects = RuboCop::RSpec::ExampleGroup.new(node).subjects

          subjects[0...-1].each do |subject|
            add_offense(subject) do |corrector|
              autocorrect(corrector, subject)
            end
          end
        end

        private

        def autocorrect(corrector, subject)
          return unless subject.method_name.equal?(:subject) # Ignore `subject!`

          if named_subject?(subject)
            rename_autocorrect(corrector, subject)
          else
            remove_autocorrect(corrector, subject)
          end
        end

        def named_subject?(node)
          node.send_node.arguments?
        end

        def rename_autocorrect(corrector, node)
          corrector.replace(node.send_node.loc.selector, 'let')
        end

        def remove_autocorrect(corrector, node)
          range = range_by_whole_lines(node.source_range,
                                       include_final_newline: true)
          corrector.remove(range)
        end
      end
    end
  end
end
