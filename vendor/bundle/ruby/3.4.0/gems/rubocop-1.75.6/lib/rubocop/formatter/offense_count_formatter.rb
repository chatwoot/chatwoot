# frozen_string_literal: true

require 'ruby-progressbar'

module RuboCop
  module Formatter
    # This formatter displays the list of offended cops with a count of how
    # many offenses of their kind were found. Ordered by desc offense count
    #
    # Here's the format:
    #
    # 26  LineLength
    # 3   OneLineConditional
    # --
    # 29  Total in 5 files
    class OffenseCountFormatter < BaseFormatter
      attr_reader :offense_counts

      def started(target_files)
        super
        @offense_counts = Hash.new(0)
        @offending_files_count = 0
        @style_guide_links = {}

        return unless output.tty?

        file_phrase = target_files.count == 1 ? 'file' : 'files'

        # 185/407 files |====== 45 ======>                    |  ETA: 00:00:04
        # %c / %C       |       %w       >         %i         |       %e
        bar_format = " %c/%C #{file_phrase} |%w>%i| %e "

        @progressbar = ProgressBar.create(
          output: output,
          total: target_files.count,
          format: bar_format,
          autostart: false
        )
        @progressbar.start
      end

      def file_finished(_file, offenses)
        offenses.each { |o| @offense_counts[o.cop_name] += 1 }
        if options[:display_style_guide]
          offenses.each { |o| @style_guide_links[o.cop_name] ||= o.message[/ \(http\S+\)\Z/] }
        end
        @offending_files_count += 1 unless offenses.empty?
        @progressbar.increment if instance_variable_defined?(:@progressbar)
      end

      def finished(_inspected_files)
        report_summary(@offense_counts, @offending_files_count)
      end

      # rubocop:disable Metrics/AbcSize
      def report_summary(offense_counts, offending_files_count)
        per_cop_counts = ordered_offense_counts(offense_counts)
        total_count = total_offense_count(offense_counts)

        output.puts

        column_width = total_count.to_s.length + 2
        per_cop_counts.each do |cop_name, count|
          output.puts "#{count.to_s.ljust(column_width)}#{cop_information(cop_name)}"
        end
        output.puts '--'
        output.puts "#{total_count}  Total in #{offending_files_count} files"

        output.puts
      end
      # rubocop:enable Metrics/AbcSize

      def ordered_offense_counts(offense_counts)
        offense_counts.sort_by { |k, v| [-v, k] }.to_h
      end

      def total_offense_count(offense_counts)
        offense_counts.values.sum
      end

      def cop_information(cop_name)
        cop = RuboCop::Cop::Registry.global.find_by_cop_name(cop_name).new

        if cop.correctable?
          safety = cop.safe_autocorrect? ? 'Safe' : 'Unsafe'
          correctable = Rainbow(" [#{safety} Correctable]").yellow
        end

        "#{cop_name}#{correctable}#{@style_guide_links[cop_name]}"
      end
    end
  end
end
