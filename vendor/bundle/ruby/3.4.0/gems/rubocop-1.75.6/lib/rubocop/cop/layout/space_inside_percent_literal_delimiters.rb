# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for unnecessary additional spaces inside the delimiters of
      # %i/%w/%x literals.
      #
      # @example
      #
      #   # bad
      #   %i( foo bar baz )
      #
      #   # good
      #   %i(foo bar baz)
      #
      #   # bad
      #   %w( foo bar baz )
      #
      #   # good
      #   %w(foo bar baz)
      #
      #   # bad
      #   %x(  ls -l )
      #
      #   # good
      #   %x(ls -l)
      #
      #   # bad
      #   %w( )
      #   %w(
      #   )
      #
      #   # good
      #   %w()
      class SpaceInsidePercentLiteralDelimiters < Base
        include MatchRange
        include PercentLiteral
        extend AutoCorrector

        MSG = 'Do not use spaces inside percent literal delimiters.'
        BEGIN_REGEX = /\A( +)/.freeze
        END_REGEX = /(?<!\\)( +)\z/.freeze

        def on_array(node)
          process(node, '%i', '%I', '%w', '%W')
        end

        def on_xstr(node)
          process(node, '%x')
        end

        def on_percent_literal(node)
          add_offenses_for_blank_spaces(node)
          add_offenses_for_unnecessary_spaces(node)
        end

        private

        def add_offenses_for_blank_spaces(node)
          range = body_range(node)
          return if range.source.empty? || !range.source.strip.empty?

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end

        def add_offenses_for_unnecessary_spaces(node)
          return unless node.single_line?

          regex_matches(node) do |match_range|
            add_offense(match_range) do |corrector|
              corrector.remove(match_range)
            end
          end
        end

        def regex_matches(node, &blk)
          [BEGIN_REGEX, END_REGEX].each do |regex|
            each_match_range(contents_range(node), regex, &blk)
          end
        end

        def body_range(node)
          node.source_range.with(
            begin_pos: node.location.begin.end_pos,
            end_pos: node.location.end.begin_pos
          )
        end
      end
    end
  end
end
