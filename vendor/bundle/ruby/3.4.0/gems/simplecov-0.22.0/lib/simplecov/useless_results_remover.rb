# frozen_string_literal: true

module SimpleCov
  #
  # Select the files that related to working scope directory of SimpleCov
  #
  module UselessResultsRemover
    def self.call(coverage_result)
      coverage_result.select do |path, _coverage|
        path =~ root_regx
      end
    end

    def self.root_regx
      @root_regx ||= /\A#{Regexp.escape(SimpleCov.root + File::SEPARATOR)}/i.freeze
    end
  end
end
