# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class RulesEngine
      class SegmentTermsRule
        PREFIX_KEY = 'prefix'.freeze
        TERMS_KEY = 'terms'.freeze
        SEGMENT_PLACEHOLDER = '*'.freeze
        ADJACENT_PLACEHOLDERS_REGEX = %r{((?:^|/)\*)(?:/\*)*}.freeze
        ADJACENT_PLACEHOLDERS_REPLACEMENT = '\1'.freeze

        attr_reader :prefix, :terms

        def self.valid?(rule_spec)
          rule_spec[PREFIX_KEY].kind_of?(String) &&
            rule_spec[TERMS_KEY].kind_of?(Array) &&
            valid_prefix_segment_count?(rule_spec[PREFIX_KEY])
        end

        def self.valid_prefix_segment_count?(prefix)
          count = prefix.count(SEGMENT_SEPARATOR)
          rindex = prefix.rindex(SEGMENT_SEPARATOR)

          (count == 2 && prefix[rindex + 1].nil?) ||
            (count == 1 && !prefix[rindex + 1].nil?)
        end

        def initialize(options)
          @prefix = options[PREFIX_KEY]
          @terms = options[TERMS_KEY]
          @trim_range = (@prefix.size..-1)
        end

        def terminal?
          true
        end

        def matches?(string)
          string.start_with?(@prefix) &&
            (prefix_matches_on_segment_boundary?(string) || string.size == @prefix.size)
        end

        def prefix_matches_on_segment_boundary?(string)
          string.size > @prefix.size &&
            string[@prefix.chomp(SEGMENT_SEPARATOR).size].chr == SEGMENT_SEPARATOR
        end

        def apply(string)
          rest = string[@trim_range]
          leading_slash = rest.slice!(LEADING_SLASH_REGEX)
          segments = rest.split(SEGMENT_SEPARATOR, -1)
          segments.map! { |s| @terms.include?(s) ? s : SEGMENT_PLACEHOLDER }
          transformed_suffix = collapse_adjacent_placeholder_segments(segments)

          "#{@prefix}#{leading_slash}#{transformed_suffix}"
        end

        def collapse_adjacent_placeholder_segments(segments)
          joined = segments.join(SEGMENT_SEPARATOR)
          joined.gsub!(ADJACENT_PLACEHOLDERS_REGEX, ADJACENT_PLACEHOLDERS_REPLACEMENT)
          joined
        end
      end
    end
  end
end
