module Sass::Exec
  # The `sass` and `scss` executables.
  class SassScss < Base
    attr_reader :default_syntax

    # @param args [Array<String>] The command-line arguments
    def initialize(args, default_syntax)
      super(args)
      @options[:sourcemap] = :auto
      @options[:for_engine] = {
        :load_paths => default_sass_path
      }
      @default_syntax = default_syntax
    end

    protected

    # Tells optparse how to parse the arguments.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      opts.banner = <<END
Usage: #{default_syntax} [options] [INPUT] [OUTPUT]

Description:
  Converts SCSS or Sass files to CSS.
END

      common_options(opts)
      watching_and_updating(opts)
      input_and_output(opts)
      miscellaneous(opts)
    end

    # Processes the options set by the command-line arguments,
    # and runs the Sass compiler appropriately.
    def process_result
      require 'sass'

      if !@options[:update] && !@options[:watch] &&
          @args.first && colon_path?(@args.first)
        if @args.size == 1
          @args = split_colon_path(@args.first)
        else
          @fake_update = true
          @options[:update] = true
        end
      end
      load_compass if @options[:compass]
      return interactive if @options[:interactive]
      return watch_or_update if @options[:watch] || @options[:update]
      super

      if @options[:sourcemap] != :none && @options[:output_filename]
        @options[:sourcemap_filename] = Sass::Util.sourcemap_name(@options[:output_filename])
      end

      @options[:for_engine][:filename] = @options[:filename]
      @options[:for_engine][:css_filename] = @options[:output] if @options[:output].is_a?(String)
      @options[:for_engine][:sourcemap_filename] = @options[:sourcemap_filename]
      @options[:for_engine][:sourcemap] = @options[:sourcemap]

      run
    end

    private

    def common_options(opts)
      opts.separator ''
      opts.separator 'Common Options:'

      opts.on('-I', '--load-path PATH', 'Specify a Sass import path.') do |path|
        (@options[:for_engine][:load_paths] ||= []) << path
      end

      opts.on('-r', '--require LIB', 'Require a Ruby library before running Sass.') do |lib|
        require lib
      end

      opts.on('--compass', 'Make Compass imports available and load project configuration.') do
        @options[:compass] = true
      end

      opts.on('-t', '--style NAME', 'Output style. Can be nested (default), compact, ' \
                                    'compressed, or expanded.') do |name|
        @options[:for_engine][:style] = name.to_sym
      end

      opts.on("-?", "-h", "--help", "Show this help message.") do
        puts opts
        exit
      end

      opts.on("-v", "--version", "Print the Sass version.") do
        puts("Ruby Sass #{Sass.version[:string]}")
        exit
      end
    end

    def watching_and_updating(opts)
      opts.separator ''
      opts.separator 'Watching and Updating:'

      opts.on('--watch', 'Watch files or directories for changes.',
                         'The location of the generated CSS can be set using a colon:',
                         "  #{@default_syntax} --watch input.#{@default_syntax}:output.css",
                         "  #{@default_syntax} --watch input-dir:output-dir") do
        @options[:watch] = true
      end

      # Polling is used by default on Windows.
      unless Sass::Util.windows?
        opts.on('--poll', 'Check for file changes manually, rather than relying on the OS.',
                          'Only meaningful for --watch.') do
          @options[:poll] = true
        end
      end

      opts.on('--update', 'Compile files or directories to CSS.',
                          'Locations are set like --watch.') do
        @options[:update] = true
      end

      opts.on('-f', '--force', 'Recompile every Sass file, even if the CSS file is newer.',
                               'Only meaningful for --update.') do
        @options[:force] = true
      end

      opts.on('--stop-on-error', 'If a file fails to compile, exit immediately.',
                                 'Only meaningful for --watch and --update.') do
        @options[:stop_on_error] = true
      end
    end

    def input_and_output(opts)
      opts.separator ''
      opts.separator 'Input and Output:'

      if @default_syntax == :sass
        opts.on('--scss',
                'Use the CSS-superset SCSS syntax.') do
          @options[:for_engine][:syntax] = :scss
        end
      else
        opts.on('--sass',
                'Use the indented Sass syntax.') do
          @options[:for_engine][:syntax] = :sass
        end
      end

      # This is optional for backwards-compatibility with Sass 3.3, which didn't
      # enable sourcemaps by default and instead used "--sourcemap" to do so.
      opts.on(:OPTIONAL, '--sourcemap=TYPE',
          'How to link generated output to the source files.',
          '  auto (default): relative paths where possible, file URIs elsewhere',
          '  file: always absolute file URIs',
          '  inline: include the source text in the sourcemap',
          '  none: no sourcemaps') do |type|
        if type && !%w(auto file inline none).include?(type)
          $stderr.puts "Unknown sourcemap type #{type}.\n\n"
          $stderr.puts opts
          exit
        elsif type.nil?
          Sass::Util.sass_warn <<MESSAGE.rstrip
