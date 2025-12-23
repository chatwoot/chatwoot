require 'optparse'
require 'fileutils'

module Sass::Exec
  # The `sass-convert` executable.
  class SassConvert < Base
    # @param args [Array<String>] The command-line arguments
    def initialize(args)
      super
      require 'sass'
      @options[:for_tree] = {}
      @options[:for_engine] = {:cache => false, :read_cache => true}
    end

    # Tells optparse how to parse the arguments.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      opts.banner = <<END
Usage: sass-convert [options] [INPUT] [OUTPUT]

Description:
  Converts between CSS, indented syntax, and SCSS files. For example,
  this can convert from the indented syntax to SCSS, or from CSS to
  SCSS (adding appropriate nesting).
END

      common_options(opts)
      style(opts)
      input_and_output(opts)
      miscellaneous(opts)
    end

    # Processes the options set by the command-line arguments,
    # and runs the CSS compiler appropriately.
    def process_result
      require 'sass'

      if @options[:recursive]
        process_directory
        return
      end

      super
      input = @options[:input]
      if File.directory?(input)
        raise "Error: '#{input.path}' is a directory (did you mean to use --recursive?)"
      end
      output = @options[:output]
      output = input if @options[:in_place]
      process_file(input, output)
    end

    private

    def common_options(opts)
      opts.separator ''
      opts.separator 'Common Options:'

      opts.on('-F', '--from FORMAT',
        'The format to convert from. Can be css, scss, sass.',
        'By default, this is inferred from the input filename.',
        'If there is none, defaults to css.') do |name|
        @options[:from] = name.downcase.to_sym
        raise "sass-convert no longer supports LessCSS." if @options[:from] == :less
        unless [:css, :scss, :sass].include?(@options[:from])
          raise "Unknown format for sass-convert --from: #{name}"
        end
      end

      opts.on('-T', '--to FORMAT',
        'The format to convert to. Can be scss or sass.',
        'By default, this is inferred from the output filename.',
        'If there is none, defaults to sass.') do |name|
        @options[:to] = name.downcase.to_sym
        unless [:scss, :sass].include?(@options[:to])
          raise "Unknown format for sass-convert --to: #{name}"
        end
      end

      opts.on('-i', '--in-place',
        'Convert a file to its own syntax.',
        'This can be used to update some deprecated syntax.') do
        @options[:in_place] = true
      end

      opts.on('-R', '--recursive',
          'Convert all the files in a directory. Requires --from and --to.') do
        @options[:recursive] = true
      end

      opts.on("-?", "-h", "--help", "Show this help message.") do
        puts opts
        exit
      end

      opts.on("-v", "--version", "Print the Sass version.") do
        puts("Sass #{Sass.version[:string]}")
        exit
      end
    end

    def style(opts)
      opts.separator ''
      opts.separator 'Style:'

      opts.on('--dasherize', 'Convert underscores to dashes.') do
        @options[:for_tree][:dasherize] = true
      end

      opts.on(
        '--indent NUM',
        'How many spaces to use for each level of indentation. Defaults to 2.',
        '"t" means use hard tabs.'
      ) do |indent|
        if indent == 't'
          @options[:for_tree][:indent] = "\t"
        else
          @options[:for_tree][:indent] = " " * indent.to_i
        end
      end

      opts.on('--old', 'Output the old-style ":prop val" property syntax.',
                       'Only meaningful when generating Sass.') do
        @options[:for_tree][:old] = true
      end
    end

    def input_and_output(opts)
      opts.separator ''
      opts.separator 'Input and Output:'

      opts.on('-s', '--stdin', :NONE,
              'Read input from standard input instead of an input file.',
              'This is the default if no input file is specified. Requires --from.') do
        @options[:input] = $stdin
      end

      encoding_option(opts)

      opts.on('--unix-newlines', 'Use Unix-style newlines in written files.',
                                 ('Always true on Unix.' unless Sass::Util.windows?)) do
        @options[:unix_newlines] = true if Sass::Util.windows?
      end
    end

    def miscellaneous(opts)
      opts.separator ''
      opts.separator 'Miscellaneous:'

        opts.on('--cache-location PATH',
                'The path to save parsed Sass files. Defaults to .sass-cache.') do |loc|
          @options[:for_engine][:cache_location] = loc
        end

      opts.on('-C', '--no-cache', "Don't cache to sassc files.") do
        @options[:for_engine][:read_cache] = false
      end

      opts.on('-q', '--quiet', 'Silence warnings and status messages during conversion.') do |bool|
        @options[:for_engine][:quiet] = bool
      end

      opts.on('--trace', :NONE, 'Show a full Ruby stack trace on error') do
        @options[:trace] = true
      end
    end

    def process_directory
      @options[:input] = @args.shift
      unless @options[:input]
        raise "Error: directory required when using --recursive."
      end

      output = @options[:output] = @args.shift
      raise "Error: --from required when using --recursive." unless @options[:from]
      raise "Error: --to required when using --recursive." unless @options[:to]
      unless File.directory?(@options[:input])
        raise "Error: '#{@options[:input]}' is not a directory"
      end
      if @options[:output] && File.exist?(@options[:output]) &&
        !File.directory?(@options[:output])
        raise "Error: '#{@options[:output]}' is not a directory"
      end
      @options[:output] ||= @options[:input]

      if @options[:to] == @options[:from] && !@options[:in_place]
        fmt = @options[:from]
        raise "Error: converting from #{fmt} to #{fmt} without --in-place"
      end

      ext = @options[:from]
      Sass::Util.glob("#{@options[:input]}/**/*.#{ext}") do |f|
        output =
          if @options[:in_place]
            f
          elsif @options[:output]
            output_name = f.gsub(/\.(c|sa|sc|le)ss$/, ".#{@options[:to]}")
            output_name[0...@options[:input].size] = @options[:output]
            output_name
          else
            f.gsub(/\.(c|sa|sc|le)ss$/, ".#{@options[:to]}")
          end

        unless File.directory?(File.dirname(output))
          puts_action :directory, :green, File.dirname(output)
          FileUtils.mkdir_p(File.dirname(output))
        end
        puts_action :convert, :green, f
        if File.exist?(output)
          puts_action :overwrite, :yellow, output
        else
          puts_action :create, :green, output
        end

        process_file(f, output)
      end
    end

    def process_file(input, output)
      input_path, output_path = path_for(input), path_for(output)
      if input_path
        @options[:from] ||=
          case input_path
          when /\.scss$/; :scss
          when /\.sass$/; :sass
          when /\.less$/; raise "sass-convert no longer supports LessCSS."
          when /\.css$/; :css
          end
      elsif @options[:in_place]
        raise "Error: the --in-place option requires a filename."
      end

      if output_path
        @options[:to] ||=
          case output_path
          when /\.scss$/; :scss
          when /\.sass$/; :sass
          end
      end

      @options[:from] ||= :css
      @options[:to] ||= :sass
      @options[:for_engine][:syntax] = @options[:from]

      out =
        Sass::Util.silence_sass_warnings do
          if @options[:from] == :css
            require 'sass/css'
            Sass::CSS.new(read(input), @options[:for_tree]).render(@options[:to])
          else
            if input_path
              Sass::Engine.for_file(input_path, @options[:for_engine])
            else
              Sass::Engine.new(read(input), @options[:for_engine])
            end.to_tree.send("to_#{@options[:to]}", @options[:for_tree])
          end
        end

      output = input_path if @options[:in_place]
      write_output(out, output)
    rescue Sass::SyntaxError => e
      raise e if @options[:trace]
      file = " of #{e.sass_filename}" if e.sass_filename
      raise "Error on line #{e.sass_line}#{file}: #{e.message}\n  Use --trace for backtrace"
    rescue LoadError => err
      handle_load_error(err)
    end

    def path_for(file)
      return file.path if file.is_a?(File)
      return file if file.is_a?(String)
    end

    def read(file)
      if file.respond_to?(:read)
        file.read
      else
        open(file, 'rb') {|f| f.read}
      end
    end
  end
end
