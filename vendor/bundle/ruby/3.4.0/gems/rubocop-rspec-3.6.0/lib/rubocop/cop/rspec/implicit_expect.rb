# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that a consistent implicit expectation style is used.
      #
      # This cop can be configured using the `EnforcedStyle` option
      # and supports the `--auto-gen-config` flag.
      #
      # @example `EnforcedStyle: is_expected` (default)
      #   # bad
      #   it { should be_truthy }
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #
      # @example `EnforcedStyle: should`
      #   # bad
      #   it { is_expected.to be_truthy }
      #
      #   # good
      #   it { should be_truthy }
      #
      class ImplicitExpect < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG = 'Prefer `%<good>s` over `%<bad>s`.'

        RESTRICT_ON_SEND = Runners.all + %i[should should_not]

        # @!method implicit_expect(node)
        def_node_matcher :implicit_expect, <<~PATTERN
          {
            (send nil? ${:should :should_not} ...)
            (send (send nil? $:is_expected) #Runners.all ...)
          }
        PATTERN

        alternatives = {
          'is_expected.to'     => 'should',
          'is_expected.not_to' => 'should_not',
          'is_expected.to_not' => 'should_not'
        }

        ENFORCED_REPLACEMENTS = alternatives.merge(alternatives.invert).freeze

        def on_send(node)
          return unless (source_range = offending_expect(node))

          expectation_source = source_range.source

          if expectation_source.start_with?(style.to_s)
            correct_style_detected
          else
            opposite_style_detected

            msg = offense_message(expectation_source)
            add_offense(source_range, message: msg) do |corrector|
              replacement = replacement_source(expectation_source)
              corrector.replace(source_range, replacement)
            end
          end
        end

        private

        def offending_expect(node)
          case implicit_expect(node)
          when :is_expected
            range_for_is_expected(node.loc)
          when :should, :should_not
            node.loc.selector
          end
        end

        def range_for_is_expected(source_map)
          Parser::Source::Range.new(
            source_map.expression.source_buffer,
            source_map.expression.begin_pos,
            source_map.selector.end_pos
          )
        end

        def offense_message(offending_source)
          format(
            MSG,
            good: replacement_source(offending_source),
            bad:  offending_source
          )
        end

        def replacement_source(offending_source)
          ENFORCED_REPLACEMENTS.fetch(offending_source)
        end
      end
    end
  end
end