DEPRECATION WARNING: Passing --sourcemap without a value is deprecated.
Sourcemaps are now generated by default, so this flag has no effect.
MESSAGE
        end

        @options[:sourcemap] = (type || :auto).to_sym
      end

      opts.on('-s', '--stdin', :NONE,
              'Read input from standard input instead of an input file.',
              'This is the default if no input file is specified.') do
        @options[:input] = $stdin
      end

      encoding_option(opts)

      opts.on('--unix-newlines', 'Use Unix-style newlines in written files.',
                                 ('Always true on Unix.' unless Sass::Util.windows?)) do
        @options[:unix_newlines] = true if Sass::Util.windows?
      end

      opts.on('-g', '--debug-info',
              'Emit output that can be used by the FireSass Firebug plugin.') do
        @options[:for_engine][:debug_info] = true
      end

      opts.on('-l', '--line-numbers', '--line-comments',
              'Emit comments in the generated CSS indicating the corresponding source line.') do
        @options[:for_engine][:line_numbers] = true
      end
    end

    def miscellaneous(opts)
      opts.separator ''
      opts.separator 'Miscellaneous:'

      opts.on('-i', '--interactive',
              'Run an interactive SassScript shell.') do
        @options[:interactive] = true
      end

      opts.on('-c', '--check', "Just check syntax, don't evaluate.") do
        require 'stringio'
        @options[:check_syntax] = true
        @options[:output] = StringIO.new
      end

      opts.on('--precision NUMBER_OF_DIGITS', Integer,
              "How many digits of precision to use when outputting decimal numbers.",
              "Defaults to #{Sass::Script::Value::Number.precision}.") do |precision|
        Sass::Script::Value::Number.precision = precision
      end

      opts.on('--cache-location PATH',
              'The path to save parsed Sass files. Defaults to .sass-cache.') do |loc|
        @options[:for_engine][:cache_location] = loc
      end

      opts.on('-C', '--no-cache', "Don't cache parsed Sass files.") do
        @options[:for_engine][:cache] = false
      end

      opts.on('--trace', :NONE, 'Show a full Ruby stack trace on error.') do
        @options[:trace] = true
      end

      opts.on('-q', '--quiet', 'Silence warnings and status messages during compilation.') do
        @options[:for_engine][:quiet] = true
      end
    end

    def load_compass
      begin
        require 'compass'
      rescue LoadError
        require 'rubygems'
        begin
          require 'compass'
        rescue LoadError
          puts "ERROR: Cannot load compass."
          exit 1
        end
      end
      Compass.add_project_configuration
      Compass.configuration.project_path ||= Dir.pwd
      @options[:for_engine][:load_paths] ||= []
      @options[:for_engine][:load_paths] += Compass.configuration.sass_load_paths
    end

    def interactive
      require 'sass/repl'
      Sass::Repl.new(@options).run
    end

    def watch_or_update
      require 'sass/plugin'
      Sass::Plugin.options.merge! @options[:for_engine]
      Sass::Plugin.options[:unix_newlines] = @options[:unix_newlines]
      Sass::Plugin.options[:poll] = @options[:poll]
      Sass::Plugin.options[:sourcemap] = @options[:sourcemap]

      if @options[:force]
        raise "The --force flag may only be used with --update." unless @options[:update]
        Sass::Plugin.options[:always_update] = true
      end

      raise <<MSG if @args.empty?
What files should I watch? Did you mean something like:
    #{@default_syntax} --watch input.#{@default_syntax}:output.css
    #{@default_syntax} --watch input-dir:output-dir
MSG

      if !colon_path?(@args[0]) && probably_dest_dir?(@args[1])
        flag = @options[:update] ? "--update" : "--watch"
        err =
          if !File.exist?(@args[1])
            "doesn't exist"
          elsif @args[1] =~ /\.css$/
            "is a CSS file"
          end
        raise <<MSG if err
File #{@args[1]} #{err}.
    Did you mean: #{@default_syntax} #{flag} #{@args[0]}:#{@args[1]}
MSG
      end

      dirs, files = @args.map {|name| split_colon_path(name)}.
        partition {|i, _| File.directory? i}

      if @fake_update && !dirs.empty?
        # Issue 1602.
        Sass::Util.sass_warn <<WARNING.strip
DEPRECATION WARNING: Compiling directories without --update or --watch is
deprecated and won't work in future versions of Sass. Instead use:
  #{@default_syntax} --update #{@args}
