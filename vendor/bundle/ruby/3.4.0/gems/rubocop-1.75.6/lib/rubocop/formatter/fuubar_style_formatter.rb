# frozen_string_literal: true

require 'ruby-progressbar'

module RuboCop
  module Formatter
    # This formatter displays a progress bar and shows details of offenses as
    # soon as they are detected.
    # This is inspired by the Fuubar formatter for RSpec by Jeff Kreeftmeijer.
    # https://github.com/jeffkreeftmeijer/fuubar
    class FuubarStyleFormatter < ClangStyleFormatter
      RESET_SEQUENCE = "\e[0m"

      def initialize(*output)
        @severest_offense = nil

        super
      end

      def started(target_files)
        super

        @severest_offense = nil

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
        with_color { @progressbar.start }
      end

      def file_finished(file, offenses)
        count_stats(offenses)

        unless offenses.empty?
          @progressbar.clear
          report_file(file, offenses)
        end

        with_color { @progressbar.increment }
      end

      def count_stats(offenses)
        super

        offenses = offenses.reject(&:corrected?)
        return if offenses.empty?

        offenses << @severest_offense if @severest_offense
        @severest_offense = offenses.max_by(&:severity)
      end

      def with_color
        if rainbow.enabled
          output.write colorize('', progressbar_color).chomp(RESET_SEQUENCE)
          yield
          output.write RESET_SEQUENCE
        else
          yield
        end
      end

      def progressbar_color
        if @severest_offense
          COLOR_FOR_SEVERITY[@severest_offense.severity.name]
        else
          :green
        end
      end
    end
  end
end
