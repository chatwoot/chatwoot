# frozen_string_literal: true

require_relative "error"

module SassC
  class Engine
    OUTPUT_STYLES = %i[
      sass_style_nested
      sass_style_expanded
      sass_style_compact
      sass_style_compressed
    ]

    attr_reader :template, :options

    def initialize(template, options = {})
      @template = template
      @options = options
      @functions = options.fetch(:functions, Script::Functions)
    end

    def render
      return @template.dup if @template.empty?

      data_context = Native.make_data_context(@template)
      context = Native.data_context_get_context(data_context)
      native_options = Native.context_get_options(context)

      Native.option_set_is_indented_syntax_src(native_options, true) if sass?
      Native.option_set_input_path(native_options, filename) if filename
      Native.option_set_precision(native_options, precision) if precision
      Native.option_set_include_path(native_options, load_paths)
      Native.option_set_output_style(native_options, output_style_enum)
      Native.option_set_source_comments(native_options, true) if line_comments?
      Native.option_set_source_map_file(native_options, source_map_file) if source_map_file
      Native.option_set_source_map_embed(native_options, true) if source_map_embed?
      Native.option_set_source_map_contents(native_options, true) if source_map_contents?
      Native.option_set_omit_source_map_url(native_options, true) if omit_source_map_url?

      import_handler.setup(native_options)
      functions_handler.setup(native_options, functions: @functions)

      status = Native.compile_data_context(data_context)

      if status != 0
        message = Native.context_get_error_message(context)
        filename = Native.context_get_error_file(context)
        line = Native.context_get_error_line(context)

        raise SyntaxError.new(message, filename: filename, line: line)
      end

      css = Native.context_get_output_string(context)

      @dependencies = Native.context_get_included_files(context)
      @source_map   = Native.context_get_source_map_string(context)

      css.force_encoding(@template.encoding)
      @source_map.force_encoding(@template.encoding) if @source_map.is_a?(String)

      return css unless quiet?
    ensure
      Native.delete_data_context(data_context) if data_context
    end

    def dependencies
      raise NotRenderedError unless @dependencies
      Dependency.from_filenames(@dependencies)
    end

    def source_map
      raise NotRenderedError unless @source_map
      @source_map
    end

    def filename
      @options[:filename]
    end

    private

    def quiet?
      @options[:quiet]
    end

    def precision
      @options[:precision]
    end

    def sass?
      @options[:syntax] && @options[:syntax].to_sym == :sass
    end

    def line_comments?
      @options[:line_comments]
    end

    def source_map_embed?
      @options[:source_map_embed]
    end

    def source_map_contents?
      @options[:source_map_contents]
    end

    def omit_source_map_url?
      @options[:omit_source_map_url]
    end

    def source_map_file
      @options[:source_map_file]
    end

    def import_handler
      @import_handler ||= ImportHandler.new(@options)
    end

    def functions_handler
      @functions_handler = FunctionsHandler.new(@options)
    end

    def output_style_enum
      @output_style_enum ||= Native::SassOutputStyle[output_style]
    end

    def output_style
      @output_style ||= begin
        style = @options.fetch(:style, :sass_style_nested).to_s
        style = "sass_style_#{style}" unless style.include?("sass_style_")
        style = style.to_sym
        raise InvalidStyleError unless Native::SassOutputStyle.symbols.include?(style)
        style
      end
    end

    def load_paths
      paths = (@options[:load_paths] || []) + SassC.load_paths
      paths.join(File::PATH_SEPARATOR) unless paths.empty?
    end
  end
end
