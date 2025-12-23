# coding: utf-8

class HighLine
  class Terminal
    # HighLine::Terminal option that uses external "stty" program
    # to control terminal options.
    class UnixStty < Terminal
      # A Unix savvy method using stty to fetch the console columns, and rows.
      # ... stty does not work in JRuby
      # @return (see Terminal#terminal_size)
      def terminal_size
        begin
          require "io/console"
          winsize = begin
                      IO.console.winsize.reverse
                    rescue NoMethodError
                      nil
                    end
          return winsize if winsize
        rescue LoadError
        end

        if /solaris/ =~ RUBY_PLATFORM &&
           `stty` =~ /\brows = (\d+).*\bcolumns = (\d+)/
          [Regexp.last_match(2), Regexp.last_match(1)].map(&:to_i)
        elsif `stty size` =~ /^(\d+)\s(\d+)$/
          [Regexp.last_match(2).to_i, Regexp.last_match(1).to_i]
        else
          [80, 24]
        end
      end

      # (see Terminal#raw_no_echo_mode)
      def raw_no_echo_mode
        @state = `stty -g`
        system "stty raw -echo -icanon isig"
      end

      # (see Terminal#restore_mode)
      def restore_mode
        system "stty #{@state}"
        print "\r"
      end

      # (see Terminal#get_character)
      def get_character(input = STDIN)
        input.getc
      end
    end
  end
end
