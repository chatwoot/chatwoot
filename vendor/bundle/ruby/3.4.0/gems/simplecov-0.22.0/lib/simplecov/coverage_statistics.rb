# frozen_string_literal: true

module SimpleCov
  # Holds the individual data of a coverage result.
  #
  # This is uniform across coverage criteria as they all have:
  #
  # * total - how many things to cover there are (total relevant loc/branches)
  # * covered - how many of the coverables are hit
  # * missed - how many of the coverables are missed
  # * percent - percentage as covered/missed
  # * strength - average hits per/coverable (will not exist for one shot lines format)
  class CoverageStatistics
    attr_reader :total, :covered, :missed, :strength, :percent

    def self.from(coverage_statistics)
      sum_covered, sum_missed, sum_total_strength =
        coverage_statistics.reduce([0, 0, 0.0]) do |(covered, missed, total_strength), file_coverage_statistics|
          [
            covered + file_coverage_statistics.covered,
            missed + file_coverage_statistics.missed,
            # gotta remultiply with loc because files have different strength and loc
            # giving them a different "weight" in total
            total_strength + (file_coverage_statistics.strength * file_coverage_statistics.total)
          ]
        end

      new(covered: sum_covered, missed: sum_missed, total_strength: sum_total_strength)
    end

    # Requires only covered, missed and strength to be initialized.
    #
    # Other values are computed by this class.
    def initialize(covered:, missed:, total_strength: 0.0)
      @covered  = covered
      @missed   = missed
      @total    = covered + missed
      @percent  = compute_percent(covered, missed, total)
      @strength = compute_strength(total_strength, total)
    end

  private

    def compute_percent(covered, missed, total)
      return 100.0 if missed.zero?

      covered * 100.0 / total
    end

    def compute_strength(total_strength, total)
      return 0.0 if total.zero?

      total_strength.to_f / total
    end
  end
end
