# frozen_string_literal: true

begin
  require "parser"
rescue LoadError
  warn(%q{Error: Unable to load parser. Add `gem "parser"` to your Gemfile.})
  exit(1)
end

module Prism
  module Translation
    # This class is the entry-point for converting a prism syntax tree into the
    # whitequark/parser gem's syntax tree. It inherits from the base parser for
    # the parser gem, and overrides the parse* methods to parse with prism and
    # then translate.
    class Parser < ::Parser::Base
      Diagnostic = ::Parser::Diagnostic # :nodoc:
      private_constant :Diagnostic

      # The parser gem has a list of diagnostics with a hard-coded set of error
      # messages. We create our own diagnostic class in order to set our own
      # error messages.
      class PrismDiagnostic < Diagnostic
        # This is the cached message coming from prism.
        attr_reader :message

        # Initialize a new diagnostic with the given message and location.
        def initialize(message, level, reason, location)
          @message = message
          super(level, reason, {}, location, [])
        end
      end

      Racc_debug_parser = false # :nodoc:

      # The `builder` argument is used to create the parser using our custom builder class by default.
      #
      # By using the `:parser` keyword argument, you can translate in a way that is compatible with
      # the Parser gem using any parser.
      #
      # For example, in RuboCop for Ruby LSP, the following approach can be used to improve performance
      # by reusing a pre-parsed `Prism::ParseLexResult`:
      #
      #   class PrismPreparsed
      #     def initialize(prism_result)
      #       @prism_result = prism_result
      #     end
      #
      #     def parse_lex(source, **options)
      #       @prism_result
      #     end
      #   end
      #
      #   prism_preparsed = PrismPreparsed.new(prism_result)
      #
      #   Prism::Translation::Ruby34.new(builder, parser: prism_preparsed)
      #
      # In an object passed to the `:parser` keyword argument, the `parse` and `parse_lex` methods
      # should be implemented as needed.
      #
      def initialize(builder = Prism::Translation::Parser::Builder.new, parser: Prism)
        @parser = parser

        super(builder)
      end

      def version # :nodoc:
        34
      end

      # The default encoding for Ruby files is UTF-8.
      def default_encoding
        Encoding::UTF_8
      end

      def yyerror # :nodoc:
      end

      # Parses a source buffer and returns the AST.
      def parse(source_buffer)
        @source_buffer = source_buffer
        source = source_buffer.source

        offset_cache = build_offset_cache(source)
        result = unwrap(@parser.parse(source, **prism_options), offset_cache)

        build_ast(result.value, offset_cache)
      ensure
        @source_buffer = nil
      end

      # Parses a source buffer and returns the AST and the source code comments.
      def parse_with_comments(source_buffer)
        @source_buffer = source_buffer
        source = source_buffer.source

        offset_cache = build_offset_cache(source)
        result = unwrap(@parser.parse(source, **prism_options), offset_cache)

        [
          build_ast(result.value, offset_cache),
          build_comments(result.comments, offset_cache)
        ]
      ensure
        @source_buffer = nil
      end

      # Parses a source buffer and returns the AST, the source code comments,
      # and the tokens emitted by the lexer.
      def tokenize(source_buffer, recover = false)
        @source_buffer = source_buffer
        source = source_buffer.source

        offset_cache = build_offset_cache(source)
        result =
          begin
            unwrap(@parser.parse_lex(source, **prism_options), offset_cache)
          rescue ::Parser::SyntaxError
            raise if !recover
          end

        program, tokens = result.value
        ast = build_ast(program, offset_cache) if result.success?

        [
          ast,
          build_comments(result.comments, offset_cache),
          build_tokens(tokens, offset_cache)
        ]
      ensure
        @source_buffer = nil
      end

      # Since prism resolves num params for us, we don't need to support this
      # kind of logic here.
      def try_declare_numparam(node)
        node.children[0].match?(/\A_[1-9]\z/)
      end

      private

      # This is a hook to allow consumers to disable some errors if they don't
      # want them to block creating the syntax tree.
      def valid_error?(error)
        true
      end

      # This is a hook to allow consumers to disable some warnings if they don't
      # want them to block creating the syntax tree.
      def valid_warning?(warning)
        true
      end

      # Build a diagnostic from the given prism parse error.
      def error_diagnostic(error, offset_cache)
        location = error.location
        diagnostic_location = build_range(location, offset_cache)

        case error.type
        when :argument_block_multi
          Diagnostic.new(:error, :block_and_blockarg, {}, diagnostic_location, [])
        when :argument_formal_constant
          Diagnostic.new(:error, :argument_const, {}, diagnostic_location, [])
        when :argument_formal_class
          Diagnostic.new(:error, :argument_cvar, {}, diagnostic_location, [])
        when :argument_formal_global
          Diagnostic.new(:error, :argument_gvar, {}, diagnostic_location, [])
        when :argument_formal_ivar
          Diagnostic.new(:error, :argument_ivar, {}, diagnostic_location, [])
        when :argument_no_forwarding_amp
          Diagnostic.new(:error, :no_anonymous_blockarg, {}, diagnostic_location, [])
        when :argument_no_forwarding_star
          Diagnostic.new(:error, :no_anonymous_restarg, {}, diagnostic_location, [])
        when :argument_no_forwarding_star_star
          Diagnostic.new(:error, :no_anonymous_kwrestarg, {}, diagnostic_location, [])
        when :begin_lonely_else
          location = location.copy(length: 4)
          diagnostic_location = build_range(location, offset_cache)
          Diagnostic.new(:error, :useless_else, {}, diagnostic_location, [])
        when :class_name, :module_name
          Diagnostic.new(:error, :module_name_const, {}, diagnostic_location, [])
        when :class_in_method
          Diagnostic.new(:error, :class_in_def, {}, diagnostic_location, [])
        when :def_endless_setter
          Diagnostic.new(:error, :endless_setter, {}, diagnostic_location, [])
        when :embdoc_term
          Diagnostic.new(:error, :embedded_document, {}, diagnostic_location, [])
        when :incomplete_variable_class, :incomplete_variable_class_3_3
          location = location.copy(length: location.length + 1)
          diagnostic_location = build_range(location, offset_cache)

          Diagnostic.new(:error, :cvar_name, { name: location.slice }, diagnostic_location, [])
        when :incomplete_variable_instance, :incomplete_variable_instance_3_3
          location = location.copy(length: location.length + 1)
          diagnostic_location = build_range(location, offset_cache)

          Diagnostic.new(:error, :ivar_name, { name: location.slice }, diagnostic_location, [])
        when :invalid_variable_global, :invalid_variable_global_3_3
          Diagnostic.new(:error, :gvar_name, { name: location.slice }, diagnostic_location, [])
        when :module_in_method
          Diagnostic.new(:error, :module_in_def, {}, diagnostic_location, [])
        when :numbered_parameter_ordinary
          Diagnostic.new(:error, :ordinary_param_defined, {}, diagnostic_location, [])
        when :numbered_parameter_outer_scope
          Diagnostic.new(:error, :numparam_used_in_outer_scope, {}, diagnostic_location, [])
        when :parameter_circular
          Diagnostic.new(:error, :circular_argument_reference, { var_name: location.slice }, diagnostic_location, [])
        when :parameter_name_repeat
          Diagnostic.new(:error, :duplicate_argument, {}, diagnostic_location, [])
        when :parameter_numbered_reserved
          Diagnostic.new(:error, :reserved_for_numparam, { name: location.slice }, diagnostic_location, [])
        when :regexp_unknown_options
          Diagnostic.new(:error, :regexp_options, { options: location.slice[1..] }, diagnostic_location, [])
        when :singleton_for_literals
          Diagnostic.new(:error, :singleton_literal, {}, diagnostic_location, [])
        when :string_literal_eof
          Diagnostic.new(:error, :string_eof, {}, diagnostic_location, [])
        when :unexpected_token_ignore
          Diagnostic.new(:error, :unexpected_token, { token: location.slice }, diagnostic_location, [])
        when :write_target_in_method
          Diagnostic.new(:error, :dynamic_const, {}, diagnostic_location, [])
        else
          PrismDiagnostic.new(error.message, :error, error.type, diagnostic_location)
        end
      end

      # Build a diagnostic from the given prism parse warning.
      def warning_diagnostic(warning, offset_cache)
        diagnostic_location = build_range(warning.location, offset_cache)

        case warning.type
        when :ambiguous_first_argument_plus
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: "+" }, diagnostic_location, [])
        when :ambiguous_first_argument_minus
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: "-" }, diagnostic_location, [])
        when :ambiguous_prefix_ampersand
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: "&" }, diagnostic_location, [])
        when :ambiguous_prefix_star
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: "*" }, diagnostic_location, [])
        when :ambiguous_prefix_star_star
          Diagnostic.new(:warning, :ambiguous_prefix, { prefix: "**" }, diagnostic_location, [])
        when :ambiguous_slash
          Diagnostic.new(:warning, :ambiguous_regexp, {}, diagnostic_location, [])
        when :dot_dot_dot_eol
          Diagnostic.new(:warning, :triple_dot_at_eol, {}, diagnostic_location, [])
        when :duplicated_hash_key
          # skip, parser does this on its own
        else
          PrismDiagnostic.new(warning.message, :warning, warning.type, diagnostic_location)
        end
      end

      # If there was a error generated during the parse, then raise an
      # appropriate syntax error. Otherwise return the result.
      def unwrap(result, offset_cache)
        result.errors.each do |error|
          next unless valid_error?(error)
          diagnostics.process(error_diagnostic(error, offset_cache))
        end

        result.warnings.each do |warning|
          next unless valid_warning?(warning)
          diagnostic = warning_diagnostic(warning, offset_cache)
          diagnostics.process(diagnostic) if diagnostic
        end

        result
      end

      # Prism deals with offsets in bytes, while the parser gem deals with
      # offsets in characters. We need to handle this conversion in order to
      # build the parser gem AST.
      #
      # If the bytesize of the source is the same as the length, then we can
      # just use the offset directly. Otherwise, we build an array where the
      # index is the byte offset and the value is the character offset.
      def build_offset_cache(source)
        if source.bytesize == source.length
          -> (offset) { offset }
        else
          offset_cache = []
          offset = 0

          source.each_char do |char|
            char.bytesize.times { offset_cache << offset }
            offset += 1
          end

          offset_cache << offset
        end
      end

      # Build the parser gem AST from the prism AST.
      def build_ast(program, offset_cache)
        program.accept(Compiler.new(self, offset_cache))
      end

      # Build the parser gem comments from the prism comments.
      def build_comments(comments, offset_cache)
        comments.map do |comment|
          ::Parser::Source::Comment.new(build_range(comment.location, offset_cache))
        end
      end

      # Build the parser gem tokens from the prism tokens.
      def build_tokens(tokens, offset_cache)
        Lexer.new(source_buffer, tokens, offset_cache).to_a
      end

      # Build a range from a prism location.
      def build_range(location, offset_cache)
        ::Parser::Source::Range.new(
          source_buffer,
          offset_cache[location.start_offset],
          offset_cache[location.end_offset]
        )
      end

      # Options for how prism should parse/lex the source.
      def prism_options
        options = {
          filepath: @source_buffer.name,
          version: convert_for_prism(version),
          partial_script: true,
        }
        # The parser gem always encodes to UTF-8, unless it is binary.
        # https://github.com/whitequark/parser/blob/v3.3.6.0/lib/parser/source/buffer.rb#L80-L107
        options[:encoding] = false if @source_buffer.source.encoding != Encoding::BINARY

        options
      end

      # Converts the version format handled by Parser to the format handled by Prism.
      def convert_for_prism(version)
        case version
        when 33
          "3.3.1"
        when 34
          "3.4.0"
        when 35
          "3.5.0"
        else
          "latest"
        end
      end

      require_relative "parser/builder"
      require_relative "parser/compiler"
      require_relative "parser/lexer"

      private_constant :Compiler
      private_constant :Lexer
    end
  end
end