WARNING
      end

      files.map! do |from, to|
        to ||= from.gsub(/\.[^.]*?$/, '.css')
        sourcemap = Sass::Util.sourcemap_name(to) if @options[:sourcemap]
        [from, to, sourcemap]
      end
      dirs.map! {|from, to| [from, to || from]}
      Sass::Plugin.options[:template_location] = dirs

      Sass::Plugin.on_updated_stylesheet do |_, css, sourcemap|
        [css, sourcemap].each do |file|
          next unless file
          puts_action :write, :green, file
        end
      end

      had_error = false
      Sass::Plugin.on_creating_directory {|dirname| puts_action :directory, :green, dirname}
      Sass::Plugin.on_deleting_css {|filename| puts_action :delete, :yellow, filename}
      Sass::Plugin.on_deleting_sourcemap {|filename| puts_action :delete, :yellow, filename}
      Sass::Plugin.on_compilation_error do |error, _, _|
        if error.is_a?(SystemCallError) && !@options[:stop_on_error]
          had_error = true
          puts_action :error, :red, error.message
          STDOUT.flush
          next
        end

        raise error unless error.is_a?(Sass::SyntaxError) && !@options[:stop_on_error]
        had_error = true
        puts_action :error, :red,
          "#{error.sass_filename} (Line #{error.sass_line}: #{error.message})"
        STDOUT.flush
      end

      if @options[:update]
        Sass::Plugin.update_stylesheets(files)
        exit 1 if had_error
        return
      end

      puts ">>> Sass is watching for changes. Press Ctrl-C to stop."

      Sass::Plugin.on_template_modified do |template|
        puts ">>> Change detected to: #{template}"
        STDOUT.flush
      end
      Sass::Plugin.on_template_created do |template|
        puts ">>> New template detected: #{template}"
        STDOUT.flush
      end
      Sass::Plugin.on_template_deleted do |template|
        puts ">>> Deleted template detected: #{template}"
        STDOUT.flush
      end

      Sass::Plugin.watch(files)
    end

    def run
      input = @options[:input]
      output = @options[:output]

      if input == $stdin
        # See issue 1745
        (@options[:for_engine][:load_paths] ||= []) << ::Sass::Importers::DeprecatedPath.new(".")
      end

      @options[:for_engine][:syntax] ||= :scss if input.is_a?(File) && input.path =~ /\.scss$/
      @options[:for_engine][:syntax] ||= @default_syntax
      engine =
        if input.is_a?(File) && !@options[:check_syntax]
          Sass::Engine.for_file(input.path, @options[:for_engine])
        else
          # We don't need to do any special handling of @options[:check_syntax] here,
          # because the Sass syntax checking happens alongside evaluation
          # and evaluation doesn't actually evaluate any code anyway.
          Sass::Engine.new(input.read, @options[:for_engine])
        end

      input.close if input.is_a?(File)

      if @options[:sourcemap] != :none && @options[:sourcemap_filename]
        relative_sourcemap_path = Sass::Util.relative_path_from(
          @options[:sourcemap_filename], Sass::Util.pathname(@options[:output_filename]).dirname)
        rendered, mapping = engine.render_with_sourcemap(relative_sourcemap_path.to_s)
        write_output(rendered, output)
        write_output(
          mapping.to_json(
            :type => @options[:sourcemap],
            :css_path => @options[:output_filename],
            :sourcemap_path => @options[:sourcemap_filename]) + "\n",
          @options[:sourcemap_filename])
      else
        write_output(engine.render, output)
      end
    rescue Sass::SyntaxError => e
      write_output(Sass::SyntaxError.exception_to_css(e), output) if output.is_a?(String)
      raise e
    ensure
      output.close if output.is_a? File
    end

    def colon_path?(path)
      !split_colon_path(path)[1].nil?
    end

    def split_colon_path(path)
      one, two = path.split(':', 2)
      if one && two && Sass::Util.windows? &&
          one =~ /\A[A-Za-z]\Z/ && two =~ %r{\A[/\\]}
        # If we're on Windows and we were passed a drive letter path,
        # don't split on that colon.
        one2, two = two.split(':', 2)
        one = one + ':' + one2
      end
      return one, two
    end

    # Whether path is likely to be meant as the destination
    # in a source:dest pair.
    def probably_dest_dir?(path)
      return false unless path
      return false if colon_path?(path)
      Sass::Util.glob(File.join(path, "*.s[ca]ss")).empty?
    end

    def default_sass_path
      return unless ENV['SASS_PATH']
      # The select here prevents errors when the environment's
      # load paths specified do not exist.
      ENV['SASS_PATH'].split(File::PATH_SEPARATOR).select {|d| File.directory?(d)}
    end
  end
end
