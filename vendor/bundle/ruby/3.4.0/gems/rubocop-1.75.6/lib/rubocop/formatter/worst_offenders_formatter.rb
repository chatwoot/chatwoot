# frozen_string_literal: true

require 'pathname'

module RuboCop
  module Formatter
    # This formatter displays the list of offensive files, sorted by number of
    # offenses with the worst offenders first.
    #
    # Here's the format:
    #
    # 26  this/file/is/really/bad.rb
    # 3   just/ok.rb
    # --
    # 29  Total in 2 files
    class WorstOffendersFormatter < BaseFormatter
      attr_reader :offense_counts

      def started(target_files)
        super
        @offense_counts = {}
      end

      def file_finished(file, offenses)
        return if offenses.empty?

        path = Pathname.new(file).relative_path_from(Pathname.new(Dir.pwd))
        @offense_counts[path] = offenses.size
      end

      def finished(_inspected_files)
        report_summary(@offense_counts)
      end

      # rubocop:disable Metrics/AbcSize
      def report_summary(offense_counts)
        per_file_counts = ordered_offense_counts(offense_counts)
        total_count = total_offense_count(offense_counts)
        file_count = per_file_counts.size

        output.puts

        column_width = total_count.to_s.length + 2
        per_file_counts.each do |file_name, count|
          output.puts "#{count.to_s.ljust(column_width)}#{file_name}\n"
        end

        output.puts '--'
        output.puts "#{total_count}  Total in #{file_count} files"

        output.puts
      end
      # rubocop:enable Metrics/AbcSize

      def ordered_offense_counts(offense_counts)
        offense_counts.sort_by { |k, v| [-v, k] }.to_h
      end

      def total_offense_count(offense_counts)
        offense_counts.values.sum
      end
    end
  end
end
