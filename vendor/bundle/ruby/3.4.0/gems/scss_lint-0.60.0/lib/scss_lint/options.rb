require 'optparse'

module SCSSLint
  # Handles option parsing for the command line application.
  class Options
    DEFAULT_REPORTER = ['Default', :stdout].freeze

    # Parses command line options into an options hash.
    #
    # @param args [Array<String>] arguments passed via the command line
    # @return [Hash] parsed options
    def parse(args)
      @options = {
        reporters: [DEFAULT_REPORTER],
      }

      OptionParser.new do |parser|
        parser.banner = "Usage: #{parser.program_name} [options] [scss-files]"

        add_display_options parser
        add_linter_options parser
        add_file_options parser
        add_info_options parser
      end.parse!(args)

      # Any remaining arguments are assumed to be files
      @options[:files] = args

      @options
    rescue OptionParser::InvalidOption => e
      raise SCSSLint::Exceptions::InvalidCLIOption,
            e.message,
            e.backtrace
    end

  private

    def add_display_options(parser)
      parser.on('-f', '--format Formatter', 'Specify how to display lints', String) do |format|
        define_output_format(format)
      end

      parser.on('-r', '--require path', 'Require Ruby file', String) do |path|
        @options[:required_paths] ||= []
        @options[:required_paths] << path
      end
    end

    # @param format [String]
    def define_output_format(format)
      return if @options[:reporters] == [DEFAULT_REPORTER] && format == 'Default'

      @options[:reporters].reject! { |i| i == DEFAULT_REPORTER }
      @options[:reporters] << [format, :stdout]
    end

    def add_linter_options(parser)
      parser.on('-i', '--include-linter linter,...', Array,
                'Specify which linters you want to run') do |linters|
        @options[:included_linters] = linters
      end

      parser.on('-x', '--exclude-linter linter,...', Array,
                "Specify which linters you don't want to run") do |linters|
        @options[:excluded_linters] = linters
      end
    end

    def add_file_options(parser)
      parser.on('-c', '--config config-file', String,
                'Specify which configuration file you want to use') do |conf_file|
        @options[:config_file] = conf_file
      end

      parser.on('-e', '--exclude file,...', Array,
                'List of file names to exclude') do |files|
        @options[:excluded_files] = files
      end

      parser.on('--stdin-file-path file-path', String,
                'Specify the path to assume for the file passed via STDIN') do |stdin_file_path|
        @options[:stdin_file_path] = stdin_file_path
      end

      parser.on('-o', '--out path', 'Write output to a file instead of STDOUT', String) do |path|
        define_output_path(path)
      end
    end

    # @param path [String]
    def define_output_path(path)
      last_reporter, _output = @options[:reporters].pop
      @options[:reporters] << [last_reporter, path]
    end

    def add_info_options(parser)
      parser.on_tail('--show-formatters', 'Shows available formatters') do
        @options[:show_formatters] = true
      end

      parser.on_tail('--show-linters', 'Display available linters') do
        @options[:show_linters] = true
      end

      parser.on('--[no-]color', 'Force output to be colorized') do |color|
        @options[:color] = color
      end

      parser.on_tail('-h', '--help', 'Display help documentation') do
        @options[:help] = parser.help
      end

      parser.on_tail('-v', '--version', 'Display version') do
        @options[:version] = true
      end
    end
  end
end
