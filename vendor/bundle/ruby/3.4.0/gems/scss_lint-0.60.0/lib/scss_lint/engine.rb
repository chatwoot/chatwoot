require 'sass'

require 'open3'

module SCSSLint
  class FileEncodingError < StandardError; end

  # Contains all information for a parsed SCSS file, including its name,
  # contents, and parse tree.
  class Engine
    ENGINE_OPTIONS = { cache: false, syntax: :scss }.freeze

    attr_reader :contents, :filename, :lines, :tree, :any_control_commands

    # Creates a parsed representation of an SCSS document from the given string
    # or file.
    #
    # @param options [Hash]
    # @option options [String] :file The file to load
    # @option options [String] :path The path of the file to load
    # @option options [String] :code The code to parse
    # @option options [String] :preprocess_command A preprocessing command
    # @option options [List<String>] :preprocess_files A list of files that should be preprocessed
    def initialize(options = {})
      @preprocess_command = options[:preprocess_command]
      @preprocess_files = options[:preprocess_files]
      build(options)

      # Need to force encoding to avoid Windows-related bugs.
      # Need to encode with universal newline to avoid other Windows-related bugs.
      encoding = 'UTF-8'
      @lines = @contents.force_encoding(encoding)
                        .encode(encoding, universal_newline: true)
                        .lines
      @tree = @engine.to_tree
      find_any_control_commands
    rescue Encoding::UndefinedConversionError, Sass::SyntaxError, ArgumentError => e
      if e.is_a?(Encoding::UndefinedConversionError) ||
         e.message.match(/invalid.*(byte sequence|character)/i)
        raise FileEncodingError,
              "Unable to parse SCSS file: #{e}",
              e.backtrace
      else
        raise
      end
    end

  private

    def build(options)
      if options[:path]
        build_from_file(options)
      elsif options[:code]
        build_from_string(options[:code])
      end
    end

    # @param options [Hash]
    # @option file [IO] if provided, us this as the file object
    # @option path [String] path of file, loading from this if `file` object not
    #   given
    def build_from_file(options)
      @filename = options[:path]
      @contents = options[:file] ? options[:file].read : File.read(@filename)
      preprocess_contents
      @engine = Sass::Engine.new(@contents, ENGINE_OPTIONS.merge(filename: @filename))
    end

    # @param scss [String]
    def build_from_string(scss)
      @contents = scss
      preprocess_contents
      @engine = Sass::Engine.new(@contents, ENGINE_OPTIONS)
    end

    def find_any_control_commands
      @any_control_commands =
        @lines.any? { |line| line['scss-lint:disable'] || line['scss-lint:enable'] }
    end

    def preprocess_contents # rubocop:disable CyclomaticComplexity
      return unless @preprocess_command
      # Never preprocess :code scss if @preprocess_files is specified.
      return if @preprocess_files && @filename.nil?
      return if @preprocess_files &&
                @preprocess_files.none? { |pattern| File.fnmatch(pattern, @filename) }
      @contents, status = Open3.capture2(@preprocess_command, stdin_data: @contents)
      raise SCSSLint::Exceptions::PreprocessorError if status != 0
    end
  end
end
