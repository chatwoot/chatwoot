require 'slim'
require 'optparse'

module Slim
  Engine.set_options pretty: false

  # Slim commandline interface
  # @api private
  class Command
    def initialize(args)
      @args = args
      @options = {}
    end

    # Run command
    def run
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)
      process
    end

    private

    # Configure OptionParser
    def set_opts(opts)
      opts.on('-s', '--stdin', 'Read input from standard input instead of an input file') do
        @options[:input] = $stdin
      end

      opts.on('--trace', 'Show a full traceback on error') do
        @options[:trace] = true
      end

      opts.on('-c', '--compile', 'Compile only but do not run') do
        @options[:compile] = true
      end

      opts.on('-e', '--erb', 'Convert to ERB') do
        @options[:erb] = true
      end

      opts.on('--rails', 'Generate rails compatible code (Implies --compile)') do
        Engine.set_options disable_capture: true, generator: Temple::Generators::RailsOutputBuffer
        @options[:compile] = true
      end

      opts.on('-r', '--require library', "Load library or plugin with -r slim/plugin") do |lib|
        require lib.strip
      end

      opts.on('-p', '--pretty', 'Produce pretty html') do
        Engine.set_options pretty: true
      end

      opts.on('-o', '--option name=code', String, 'Set slim option') do |str|
        parts = str.split('=', 2)
        Engine.options[parts.first.gsub(/\A:/, '').to_sym] = eval(parts.last)
      end

      opts.on('-l', '--locals Hash|YAML|JSON', String, 'Set local variables') do |locals|
        @options[:locals] =
          if locals =~ /\A\s*\{\s*\p{Word}+:/
            eval(locals)
          else
            require 'yaml'
            if RUBY_ENGINE == 'rbx'
              begin
                require 'psych'
              rescue LoadError
                $stderr.puts 'Please install psych gem as Rubunius ships with an old YAML engine.'
              end
            end
            YAML.load(locals)
          end
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Print version') do
        puts "Slim #{VERSION}"
        exit
      end
    end

    # Process command
    def process
      args = @args.dup
      unless @options[:input]
        file = args.shift
        if file
          @options[:file] = file
          @options[:input] = File.open(file, 'r')
        else
          @options[:file] = 'STDIN'
          @options[:input] = $stdin
        end
      end

      locals = @options.delete(:locals) || {}
      result =
        if @options[:erb]
          require 'slim/erb_converter'
          ERBConverter.new(file: @options[:file]).call(@options[:input].read)
        elsif @options[:compile]
          Engine.new(file: @options[:file]).call(@options[:input].read)
        else
          Template.new(@options[:file]) { @options[:input].read }.render(nil, locals)
        end

    rescue Exception => ex
      raise ex if @options[:trace] || SystemExit === ex
      $stderr.print "#{ex.class}: " if ex.class != RuntimeError
      $stderr.puts ex.message
      $stderr.puts '  Use --trace for backtrace.'
      exit 1
    else
      unless @options[:output]
        file = args.shift
        @options[:output] = file ? File.open(file, 'w') : $stdout
      end
      @options[:output].puts(result)
      exit 0
    end
  end
end
