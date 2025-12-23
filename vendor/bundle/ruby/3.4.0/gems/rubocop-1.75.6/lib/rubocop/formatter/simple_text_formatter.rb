# frozen_string_literal: true

require_relative 'colorizable'

module RuboCop
  module Formatter
    # A basic formatter that displays only files with offenses.
    # Offenses are displayed at compact form - just the
    # location of the problem and the associated message.
    class SimpleTextFormatter < BaseFormatter
      include Colorizable
      include PathUtil

      COLOR_FOR_SEVERITY = {
        info:       :gray,
        refactor:   :yellow,
        convention: :yellow,
        warning:    :magenta,
        error:      :red,
        fatal:      :red
      }.freeze

      def started(_target_files)
        @total_offense_count = 0
        @total_correction_count = 0
        @total_correctable_count = 0
      end

      def file_finished(file, offenses)
        return if offenses.empty?

        count_stats(offenses)
        report_file(file, offenses)
      end

      def finished(inspected_files)
        report_summary(inspected_files.count,
                       @total_offense_count,
                       @total_correction_count,
                       @total_correctable_count)
      end

      def report_file(file, offenses)
        output.puts yellow("== #{smart_path(file)} ==")

        offenses.each do |o|
          output.printf(
            "%<severity>s:%3<line>d:%3<column>d: %<message>s\n",
            severity: colored_severity_code(o),
            line: o.line,
            column: o.real_column,
            message: message(o)
          )
        end
      end

      def report_summary(file_count, offense_count, correction_count, correctable_count)
        report = Report.new(file_count,
                            offense_count,
                            correction_count,
                            correctable_count,
                            rainbow,
                            # :safe_autocorrect is a derived option based on several command-line
                            # arguments - see RuboCop::Options#add_autocorrection_options
                            safe_autocorrect: @options[:safe_autocorrect])

        output.puts
        output.puts report.summary
      end

      private

      def count_stats(offenses)
        @total_offense_count += offenses.count
        corrected = offenses.count(&:corrected?)
        @total_correction_count += corrected
        @total_correctable_count += offenses.count(&:correctable?) - corrected
      end

      def colored_severity_code(offense)
        color = COLOR_FOR_SEVERITY.fetch(offense.severity.name)
        colorize(offense.severity.code, color)
      end

      def annotate_message(msg)
        msg.gsub(/`(.*?)`/m, yellow('\1'))
      end

      def message(offense)
        message =
          if offense.corrected_with_todo?
            green('[Todo] ')
          elsif offense.corrected?
            green('[Corrected] ')
          elsif offense.correctable?
            yellow('[Correctable] ')
          else
            ''
          end

        "#{message}#{annotate_message(offense.message)}"
      end

      # A helper class for building the report summary text.
      class Report
        include Colorizable
        include TextUtil

        # rubocop:disable Metrics/ParameterLists
        def initialize(
          file_count, offense_count, correction_count, correctable_count, rainbow,
          safe_autocorrect: false
        )
          @file_count = file_count
          @offense_count = offense_count
          @correction_count = correction_count
          @correctable_count = correctable_count
          @rainbow = rainbow
          @safe_autocorrect = safe_autocorrect
        end
        # rubocop:enable Metrics/ParameterLists

        def summary
          if @correction_count.positive?
            if @correctable_count.positive?
              "#{files} inspected, #{offenses} detected, #{corrections} corrected, " \
                "#{correctable}"
            else
              "#{files} inspected, #{offenses} detected, #{corrections} corrected"
            end
          elsif @correctable_count.positive?
            "#{files} inspected, #{offenses} detected, #{correctable}"
          else
            "#{files} inspected, #{offenses} detected"
          end
        end

        private

        attr_reader :rainbow

        def files
          pluralize(@file_count, 'file')
        end

        def offenses
          text = pluralize(@offense_count, 'offense', no_for_zero: true)
          color = @offense_count.zero? ? :green : :red

          colorize(text, color)
        end

        def corrections
          text = pluralize(@correction_count, 'offense')
          color = @correction_count == @offense_count ? :green : :cyan

          colorize(text, color)
        end

        def correctable
          if @safe_autocorrect
            text = pluralize(@correctable_count, 'more offense')
            "#{colorize(text, :yellow)} can be corrected with `rubocop -A`"
          else
            text = pluralize(@correctable_count, 'offense')
            "#{colorize(text, :yellow)} autocorrectable"
          end
        end
      end
    end
  end
end
