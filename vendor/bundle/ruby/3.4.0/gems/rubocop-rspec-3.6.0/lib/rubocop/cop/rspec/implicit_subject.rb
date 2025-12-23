# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for usage of implicit subject (`is_expected` / `should`).
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: single_line_only` (default)
      #   # bad
      #   it do
      #     is_expected.to be_truthy
      #   end
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #   it do
      #     expect(subject).to be_truthy
      #   end
      #
      # @example `EnforcedStyle: single_statement_only`
      #   # bad
      #   it do
      #     foo = 1
      #     is_expected.to be_truthy
      #   end
      #
      #   # good
      #   it do
      #     foo = 1
      #     expect(subject).to be_truthy
      #   end
      #   it do
      #     is_expected.to be_truthy
      #   end
      #
      # @example `EnforcedStyle: disallow`
      #   # bad
      #   it { is_expected.to be_truthy }
      #
      #   # good
      #   it { expect(subject).to be_truthy }
      #
      # @example `EnforcedStyle: require_implicit`
      #   # bad
      #   it { expect(subject).to be_truthy }
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #
      #   # bad
      #   it do
      #     expect(subject).to be_truthy
      #   end
      #
      #   # good
      #   it do
      #     is_expected.to be_truthy
      #   end
      #
      #   # good
      #   it { expect(named_subject).to be_truthy }
      #
      class ImplicitSubject < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG_REQUIRE_EXPLICIT = "Don't use implicit subject."

        MSG_REQUIRE_IMPLICIT = "Don't use explicit subject."

        RESTRICT_ON_SEND = %i[
          expect
          is_expected
          should
          should_not
        ].freeze

        # @!method explicit_unnamed_subject?(node)
        def_node_matcher :explicit_unnamed_subject?, <<~PATTERN
          (send nil? :expect (send nil? :subject))
        PATTERN

        # @!method implicit_subject?(node)
        def_node_matcher :implicit_subject?, <<~PATTERN
          (send nil? {:should :should_not :is_expected} ...)
        PATTERN

        def on_send(node)
          return unless invalid?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          case node.method_name
          when :expect
            corrector.replace(node, 'is_expected')
          when :is_expected
            corrector.replace(node.location.selector, 'expect(subject)')
          when :should
            corrector.replace(node.location.selector, 'expect(subject).to')
          when :should_not
            corrector.replace(node.location.selector, 'expect(subject).not_to')
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end

        def message(_node)
          case style
          when :require_implicit
            MSG_REQUIRE_IMPLICIT
          else
            MSG_REQUIRE_EXPLICIT
          end
        end

        def invalid?(node)
          case style
          when :require_implicit
            explicit_unnamed_subject?(node)
          when :disallow
            implicit_subject_in_non_its?(node)
          when :single_line_only
            implicit_subject_in_non_its_and_non_single_line?(node)
          when :single_statement_only
            implicit_subject_in_non_its_and_non_single_statement?(node)
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end

        def implicit_subject_in_non_its?(node)
          implicit_subject?(node) && !its?(node)
        end

        def implicit_subject_in_non_its_and_non_single_line?(node)
          implicit_subject_in_non_its?(node) && !single_line?(node)
        end

        def implicit_subject_in_non_its_and_non_single_statement?(node)
          implicit_subject_in_non_its?(node) && !single_statement?(node)
        end

        def its?(node)
          example_of(node)&.method?(:its)
        end

        def single_line?(node)
          example_of(node)&.single_line?
        end

        def single_statement?(node)
          !example_of(node)&.body&.begin_type?
        end

        def example_of(node)
          node.each_ancestor.find do |ancestor|
            example?(ancestor)
          end
        end
      end
    end
  end
end
