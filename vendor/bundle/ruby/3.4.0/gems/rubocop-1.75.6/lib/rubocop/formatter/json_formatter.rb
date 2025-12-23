# frozen_string_literal: true

require 'json'

module RuboCop
  module Formatter
    # This formatter formats the report data in JSON format.
    class JSONFormatter < BaseFormatter
      include PathUtil

      attr_reader :output_hash

      def initialize(output, options = {})
        super
        @output_hash = { metadata: metadata_hash, files: [], summary: { offense_count: 0 } }
      end

      def started(target_files)
        output_hash[:summary][:target_file_count] = target_files.count
      end

      def file_finished(file, offenses)
        output_hash[:files] << hash_for_file(file, offenses)
        output_hash[:summary][:offense_count] += offenses.count
      end

      def finished(inspected_files)
        output_hash[:summary][:inspected_file_count] = inspected_files.count
        output.write output_hash.to_json
      end

      def metadata_hash
        {
          rubocop_version: RuboCop::Version::STRING,
          ruby_engine:     RUBY_ENGINE,
          ruby_version:    RUBY_VERSION,
          ruby_patchlevel: RUBY_PATCHLEVEL.to_s,
          ruby_platform:   RUBY_PLATFORM
        }
      end

      def hash_for_file(file, offenses)
        {
          path:     smart_path(file),
          offenses: offenses.map { |o| hash_for_offense(o) }
        }
      end

      def hash_for_offense(offense)
        {
          severity:    offense.severity.name,
          message:     offense.message,
          cop_name:    offense.cop_name,
          corrected:   offense.corrected?,
          correctable: offense.correctable?,
          location:    hash_for_location(offense)
        }
      end

      # TODO: Consider better solution for Offense#real_column.
      #       The minimum value of `start_column: real_column` is 1.
      #       So, the minimum value of `last_column` should be 1.
      #       And non-zero value of `last_column` should be used as is.
      def hash_for_location(offense)
        {
          start_line:   offense.line,
          start_column: offense.real_column,
          last_line:    offense.last_line,
          last_column:  offense.last_column.zero? ? 1 : offense.last_column,
          length:       offense.location.length,
          # `line` and `column` exist for compatibility.
          # Use `start_line` and `start_column` instead.
          line:         offense.line,
          column:       offense.real_column
        }
      end
    end
  end
end
