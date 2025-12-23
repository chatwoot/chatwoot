# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for obtaining source ranges from regexp matches
    module MatchRange
      include RangeHelp

      private

      # Return a new `Range` covering the first matching group number for each
      # match of `regex` inside `range`
      def each_match_range(range, regex)
        range.source.scan(regex) { yield match_range(range, Regexp.last_match) }
      end

      # For a `match` inside `range`, return a new `Range` covering the match
      def match_range(range, match)
        range_between(range.begin_pos + match.begin(1), range.begin_pos + match.end(1))
      end
    end
  end
end
