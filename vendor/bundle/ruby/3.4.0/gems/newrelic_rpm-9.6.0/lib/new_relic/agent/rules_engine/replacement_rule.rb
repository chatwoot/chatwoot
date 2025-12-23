# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class RulesEngine
      class ReplacementRule
        attr_reader(:terminate_chain, :each_segment, :ignore, :replace_all, :eval_order,
          :match_expression, :replacement)

        def initialize(options)
          if !options['match_expression']
            raise ArgumentError.new('missing required match_expression')
          end
          if !options['replacement'] && !options['ignore']
            raise ArgumentError.new('must specify replacement when ignore is false')
          end

          @match_expression = Regexp.new(options['match_expression'], Regexp::IGNORECASE)
          @replacement = options['replacement']
          @ignore = options['ignore'] || false
          @eval_order = options['eval_order'] || 0
          @replace_all = options['replace_all'] || false
          @each_segment = options['each_segment'] || false
          @terminate_chain = options['terminate_chain'] || false
        end

        def terminal?
          @terminate_chain || @ignore
        end

        def matches?(string)
          if @each_segment
            string.split(SEGMENT_SEPARATOR).any? do |segment|
              segment.match(@match_expression)
            end
          else
            string.match(@match_expression)
          end
        end

        def apply(string)
          if @ignore
            nil
          elsif @each_segment
            apply_to_each_segment(string)
          else
            apply_replacement(string)
          end
        end

        def apply_replacement(string)
          method = @replace_all ? :gsub : :sub
          string.send(method, @match_expression, @replacement)
        end

        def apply_to_each_segment(string)
          string = string.dup
          leading_slash = string.slice!(LEADING_SLASH_REGEX)
          segments = string.split(SEGMENT_SEPARATOR)

          segments.map! do |segment|
            apply_replacement(segment)
          end

          "#{leading_slash}#{segments.join(SEGMENT_SEPARATOR)}"
        end

        def <=>(other)
          eval_order <=> other.eval_order
        end
      end
    end
  end
end
