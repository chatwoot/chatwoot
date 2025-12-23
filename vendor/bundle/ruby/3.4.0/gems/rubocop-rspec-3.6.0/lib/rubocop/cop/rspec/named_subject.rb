# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for explicitly referenced test subjects.
      #
      # RSpec lets you declare an "implicit subject" using `subject { ... }`
      # which allows for tests like `it { is_expected.to be_valid }`.
      # If you need to reference your test subject you should explicitly
      # name it using `subject(:your_subject_name) { ... }`. Your test subjects
      # should be the most important object in your tests so they deserve
      # a descriptive name.
      #
      # This cop can be configured in your configuration using `EnforcedStyle`,
      # and `IgnoreSharedExamples` which will not report offenses for implicit
      # subjects in shared example groups.
      #
      # @example `EnforcedStyle: always` (default)
      #   # bad
      #   RSpec.describe User do
      #     subject { described_class.new }
      #
      #     it 'is valid' do
      #       expect(subject.valid?).to be(true)
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe User do
      #     subject(:user) { described_class.new }
      #
      #     it 'is valid' do
      #       expect(user.valid?).to be(true)
      #     end
      #   end
      #
      #   # also good
      #   RSpec.describe User do
      #     subject(:user) { described_class.new }
      #
      #     it { is_expected.to be_valid }
      #   end
      #
      # @example `EnforcedStyle: named_only`
      #   # bad
      #   RSpec.describe User do
      #     subject(:user) { described_class.new }
      #
      #     it 'is valid' do
      #       expect(subject.valid?).to be(true)
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe User do
      #     subject(:user) { described_class.new }
      #
      #     it 'is valid' do
      #       expect(user.valid?).to be(true)
      #     end
      #   end
      #
      #   # also good
      #   RSpec.describe User do
      #     subject { described_class.new }
      #
      #     it { is_expected.to be_valid }
      #   end
      #
      #   # acceptable
      #   RSpec.describe User do
      #     subject { described_class.new }
      #
      #     it 'is valid' do
      #       expect(subject.valid?).to be(true)
      #     end
      #   end
      class NamedSubject < Base
        include ConfigurableEnforcedStyle

        MSG = 'Name your test subject if you need to reference it explicitly.'

        # @!method example_or_hook_block?(node)
        def_node_matcher :example_or_hook_block?, <<~PATTERN
          (block (send nil? {#Examples.all #Hooks.all} ...) ...)
        PATTERN

        # @!method shared_example?(node)
        def_node_matcher :shared_example?, <<~PATTERN
          (block (send #rspec? #SharedGroups.examples ...) ...)
        PATTERN

        # @!method subject_usage(node)
        def_node_search :subject_usage, '$(send nil? :subject)'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          if !example_or_hook_block?(node) || ignored_shared_example?(node)
            return
          end

          subject_usage(node) do |subject_node|
            check_explicit_subject(subject_node)
          end
        end

        private

        def ignored_shared_example?(node)
          return false unless cop_config['IgnoreSharedExamples']

          node.each_ancestor(:block).any? do |ancestor|
            shared_example?(ancestor)
          end
        end

        def check_explicit_subject(node)
          return if allow_explicit_subject?(node)

          add_offense(node.loc.selector)
        end

        def allow_explicit_subject?(node)
          !always? && !named_only?(node)
        end

        def always?
          style == :always
        end

        def named_only?(node)
          style == :named_only &&
            subject_definition_is_named?(node)
        end

        def subject_definition_is_named?(node)
          subject = nearest_subject(node)

          subject&.send_node&.arguments?
        end

        def nearest_subject(node)
          node
            .each_ancestor(:block)
            .lazy
            .map { |block_node| find_subject(block_node) }
            .find(&:itself)
        end

        def find_subject(block_node)
          block_node.body&.child_nodes&.find { |send_node| subject?(send_node) }
        end
      end
    end
  end
end
