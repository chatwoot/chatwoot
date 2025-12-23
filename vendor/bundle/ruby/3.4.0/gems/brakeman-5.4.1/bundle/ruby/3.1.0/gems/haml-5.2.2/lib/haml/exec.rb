# frozen_string_literal: true

require 'optparse'
require 'rbconfig'
require 'pp'

module Haml
  # This module handles the various Haml executables (`haml` and `haml-convert`).
  module Exec
    # An abstract class that encapsulates the executable code for all three executables.
    class Generic
      # @param args [Array<String>] The command-line arguments
      def initialize(args)
        @args = args
        @options = {:for_engine => {}}
      end

      # Parses the command-line arguments and runs the executable.
      # Calls `Kernel#exit` at the end, so it never returns.
      #
      # @see #parse
      def parse!
        begin
          parse
        rescue Exception => e
          raise e if @options[:trace] || e.is_a?(SystemExit)

          $stderr.print "#{e.class}: " unless e.class == RuntimeError
          $stderr.puts "#{e.message}"
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
        # when there's trailing whitespace,
        # which there is for Haml documents.
        return (exception.message.scan(/:(\d+)/).first || ["??"]).first if exception.is_a?(::SyntaxError)
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
        opts.on('-s', '--stdin', :NONE, 'Read input from standard input instead of an input file') do
          @options[:input] = $stdin
        end

        opts.on('--trace', :NONE, 'Show a full traceback on error') do
          @options[:trace] = true
        end

        opts.on('--unix-newlines', 'Use Unix-style newlines in written files.') do
          # Note that this is the preferred way to check for Windows, since
          # JRuby and Rubinius also run there.
          if RbConfig::CONFIG['host_os'] =~ /mswin|windows|mingw/i
            @options[:unix_newlines] = true
          end
        end

        opts.on_tail("-?", "-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print version") do
          puts("Haml #{::Haml::VERSION}")
          exit
        end
      end

      # Processes the options set by the command-line arguments.
      # In particular, sets `@options[:input]` and `@options[:output]`
      # to appropriate IO streams.
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
        output ||= open_file(args.shift, 'w') || $stdout

        @options[:input], @options[:output] = input, output
      end

      COLORS = {red: 31, green: 32, yellow: 33}.freeze

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
      # If terminal esapes aren't supported on this platform,
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
        return "\e[#{COLORS[color]}m#{str}\e[0m"
      end

      private

      def open_file(filename, flag = 'r')
        return if filename.nil?
        flag = 'wb' if @options[:unix_newlines] && flag == 'w'
        File.open(filename, flag)
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

    # The `haml` executable.
    class Haml < Generic
      # @param args [Array<String>] The command-line arguments
      def initialize(args)
        super
        @options[:for_engine] = {}
        @options[:requires] = []
        @options[:load_paths] = []
      end

      # Tells optparse how to parse the arguments.
      #
      # @param opts [OptionParser]
      def set_opts(opts)
        super

        opts.banner = <<END
Usage: haml [options] [INPUT] [OUTPUT]

Description:
  Converts Haml files to HTML.

Options:
END

        opts.on('-c', '--check', "Just check syntax, don't evaluate.") do
          require 'stringio'
          @options[:check_syntax] = true
          @options[:output] = StringIO.new
        end

        opts.on('-f', '--format NAME',
                'Output format. Can be html5 (default), xhtml, or html4.') do |name|
          @options[:for_engine][:format] = name.to_sym
        end

        opts.on('-e', '--escape-html',
                'Escape HTML characters (like ampersands and angle brackets) by default.') do
          @options[:for_engine][:escape_html] = true
        end

        opts.on('--no-escape-attrs',
                "Don't escape HTML characters (like ampersands and angle brackets) in attributes.") do
          @options[:for_engine][:escape_attrs] = false
        end

        opts.on('-q', '--double-quote-attributes',
                'Set attribute wrapper to double-quotes (default is single).') do
          @options[:for_engine][:attr_wrapper] = '"'
        end

        opts.on('--remove-whitespace',
                'Remove whitespace surrounding and within tags') do
          @options[:for_engine][:remove_whitespace] = true
        end

        opts.on('--cdata',
                'Always add CDATA sections to javascript and css blocks.') do
          @options[:for_engine][:cdata] = true
        end

        opts.on('--autoclose LIST',
                'Comma separated list of elements to be automatically self-closed.') do |list|
          @options[:for_engine][:autoclose] = list.split(',')
        end

        opts.on('--suppress-eval',
                'Don\'t evaluate Ruby scripts.') do
          @options[:for_engine][:suppress_eval] = true
        end

        opts.on('-r', '--require FILE', "Same as 'ruby -r'.") do |file|
          @options[:requires] << file
        end

        opts.on('-I', '--load-path PATH', "Same as 'ruby -I'.") do |path|
          @options[:load_paths] << path
        end

        opts.on('-E ex[:in]', 'Specify the default external and internal character encodings.') do |encoding|
          external, internal = encoding.split(':')
          Encoding.default_external = external if external && !external.empty?
          Encoding.default_internal = internal if internal && !internal.empty?
        end

        opts.on('-d', '--debug', "Print out the precompiled Ruby source, and show syntax errors in the Ruby code.") do
          @options[:debug] = true
        end

        opts.on('-p', '--parse', "Print out Haml parse tree.") do
          @options[:parse] = true
        end

      end

      # Processes the options set by the command-line arguments,
      # and runs the Haml compiler appropriately.
      def process_result
        super
        @options[:for_engine][:filename] = @options[:filename]
        input = @options[:input]
        output = @options[:output]

        template = input.read()
        input.close() if input.is_a? File

        @options[:load_paths].each {|p| $LOAD_PATH << p}
        @options[:requires].each {|f| require f}

        begin

          if @options[:parse]
            parser = ::Haml::Parser.new(::Haml::Options.new(@options))
            pp parser.call(template)
            return
          end

          engine = ::Haml::Engine.new(template, @options[:for_engine])

          if @options[:check_syntax]
            error = validate_ruby(engine.precompiled)
            if error
              puts error.message.split("\n").first
              exit 1
            end
            puts "Syntax OK"
            return
          end

          if @options[:debug]
            puts engine.precompiled
            error = validate_ruby(engine.precompiled)
            if error
              puts '=' * 100
              puts error.message.split("\n")[0]
              exit 1
            end
            return
          end

          result = engine.to_html
        rescue Exception => e
          raise e if @options[:trace]

          case e
          when ::Haml::SyntaxError; raise "Syntax error on line #{get_line e}: #{e.message}"
          when ::Haml::Error;       raise "Haml error on line #{get_line e}: #{e.message}"
          else raise "Exception on line #{get_line e}: #{e.message}"
          end
        end

        output.write(result)
        output.close() if output.is_a? File
      end

      def validate_ruby(code)
        eval("BEGIN {return nil}; #{code}", binding, @options[:filename] || "")
      rescue ::SyntaxError # Not to be confused with Haml::SyntaxError
        $!
      end
    end
  end
end
