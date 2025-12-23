# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter prints a PACDOT per every file to be analyzed.
    # Pacman will "eat" one PACDOT per file when no offense is detected.
    # Otherwise it will print a Ghost.
    # This is inspired by the Pacman formatter for RSpec by Carlos Rojas.
    # https://github.com/go-labs/rspec_pacman_formatter
    class PacmanFormatter < ClangStyleFormatter
      include TextUtil
      attr_accessor :progress_line

      FALLBACK_TERMINAL_WIDTH = 80
      GHOST = 'ᗣ'
      PACMAN = Rainbow('ᗧ').yellow.bright
      PACDOT = Rainbow('•').yellow.bright

      def initialize(output, options = {})
        super
        @progress_line = ''
        @total_files   = 0
        @repetitions   = 0
      end

      def started(target_files)
        super
        @total_files = target_files.size
        output.puts "Eating #{pluralize(target_files.size, 'file')}"
        update_progress_line
      end

      def file_started(_file, _options)
        step(PACMAN)
      end

      def file_finished(file, offenses)
        count_stats(offenses) unless offenses.empty?
        next_step(offenses)
        report_file(file, offenses)
      end

      def next_step(offenses)
        return step('.') if offenses.empty?

        ghost_color = COLOR_FOR_SEVERITY[offenses.last.severity.name]
        step(colorize(GHOST, ghost_color))
      end

      def cols
        @cols ||= begin
          _height, width = $stdout.winsize
          width.nil? || width.zero? ? FALLBACK_TERMINAL_WIDTH : width
        end
      end

      def update_progress_line
        return pacdots(@total_files) unless @total_files > cols
        return pacdots(cols) unless (@total_files / cols).eql?(@repetitions)

        pacdots(@total_files - (cols * @repetitions))
      end

      def pacdots(number)
        @progress_line = PACDOT * number
      end

      def step(character)
        regex = /#{Regexp.quote(PACMAN)}|#{Regexp.quote(PACDOT)}/
        @progress_line = @progress_line.sub(regex, character)
        output.printf("%<line>s\r", line: @progress_line)
        return unless /ᗣ|\./.match?(@progress_line[-1])

        @repetitions += 1
        output.puts
        update_progress_line
      end
    end
  end
end
