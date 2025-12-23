# frozen_string_literal: true

module SimpleCovJSONFormatter
  class ResultExporter
    FILENAME = 'coverage.json'

    def initialize(result_hash)
      @result = result_hash
    end

    def export
      File.open(export_path, 'w') do |file|
        file << json_result
      end
    end

    private

    def json_result
      JSON.pretty_generate(@result)
    end

    def export_path
      File.join(SimpleCov.coverage_path, FILENAME)
    end
  end
end
