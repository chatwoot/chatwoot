# frozen_string_literal: true

module RuboCop
  # A wrapper around patterns array to perform optimized search.
  #
  # For projects with a large set of rubocop todo files, most items in `Exclude`/`Include`
  # are exact file names. It is wasteful to linearly check the list of patterns over and over
  # to check if the file is relevant to the cop.
  #
  # This class partitions an array of patterns into a set of exact match strings and the rest
  # of the patterns. This way we can firstly do a cheap check in the set and then proceed via
  # the costly patterns check, if needed.
  # @api private
  class FilePatterns
    @cache = {}.compare_by_identity

    def self.from(patterns)
      @cache[patterns] ||= new(patterns)
    end

    def initialize(patterns)
      @strings = Set.new
      @patterns = []
      partition_patterns(patterns)
    end

    def match?(path)
      @strings.include?(path) || @patterns.any? { |pattern| PathUtil.match_path?(pattern, path) }
    end

    private

    def partition_patterns(patterns)
      patterns.each do |pattern|
        if pattern.is_a?(String) && !pattern.match?(/[*{\[?]/)
          @strings << pattern
        else
          @patterns << pattern
        end
      end
    end
  end
end
