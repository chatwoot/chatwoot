# frozen_string_literal: true

module SimpleCov
  module ExitCodes
    class MaximumCoverageDropCheck
      def initialize(result, maximum_coverage_drop)
        @result = result
        @maximum_coverage_drop = maximum_coverage_drop
      end

      def failing?
        return false unless maximum_coverage_drop && last_run

        coverage_drop_violations.any?
      end

      def report
        coverage_drop_violations.each do |violation|
          $stderr.printf(
            "%<criterion>s coverage has dropped by %<drop_percent>.2f%% since the last time (maximum allowed: %<max_drop>.2f%%).\n",
            criterion: violation[:criterion].capitalize,
            drop_percent: SimpleCov.round_coverage(violation[:drop_percent]),
            max_drop: violation[:max_drop]
          )
        end
      end

      def exit_code
        SimpleCov::ExitCodes::MAXIMUM_COVERAGE_DROP
      end

    private

      attr_reader :result, :maximum_coverage_drop

      def last_run
        return @last_run if defined?(@last_run)

        @last_run = SimpleCov::LastRun.read
      end

      def coverage_drop_violations
        @coverage_drop_violations ||=
          compute_coverage_drop_data.select do |achieved|
            achieved.fetch(:max_drop) < achieved.fetch(:drop_percent)
          end
      end

      def compute_coverage_drop_data
        maximum_coverage_drop.map do |criterion, percent|
          {
            criterion: criterion,
            max_drop: percent,
            drop_percent: drop_percent(criterion)
          }
        end
      end

      # if anyone says "max_coverage_drop 0.000000000000000001" I appologize. Please don't.
      MAX_DROP_ACCURACY = 10
      def drop_percent(criterion)
        drop = last_coverage(criterion) -
               SimpleCov.round_coverage(
                 result.coverage_statistics.fetch(criterion).percent
               )

        # floats, I tell ya.
        # irb(main):001:0* 80.01 - 80.0
        # => 0.010000000000005116
        drop.floor(MAX_DROP_ACCURACY)
      end

      def last_coverage(criterion)
        last_coverage_percent = last_run[:result][criterion]

        # fallback for old file format
        last_coverage_percent = last_run[:result][:covered_percent] if !last_coverage_percent && criterion == :line

        last_coverage_percent || 0
      end
    end
  end
end
