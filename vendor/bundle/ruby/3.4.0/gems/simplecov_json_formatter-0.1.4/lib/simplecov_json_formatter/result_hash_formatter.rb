# frozen_string_literal: true

require 'simplecov_json_formatter/source_file_formatter'

module SimpleCovJSONFormatter
  class ResultHashFormatter
    def initialize(result)
      @result = result
    end

    def format
      format_files
      format_groups

      formatted_result
    end

    private

    def format_files
      @result.files.each do |source_file|
        formatted_result[:coverage][source_file.filename] =
          format_source_file(source_file)
      end
    end

    def format_groups
      @result.groups.each do |name, file_list|
        formatted_result[:groups][name] = {
          lines: {
            covered_percent: file_list.covered_percent
          }
        }
      end
    end

    def formatted_result
      @formatted_result ||= {
        meta: {
          simplecov_version: SimpleCov::VERSION
        },
        coverage: {},
        groups: {}
      }
    end

    def format_source_file(source_file)
      source_file_formatter = SourceFileFormatter.new(source_file)
      source_file_formatter.format
    end
  end
end
