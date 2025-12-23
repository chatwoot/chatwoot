# frozen_string_literal: true

class Pry
  class Output
    # @return [Array<Integer>] default terminal screen size [rows, cols]
    DEFAULT_SIZE = [27, 80].freeze

    attr_reader :pry_instance

    def initialize(pry_instance)
      @output = pry_instance.config.output
      @color = pry_instance.config.color
    end

    def puts(*objs)
      return print "\n" if objs.empty?

      objs.each do |obj|
        if (ary = Array.try_convert(obj))
          puts(*ary)
        else
          print "#{obj.to_s.chomp}\n"
        end
      end
      nil
    end

    def print(*objs)
      objs.each do |obj|
        @output.print decolorize_maybe(obj.to_s)
      end
      nil
    end
    alias << print
    alias write print

    def tty?
      @output.respond_to?(:tty?) && @output.tty?
    end

    def method_missing(method_name, *args, &block)
      if @output.respond_to?(method_name)
        @output.__send__(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @output.respond_to?(method_name, include_private)
    end

    def decolorize_maybe(str)
      return str if @color

      Pry::Helpers::Text.strip_color(str)
    end

    # @return [Array<Integer>] a pair of [rows, columns] which gives the size of
    #   the window. If the window size cannot be determined, the default value.
    def size
      rows, cols = actual_screen_size
      return [rows.to_i, cols.to_i] if rows.to_i != 0 && cols.to_i != 0

      DEFAULT_SIZE
    end

    # Return a screen width or the default if that fails.
    def width
      size.last
    end

    # Return a screen height or the default if that fails.
    def height
      size.first
    end

    private

    def actual_screen_size
      # The best way, if possible (requires non-jruby >=1.9 or io-console gem).
      io_console_size ||
        # Fall back to the old standby, though it might be stale.
        env_size ||
        # Fall further back, though this one is also out of date without
        # something calling Readline.set_screen_size.
        readline_size ||
        # Windows users can otherwise run ansicon and get a decent answer.
        ansicon_env_size
    end

    def io_console_size
      return if Pry::Helpers::Platform.jruby?

      begin
        require 'io/console'

        begin
          @output.winsize if tty? && @output.respond_to?(:winsize)
        rescue Errno::EOPNOTSUPP # rubocop:disable Lint/HandleExceptions
          # Output is probably a socket, which doesn't support #winsize.
        end
      rescue LoadError # rubocop:disable Lint/HandleExceptions
        # They probably don't have the io/console stdlib or the io-console gem.
        # We'll keep trying.
      end
    end

    def env_size
      size = [Pry::Env['LINES'] || Pry::Env['ROWS'], Pry::Env['COLUMNS']]
      size if nonzero_column?(size)
    end

    def readline_size
      return unless defined?(Readline) && Readline.respond_to?(:get_screen_size)

      size = Readline.get_screen_size
      size if nonzero_column?(size)
    rescue Java::JavaLang::NullPointerException
      # This rescue won't happen on jrubies later than:
      #     https://github.com/jruby/jruby/pull/436
      nil
    end

    def ansicon_env_size
      return unless Pry::Env['ANSICON'] =~ /\((.*)x(.*)\)/

      size = [Regexp.last_match(2), Regexp.last_match(1)]
      size if nonzero_column?(size)
    end

    def nonzero_column?(size)
      size[1].to_i > 0
    end
  end
end
