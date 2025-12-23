# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `in;` uses in `case` expressions.
      #
      # @example
      #   # bad
      #   case expression
      #   in pattern_a; foo
      #   in pattern_b; bar
      #   end
      #
      #   # good
      #   case expression
      #   in pattern_a then foo
      #   in pattern_b then bar
      #   end
      #
      class InPatternThen < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.7

        MSG = 'Do not use `in %<pattern>s;`. Use `in %<pattern>s then` instead.'

        def on_in_pattern(node)
          return if node.multiline? || node.then? || !node.body

          pattern = node.pattern
          pattern_source = if pattern.match_alt_type?
                             alternative_pattern_source(pattern)
                           else
                             pattern.source
                           end

          add_offense(node.loc.begin, message: format(MSG, pattern: pattern_source)) do |corrector|
            corrector.replace(node.loc.begin, ' then')
          end
        end

        private

        def alternative_pattern_source(pattern)
          collect_alternative_patterns(pattern).join(' | ')
        end

        def collect_alternative_patterns(pattern)
          return pattern.children.map(&:source) unless pattern.children.first.match_alt_type?

          pattern_sources = collect_alternative_patterns(pattern.children.first)

          pattern_sources << pattern.children[1].source
        end
      end
    end
  end
end
