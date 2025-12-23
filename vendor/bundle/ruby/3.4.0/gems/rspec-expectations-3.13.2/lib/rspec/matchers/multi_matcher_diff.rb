module RSpec
  module Matchers
    # @api private
    # Handles list of expected and actual value pairs when there is a need
    # to render multiple diffs. Also can handle one pair.
    class MultiMatcherDiff
      # @private
      # Default diff label when there is only one matcher in diff
      # output
      DEFAULT_DIFF_LABEL = "Diff:".freeze

      # @private
      # Maximum readable matcher description length
      DESCRIPTION_MAX_LENGTH = 65

      def initialize(expected_list)
        @expected_list = expected_list
      end

      # @api private
      # Wraps provided expected value in instance of
      # MultiMatcherDiff. If provided value is already an
      # MultiMatcherDiff then it just returns it.
      # @param [Any] expected value to be wrapped
      # @param [Any] actual value
      # @return [RSpec::Matchers::MultiMatcherDiff]
      def self.from(expected, actual)
        return expected if self === expected
        new([[expected, DEFAULT_DIFF_LABEL, actual]])
      end

      # @api private
      # Wraps provided matcher list in instance of
      # MultiMatcherDiff.
      # @param [Array<Any>] matchers list of matchers to wrap
      # @return [RSpec::Matchers::MultiMatcherDiff]
      def self.for_many_matchers(matchers)
        new(matchers.map { |m| [m.expected, diff_label_for(m), m.actual] })
      end

      # @api private
      # Returns message with diff(s) appended for provided differ
      # factory and actual value if there are any
      # @param [String] message original failure message
      # @param [Proc] differ
      # @return [String]
      def message_with_diff(message, differ)
        diff = diffs(differ)
        message = "#{message}\n#{diff}" unless diff.empty?
        message
      end

    private

      class << self
        private

        def diff_label_for(matcher)
          "Diff for (#{truncated(RSpec::Support::ObjectFormatter.format(matcher))}):"
        end

        def truncated(description)
          return description if description.length <= DESCRIPTION_MAX_LENGTH
          description[0...DESCRIPTION_MAX_LENGTH - 3] << "..."
        end
      end

      def diffs(differ)
        @expected_list.map do |(expected, diff_label, actual)|
          diff = differ.diff(actual, expected)
          next if diff.strip.empty?
          if diff == "\e[0m\n\e[0m"
            "#{diff_label}\n" \
              "  <The diff is empty, are your objects producing identical `#inspect` output?>"
          else
            "#{diff_label}#{diff}"
          end
        end.compact.join("\n")
      end
    end
  end
end
