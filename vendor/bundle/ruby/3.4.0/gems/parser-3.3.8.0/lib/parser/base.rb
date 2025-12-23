# frozen_string_literal: true

module Parser

  ##
  # Base class for version-specific parsers.
  #
  # @api public
  #
  # @!attribute [r] diagnostics
  #  @return [Parser::Diagnostic::Engine]
  #
  # @!attribute [r] static_env
  #  @return [Parser::StaticEnvironment]
  #
  # @!attribute [r] version
  #  @return [Integer]
  #
  class Base < Racc::Parser
    ##
    # Parses a string of Ruby code and returns the AST. If the source
    # cannot be parsed, {SyntaxError} is raised and a diagnostic is
    # printed to `stderr`.
    #
    # @example
    #  Parser::Base.parse('puts "hello"')
    #
    # @param [String] string The block of code to parse.
    # @param [String] file The name of the file the code originated from.
    # @param [Numeric] line The initial line number.
    # @return [Parser::AST::Node]
    #
    def self.parse(string, file='(string)', line=1)
      parser = default_parser
      source_buffer = setup_source_buffer(file, line, string, parser.default_encoding)
      parser.parse(source_buffer)
    end

    ##
    # Parses a string of Ruby code and returns the AST and comments. If the
    # source cannot be parsed, {SyntaxError} is raised and a diagnostic is
    # printed to `stderr`.
    #
    # @example
    #  Parser::Base.parse_with_comments('puts "hello"')
    #
    # @param [String] string The block of code to parse.
    # @param [String] file The name of the file the code originated from.
    # @param [Numeric] line The initial line number.
    # @return [Array]
    #
    def self.parse_with_comments(string, file='(string)', line=1)
      parser = default_parser
      source_buffer = setup_source_buffer(file, line, string, parser.default_encoding)
      parser.parse_with_comments(source_buffer)
    end

    ##
    # Parses Ruby source code by reading it from a file. If the source
    # cannot be parsed, {SyntaxError} is raised and a diagnostic is
    # printed to `stderr`.
    #
    # @param [String] filename Path to the file to parse.
    # @return [Parser::AST::Node]
    # @see #parse
    #
    def self.parse_file(filename)
      parse(File.read(filename), filename)
    end

    ##
    # Parses Ruby source code by reading it from a file and returns the AST and
    # comments. If the source cannot be parsed, {SyntaxError} is raised and a
    # diagnostic is printed to `stderr`.
    #
    # @param [String] filename Path to the file to parse.
    # @return [Array]
    # @see #parse
    #
    def self.parse_file_with_comments(filename)
      parse_with_comments(File.read(filename), filename)
    end

    ##
    # @return [Parser::Base] parser with the default options set.
    #
    def self.default_parser
      parser = new

      parser.diagnostics.all_errors_are_fatal = true
      parser.diagnostics.ignore_warnings      = true

      parser.diagnostics.consumer = lambda do |diagnostic|
        $stderr.puts(diagnostic.render)
      end

      parser
    end

    def self.setup_source_buffer(file, line, string, encoding)
      string = string.dup.force_encoding(encoding)

      source_buffer = Source::Buffer.new(file, line)

      if name == 'Parser::Ruby18'
        source_buffer.raw_source = string
      else
        source_buffer.source     = string
      end

      source_buffer
    end
    private_class_method :setup_source_buffer

    attr_reader :lexer
    attr_reader :diagnostics
    attr_reader :builder
    attr_reader :static_env
    attr_reader :source_buffer
    attr_reader :context
    attr_reader :max_numparam_stack
    attr_reader :current_arg_stack
    attr_reader :pattern_variables
    attr_reader :pattern_hash_keys

    ##
    # @param [Parser::Builders::Default] builder The AST builder to use.
    #
    def initialize(builder=Parser::Builders::Default.new)
      @diagnostics = Diagnostic::Engine.new

      @static_env  = StaticEnvironment.new

      # Stack that holds current parsing context
      @context = Context.new

      # Maximum numbered parameters stack
      @max_numparam_stack = MaxNumparamStack.new

      # Current argument names stack
      @current_arg_stack = CurrentArgStack.new

      # Stack of set of variables used in the current pattern
      @pattern_variables = VariablesStack.new

      # Stack of set of keys used in the current hash in pattern matchinig
      @pattern_hash_keys = VariablesStack.new

      @lexer = Lexer.new(version)
      @lexer.diagnostics = @diagnostics
      @lexer.static_env  = @static_env
      @lexer.context     = @context

      @builder = builder
      @builder.parser = self

      # Last emitted token
      @last_token = nil

      if self.class::Racc_debug_parser && ENV['RACC_DEBUG']
        @yydebug = true
      end

      reset
    end

    ##
    # Resets the state of the parser.
    #
    def reset
      @source_buffer = nil

      @lexer.reset
      @static_env.reset
      @context.reset
      @current_arg_stack.reset
      @pattern_variables.reset
      @pattern_hash_keys.reset

      self
    end

    ##
    # Parses a source buffer and returns the AST, or `nil` in case of a non fatal error.
    #
    # @param [Parser::Source::Buffer] source_buffer The source buffer to parse.
    # @return [Parser::AST::Node, nil]
    #
    def parse(source_buffer)
      @lexer.source_buffer = source_buffer
      @source_buffer       = source_buffer

      do_parse || nil # Force `false` to `nil`, see https://github.com/ruby/racc/pull/136
    ensure
      # Don't keep references to the source file.
      @source_buffer       = nil
      @lexer.source_buffer = nil
    end

    ##
    # Parses a source buffer and returns the AST and the source code comments.
    #
    # @see #parse
    # @see Parser::Source::Comment#associate
    # @return [Array]
    #
    def parse_with_comments(source_buffer)
      @lexer.comments = []

      [ parse(source_buffer), @lexer.comments ]
    ensure
      @lexer.comments = nil
    end

    ##
    # Parses a source buffer and returns the AST, the source code comments,
    # and the tokens emitted by the lexer. In case of a fatal error, a {SyntaxError}
    # is raised, unless `recover` is true. In case of an error
    # (non-fatal or recovered), `nil` is returned instead of the AST, and
    # comments as well as tokens are only returned up to the location of
    # the error.
    #
    # Currently, token stream format returned by #tokenize is not documented,
    # but is considered part of a public API and only changed according
    # to Semantic Versioning.
    #
    # However, note that the exact token composition of various constructs
    # might vary. For example, a string `"foo"` is represented equally well
    # by `:tSTRING_BEG " :tSTRING_CONTENT foo :tSTRING_END "` and
    # `:tSTRING "foo"`; such details must not be relied upon.
    #
    # @param [Parser::Source::Buffer] source_buffer
    # @param [Boolean] recover If true, recover from syntax errors. False by default.
    # @return [Array]
    #
    def tokenize(source_buffer, recover=false)
      @lexer.tokens = []
      @lexer.comments = []

      begin
        ast = parse(source_buffer)
      rescue Parser::SyntaxError
        raise if !recover
      end

      [ ast, @lexer.comments, @lexer.tokens ]
    ensure
      @lexer.tokens = nil
      @lexer.comments = nil
    end

    private

    def next_token
      token = @lexer.advance
      @last_token = token
      token
    end

    def check_kwarg_name(name_t)
      case name_t[0]
      when /^[a-z_]/
        # OK
      when /^[A-Z]/
        diagnostic :error, :argument_const, nil, name_t
      end
    end

    def diagnostic(level, reason, arguments, location_t, highlights_ts=[])
      _, location = location_t

      highlights = highlights_ts.map do |token|
        _, range = token
        range
      end

      @diagnostics.process(
          Diagnostic.new(level, reason, arguments, location, highlights))

      if level == :error
        yyerror
      end
    end

    def on_error(error_token_id, error_value, value_stack)
      token_name = token_to_str(error_token_id)
      _, location = error_value

      @diagnostics.process(Diagnostic.new(
          :error, :unexpected_token, { :token => token_name }, location))
    end
  end

end
