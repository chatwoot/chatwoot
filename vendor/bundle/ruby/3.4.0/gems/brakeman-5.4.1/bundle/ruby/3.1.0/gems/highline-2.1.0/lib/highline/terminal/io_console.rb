# frozen_string_literal: true

class HighLine
  class Terminal
    # io/console option for HighLine::Terminal.
    # It's the most used terminal.
    # TODO: We're rescuing when not a terminal.
    #       We should make a more robust implementation.
    class IOConsole < Terminal
      # (see Terminal#terminal_size)
      def terminal_size
        output.winsize.reverse
      rescue Errno::ENOTTY
      end

      # (see Terminal#raw_no_echo_mode)
      def raw_no_echo_mode
        input.echo = false
      rescue Errno::ENOTTY
      end

      # (see Terminal#restore_mode)
      def restore_mode
        input.echo = true
      rescue Errno::ENOTTY
      end

      # (see Terminal#get_character)
      def get_character
        input.getch # from ruby io/console
      rescue Errno::ENOTTY
        input.getc
      end
    end
  end
end
