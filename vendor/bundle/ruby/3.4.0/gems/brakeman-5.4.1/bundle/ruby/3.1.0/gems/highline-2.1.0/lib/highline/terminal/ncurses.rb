# coding: utf-8

class HighLine
  class Terminal
    # NCurses HighLine::Terminal
    # @note Code migrated +UNTESTED+ from the old code base to the new
    # terminal api.
    class NCurses < Terminal
      require "ffi-ncurses"

      # (see Terminal#raw_no_echo_mode)
      def raw_no_echo_mode
        FFI::NCurses.initscr
        FFI::NCurses.cbreak
      end

      # (see Terminal#restore_mode)
      def restore_mode
        FFI::NCurses.endwin
      end

      #
      # (see Terminal#terminal_size)
      # A ncurses savvy method to fetch the console columns, and rows.
      #
      def terminal_size
        size = [80, 40]
        FFI::NCurses.initscr
        begin
          size = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr).reverse
        ensure
          FFI::NCurses.endwin
        end
        size
      end
    end
  end
end
