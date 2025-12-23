# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Enforce that subject is the first definition in the test.
      #
      # @example
      #   # bad
      #   let(:params) { blah }
      #   subject { described_class.new(params) }
      #
      #   before { do_something }
      #   subject { described_class.new(params) }
      #
      #   it { expect_something }
      #   subject { described_class.new(params) }
      #   it { expect_something_else }
      #
      #
      #   # good
      #   subject { described_class.new(params) }
      #   let(:params) { blah }
      #
      #   # good
      #   subject { described_class.new(params) }
      #   before { do_something }
      #
      #   # good
      #   subject { described_class.new(params) }
      #   it { expect_something }
      #   it { expect_something_else }
      #
      class LeadingSubject < Base
        extend AutoCorrector
        include InsideExampleGroup

        MSG = 'Declare `subject` above any other `%<offending>s` declarations.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless subject?(node)
          return unless inside_example_group?(node)

          check_previous_nodes(node)
        end

        private

        def check_previous_nodes(node)
          offending_node(node) do |offender|
            msg = format(MSG, offending: offender.method_name)
            add_offense(node, message: msg) do |corrector|
              autocorrect(corrector, node, offender)
            end
          end
        end

        def offending_node(node)
          parent(node).each_child_node.find do |sibling|
            break if sibling.equal?(node)

            yield sibling if offending?(sibling)
          end
        end

        def parent(node)
          node.each_ancestor(:block).first.body
        end

        def autocorrect(corrector, node, sibling)
          RuboCop::RSpec::Corrector::MoveNode.new(
            node, corrector, processed_source
          ).move_before(sibling)
        end

        def offending?(node)
          let?(node) ||
            hook?(node) ||
            example?(node) ||
            spec_group?(node) ||
            include?(node)
        end
      end
    end
  end
end
