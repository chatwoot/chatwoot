require 'optparse'

module Sass::Exec
  # The abstract base class for Sass executables.
  class Base
    # @param args [Array<String>] The command-line arguments
    def initialize(args)
      @args = args
      @options = {}
    end

    # Parses the command-line arguments and runs the executable.
    # Calls `Kernel#exit` at the end, so it never returns.
    #
    # @see #parse
    def parse!
      begin
        parse
      rescue Exception => e
        # Exit code 65 indicates invalid data per
        # http://www.freebsd.org/cgi/man.cgi?query=sysexits. Setting it via
        # at_exit is a bit of a hack, but it allows us to rethrow when --trace
        # is active and get both the built-in exception formatting and the
        # correct exit code.
        at_exit {exit Sass::Util.windows? ? 13 : 65} if e.is_a?(Sass::SyntaxError)

        raise e if @options[:trace] || e.is_a?(SystemExit)

        if e.is_a?(Sass::SyntaxError)
          $stderr.puts e.sass_backtrace_str("standard input")
        else
          $stderr.print "#{e.class}: " unless e.class == RuntimeError
          $stderr.puts e.message.to_s
        end
        $stderr.puts "  Use --trace for backtrace."

        exit 1
      end
      exit 0
    end

    # Parses the command-line arguments and runs the executable.
    # This does not handle exceptions or exit the program.
    #
    # @see #parse!
    def parse
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)

      process_result

      @options
    end

    # @return [String] A description of the executable
    def to_s
      @opts.to_s
    end

    protected

    # Finds the line of the source template
    # on which an exception was raised.
    #
    # @param exception [Exception] The exception
    # @return [String] The line number
    def get_line(exception)
      # SyntaxErrors have weird line reporting
      # when there's trailing whitespace
      if exception.is_a?(::SyntaxError)
        return (exception.message.scan(/:(\d+)/).first || ["??"]).first
      end
      (exception.backtrace[0].scan(/:(\d+)/).first || ["??"]).first
    end

    # Tells optparse how to parse the arguments
    # available for all executables.
    #
    # This is meant to be overridden by subclasses
    # so they can add their own options.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      Sass::Util.abstract(this)
    end

    # Set an option for specifying `Encoding.default_external`.
    #
    # @param opts [OptionParser]
    def encoding_option(opts)
      encoding_desc = 'Specify the default encoding for input files.'
      opts.on('-E', '--default-encoding ENCODING', encoding_desc) do |encoding|
        Encoding.default_external = encoding
      end
    end

    # Processes the options set by the command-line arguments. In particular,
    # sets `@options[:input]` and `@options[:output]` to appropriate IO streams.
    #
    # This is meant to be overridden by subclasses
    # so they can run their respective programs.
    def process_result
      input, output = @options[:input], @options[:output]
      args = @args.dup
      input ||=
        begin
          filename = args.shift
          @options[:filename] = filename
          open_file(filename) || $stdin
        end
      @options[:output_filename] = args.shift
      output ||= @options[:output_filename] || $stdout
      @options[:input], @options[:output] = input, output
    end

    COLORS = {:red => 31, :green => 32, :yellow => 33}

    # Prints a status message about performing the given action,
    # colored using the given color (via terminal escapes) if possible.
    #
    # @param name [#to_s] A short name for the action being performed.
    #   Shouldn't be longer than 11 characters.
    # @param color [Symbol] The name of the color to use for this action.
    #   Can be `:red`, `:green`, or `:yellow`.
    def puts_action(name, color, arg)
      return if @options[:for_engine][:quiet]
      printf color(color, "%11s %s\n"), name, arg
      STDOUT.flush
    end

    # Same as `Kernel.puts`, but doesn't print anything if the `--quiet` option is set.
    #
    # @param args [Array] Passed on to `Kernel.puts`
    def puts(*args)
      return if @options[:for_engine][:quiet]
      Kernel.puts(*args)
    end

    # Wraps the given string in terminal escapes
    # causing it to have the given color.
    # If terminal escapes aren't supported on this platform,
    # just returns the string instead.
    #
    # @param color [Symbol] The name of the color to use.
    #   Can be `:red`, `:green`, or `:yellow`.
    # @param str [String] The string to wrap in the given color.
    # @return [String] The wrapped string.
    def color(color, str)
      raise "[BUG] Unrecognized color #{color}" unless COLORS[color]

      # Almost any real Unix terminal will support color,
      # so we just filter for Windows terms (which don't set TERM)
      # and not-real terminals, which aren't ttys.
      return str if ENV["TERM"].nil? || ENV["TERM"].empty? || !STDOUT.tty?
      "\e[#{COLORS[color]}m#{str}\e[0m"
    end

    def write_output(text, destination)
      if destination.is_a?(String)
        open_file(destination, 'w') {|file| file.write(text)}
      else
        destination.write(text)
      end
    end

    private

    def open_file(filename, flag = 'r')
      return if filename.nil?
      flag = 'wb' if @options[:unix_newlines] && flag == 'w'
      file = File.open(filename, flag)
      return file unless block_given?
      yield file
      file.close
    end

    def handle_load_error(err)
      dep = err.message[/^no such file to load -- (.*)/, 1]
      raise err if @options[:trace] || dep.nil? || dep.empty?
      $stderr.puts <<MESSAGE
Required dependency #{dep} not found!
    Run "gem install #{dep}" to get it.
  Use --trace for backtrace.
MESSAGE
      exit 1
    end
  end
end
