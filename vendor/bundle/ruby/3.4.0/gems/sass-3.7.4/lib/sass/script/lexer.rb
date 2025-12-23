require 'sass/scss/rx'

module Sass
  module Script
    # The lexical analyzer for SassScript.
    # It takes a raw string and converts it to individual tokens
    # that are easier to parse.
    class Lexer
      include Sass::SCSS::RX

      # A struct containing information about an individual token.
      #
      # `type`: \[`Symbol`\]
      # : The type of token.
      #
      # `value`: \[`Object`\]
      # : The Ruby object corresponding to the value of the token.
      #
      # `source_range`: \[`Sass::Source::Range`\]
      # : The range in the source file in which the token appeared.
      #
      # `pos`: \[`Integer`\]
      # : The scanner position at which the SassScript token appeared.
      Token = Struct.new(:type, :value, :source_range, :pos)

      # The line number of the lexer's current position.
      #
      # @return [Integer]
      def line
        return @line unless @tok
        @tok.source_range.start_pos.line
      end

      # The number of bytes into the current line
      # of the lexer's current position (1-based).
      #
      # @return [Integer]
      def offset
        return @offset unless @tok
        @tok.source_range.start_pos.offset
      end

      # A hash from operator strings to the corresponding token types.
      OPERATORS = {
        '+' => :plus,
        '-' => :minus,
        '*' => :times,
        '/' => :div,
        '%' => :mod,
        '=' => :single_eq,
        ':' => :colon,
        '(' => :lparen,
        ')' => :rparen,
        '[' => :lsquare,
        ']' => :rsquare,
        ',' => :comma,
        'and' => :and,
        'or' => :or,
        'not' => :not,
        '==' => :eq,
        '!=' => :neq,
        '>=' => :gte,
        '<=' => :lte,
        '>' => :gt,
        '<' => :lt,
        '#{' => :begin_interpolation,
        '}' => :end_interpolation,
        ';' => :semicolon,
        '{' => :lcurly,
        '...' => :splat,
      }

      OPERATORS_REVERSE = Sass::Util.map_hash(OPERATORS) {|k, v| [v, k]}

      TOKEN_NAMES = Sass::Util.map_hash(OPERATORS_REVERSE) {|k, v| [k, v.inspect]}.merge(
        :const => "variable (e.g. $foo)",
        :ident => "identifier (e.g. middle)")

      # A list of operator strings ordered with longer names first
      # so that `>` and `<` don't clobber `>=` and `<=`.
      OP_NAMES = OPERATORS.keys.sort_by {|o| -o.size}

      # A sub-list of {OP_NAMES} that only includes operators
      # with identifier names.
      IDENT_OP_NAMES = OP_NAMES.select {|k, _v| k =~ /^\w+/}

      PARSEABLE_NUMBER = /(?:(\d*\.\d+)|(\d+))(?:[eE]([+-]?\d+))?(#{UNIT})?/

      # A hash of regular expressions that are used for tokenizing.
      REGULAR_EXPRESSIONS = {
        :whitespace => /\s+/,
        :comment => COMMENT,
        :single_line_comment => SINGLE_LINE_COMMENT,
        :variable => /(\$)(#{IDENT})/,
        :ident => /(#{IDENT})(\()?/,
        :number => PARSEABLE_NUMBER,
        :unary_minus_number => /-#{PARSEABLE_NUMBER}/,
        :color => HEXCOLOR,
        :id => /##{IDENT}/,
        :selector => /&/,
        :ident_op => /(#{Regexp.union(*IDENT_OP_NAMES.map do |s|
          Regexp.new(Regexp.escape(s) + "(?!#{NMCHAR}|\Z)")
        end)})/,
        :op => /(#{Regexp.union(*OP_NAMES)})/,
      }

      class << self
        private

        def string_re(open, close)
          /#{open}((?:\\.|\#(?!\{)|[^#{close}\\#])*)(#{close}|#\{)/m
        end
      end

      # A hash of regular expressions that are used for tokenizing strings.
      #
      # The key is a `[Symbol, Boolean]` pair.
      # The symbol represents which style of quotation to use,
      # while the boolean represents whether or not the string
      # is following an interpolated segment.
      STRING_REGULAR_EXPRESSIONS = {
        :double => {
          false => string_re('"', '"'),
          true => string_re('', '"')
        },
        :single => {
          false => string_re("'", "'"),
          true => string_re('', "'")
        },
        :uri => {
          false => /url\(#{W}(#{URLCHAR}*?)(#{W}\)|#\{)/,
          true => /(#{URLCHAR}*?)(#{W}\)|#\{)/
        },
        # Defined in https://developer.mozilla.org/en/CSS/@-moz-document as a
        # non-standard version of http://www.w3.org/TR/css3-conditional/
        :url_prefix => {
          false => /url-prefix\(#{W}(#{URLCHAR}*?)(#{W}\)|#\{)/,
          true => /(#{URLCHAR}*?)(#{W}\)|#\{)/
        },
        :domain => {
          false => /domain\(#{W}(#{URLCHAR}*?)(#{W}\)|#\{)/,
          true => /(#{URLCHAR}*?)(#{W}\)|#\{)/
        }
      }

      # @param str [String, StringScanner] The source text to lex
      # @param line [Integer] The 1-based line on which the SassScript appears.
      #   Used for error reporting and sourcemap building
      # @param offset [Integer] The 1-based character (not byte) offset in the line in the source.
      #   Used for error reporting and sourcemap building
      # @param options [{Symbol => Object}] An options hash;
      #   see {file:SASS_REFERENCE.md#Options the Sass options documentation}
      def initialize(str, line, offset, options)
        @scanner = str.is_a?(StringScanner) ? str : Sass::Util::MultibyteStringScanner.new(str)
        @line = line
        @offset = offset
        @options = options
        @interpolation_stack = []
        @prev = nil
        @tok = nil
        @next_tok = nil
      end

      # Moves the lexer forward one token.
      #
      # @return [Token] The token that was moved past
      def next
        @tok ||= read_token
        @tok, tok = nil, @tok
        @prev = tok
        tok
      end

      # Returns whether or not there's whitespace before the next token.
      #
      # @return [Boolean]
      def whitespace?(tok = @tok)
        if tok
          @scanner.string[0...tok.pos] =~ /\s\Z/
        else
          @scanner.string[@scanner.pos, 1] =~ /^\s/ ||
            @scanner.string[@scanner.pos - 1, 1] =~ /\s\Z/
        end
      end

      # Returns the given character.
      #
      # @return [String]
      def char(pos = @scanner.pos)
        @scanner.string[pos, 1]
      end

      # Consumes and returns single raw character from the input stream.
      #
      # @return [String]
      def next_char
        unpeek!
        scan(/./)
      end

      # Returns the next token without moving the lexer forward.
      #
      # @return [Token] The next token
      def peek
        @tok ||= read_token
      end

      # Rewinds the underlying StringScanner
      # to before the token returned by \{#peek}.
      def unpeek!
        raise "[BUG] Can't unpeek before a queued token!" if @next_tok
        return unless @tok
        @scanner.pos = @tok.pos
        @line = @tok.source_range.start_pos.line
        @offset = @tok.source_range.start_pos.offset
      end

      # @return [Boolean] Whether or not there's more source text to lex.
      def done?
        return if @next_tok
        whitespace unless after_interpolation? && !@interpolation_stack.empty?
        @scanner.eos? && @tok.nil?
      end

      # @return [Boolean] Whether or not the last token lexed was `:end_interpolation`.
      def after_interpolation?
        @prev && @prev.type == :end_interpolation
      end

      # Raise an error to the effect that `name` was expected in the input stream
      # and wasn't found.
      #
      # This calls \{#unpeek!} to rewind the scanner to immediately after
      # the last returned token.
      #
      # @param name [String] The name of the entity that was expected but not found
      # @raise [Sass::SyntaxError]
      def expected!(name)
        unpeek!
        Sass::SCSS::Parser.expected(@scanner, name, @line)
      end

      # Records all non-comment text the lexer consumes within the block
      # and returns it as a string.
      #
      # @yield A block in which text is recorded
      # @return [String]
      def str
        old_pos = @tok ? @tok.pos : @scanner.pos
        yield
        new_pos = @tok ? @tok.pos : @scanner.pos
        @scanner.string[old_pos...new_pos]
      end

      # Runs a block, and rewinds the state of the lexer to the beginning of the
      # block if it returns `nil` or `false`.
      def try
        old_pos = @scanner.pos
        old_line = @line
        old_offset = @offset
        old_interpolation_stack = @interpolation_stack.dup
        old_prev = @prev
        old_tok = @tok
        old_next_tok = @next_tok

        result = yield
        return result if result

        @scanner.pos = old_pos
        @line = old_line
        @offset = old_offset
        @interpolation_stack = old_interpolation_stack
        @prev = old_prev
        @tok = old_tok
        @next_tok = old_next_tok
        nil
      end

      private

      def read_token
        if (tok = @next_tok)
          @next_tok = nil
          return tok
        end

        return if done?
        start_pos = source_position
        value = token
        return unless value
        type, val = value
        Token.new(type, val, range(start_pos), @scanner.pos - @scanner.matched_size)
      end

      def whitespace
        nil while scan(REGULAR_EXPRESSIONS[:whitespace]) ||
          scan(REGULAR_EXPRESSIONS[:comment]) ||
          scan(REGULAR_EXPRESSIONS[:single_line_comment])
      end

      def token
        if after_interpolation?
          interp_type, interp_value = @interpolation_stack.pop
          if interp_type == :special_fun
            return special_fun_body(interp_value)
          elsif interp_type.nil?
            if @scanner.string[@scanner.pos - 1] == '}' && scan(REGULAR_EXPRESSIONS[:ident])
              return [@scanner[2] ? :funcall : :ident, Sass::Util.normalize_ident_escapes(@scanner[1], start: false)]
            end
          else
            raise "[BUG]: Unknown interp_type #{interp_type}" unless interp_type == :string
            return string(interp_value, true)
          end
        end

        variable || string(:double, false) || string(:single, false) || number || id || color ||
          selector || string(:uri, false) || raw(UNICODERANGE) || special_fun || special_val ||
          ident_op || ident || op
      end

      def variable
        _variable(REGULAR_EXPRESSIONS[:variable])
      end

      def _variable(rx)
        return unless scan(rx)
        [:const, Sass::Util.normalize_ident_escapes(@scanner[2])]
      end

      def ident
        return unless scan(REGULAR_EXPRESSIONS[:ident])
        [@scanner[2] ? :funcall : :ident, Sass::Util.normalize_ident_escapes(@scanner[1])]
      end

      def string(re, open)
        line, offset = @line, @offset
        return unless scan(STRING_REGULAR_EXPRESSIONS[re][open])
        if @scanner[0] =~ /([^\\]|^)\n/
          filename = @options[:filename]
          Sass::Util.sass_warn <<MESSAGE
DEPRECATION WARNING on line #{line}, column #{offset}#{" of #{filename}" if filename}:
Unescaped multiline strings are deprecated and will be removed in a future version of Sass.
To include a newline in a string, use "\\a" or "\\a " as in CSS.
MESSAGE
        end

        if @scanner[2] == '#{' # '
          @interpolation_stack << [:string, re]
          start_pos = Sass::Source::Position.new(@line, @offset - 2)
          @next_tok = Token.new(:string_interpolation, range(start_pos), @scanner.pos - 2)
        end
        str =
          if re == :uri
            url = "#{'url(' unless open}#{@scanner[1]}#{')' unless @scanner[2] == '#{'}"
            Script::Value::String.new(url)
          else
            Script::Value::String.new(Sass::Script::Value::String.value(@scanner[1]), :string)
          end
        [:string, str]
      end

      def number
        # Handling unary minus is complicated by the fact that whitespace is an
        # operator in SassScript. We want "1-2" to be parsed as "1 - 2", but we
        # want "1 -2" to be parsed as "1 (-2)". To accomplish this, we only
        # parse a unary minus as part of a number literal if there's whitespace
        # before and not after it. Cases like "(-2)" are handled by the unary
        # minus logic in the parser instead.
        if @scanner.peek(1) == '-'
          return if @scanner.pos == 0
          unary_minus_allowed =
            case @scanner.string[@scanner.pos - 1, 1]
            when /\s/; true
            when '/'; @scanner.pos != 1 && @scanner.string[@scanner.pos - 2, 1] == '*'
            else; false
            end

          return unless unary_minus_allowed
          return unless scan(REGULAR_EXPRESSIONS[:unary_minus_number])
          minus = true
        else
          return unless scan(REGULAR_EXPRESSIONS[:number])
          minus = false
        end

        value = (@scanner[1] ? @scanner[1].to_f : @scanner[2].to_i) * (minus ? -1 : 1)
        value *= 10**@scanner[3].to_i if @scanner[3]
        units = @scanner[4]
        units = Sass::Util::normalize_ident_escapes(units) if units
        script_number = Script::Value::Number.new(value, Array(units))
        [:number, script_number]
      end

      def id
        # Colors and ids are tough to tell apart, because they overlap but
        # neither is a superset of the other. "#xyz" is an id but not a color,
        # "#000" is a color but not an id, "#abc" is both, and "#0" is neither.
        # We need to handle all these cases correctly.
        #
        # To do so, we first try to parse something as an id. If this works and
        # the id is also a valid color, we return the color. Otherwise, we
        # return the id. If it didn't parse as an id, we then try to parse it as
        # a color. If *this* works, we return the color, and if it doesn't we
        # give up and throw an error.
        #
        # IDs in properties are used in the Basic User Interface Module
        # (http://www.w3.org/TR/css3-ui/).
        return unless scan(REGULAR_EXPRESSIONS[:id])
        if @scanner[0] =~ /^\#[0-9a-fA-F]+$/ &&
          (@scanner[0].length == 4 || @scanner[0].length == 5 ||
           @scanner[0].length == 7 || @scanner[0].length == 9)
          return [:color, Script::Value::Color.from_hex(@scanner[0])]
        end
        [:ident, Sass::Util.normalize_ident_escapes(@scanner[0])]
      end

      def color
        return unless @scanner.match?(REGULAR_EXPRESSIONS[:color])
        unless @scanner[0].length == 4 || @scanner[0].length == 5 ||
               @scanner[0].length == 7 || @scanner[0].length == 9
          return
        end
        script_color = Script::Value::Color.from_hex(scan(REGULAR_EXPRESSIONS[:color]))
        [:color, script_color]
      end

      def selector
        start_pos = source_position
        return unless scan(REGULAR_EXPRESSIONS[:selector])

        if @scanner.peek(1) == '&'
          filename = @options[:filename]
          Sass::Util.sass_warn <<MESSAGE
WARNING on line #{line}, column #{offset}#{" of #{filename}" if filename}:
In Sass, "&&" means two copies of the parent selector. You probably want to use "and" instead.
MESSAGE
        end

        script_selector = Script::Tree::Selector.new
        script_selector.source_range = range(start_pos)
        [:selector, script_selector]
      end

      def special_fun
        prefix = scan(/((-[\w-]+-)?(calc|element)|expression|progid:[a-z\.]*)\(/i)
        return unless prefix
        special_fun_body(1, prefix)
      end

      def special_fun_body(parens, prefix = nil)
        str = prefix || ''
        while (scanned = scan(/.*?([()]|\#\{)/m))
          str << scanned
          if scanned[-1] == ?(
            parens += 1
            next
          elsif scanned[-1] == ?)
            parens -= 1
            next unless parens == 0
          else
            raise "[BUG] Unreachable" unless @scanner[1] == '#{' # '
            str.slice!(-2..-1)
            @interpolation_stack << [:special_fun, parens]
            start_pos = Sass::Source::Position.new(@line, @offset - 2)
            @next_tok = Token.new(:string_interpolation, range(start_pos), @scanner.pos - 2)
          end

          return [:special_fun, Sass::Script::Value::String.new(str)]
        end

        scan(/.*/)
        expected!('")"')
      end

      def special_val
        return unless scan(/!#{W}important/i)
        [:string, Script::Value::String.new("!important")]
      end

      def ident_op
        op = scan(REGULAR_EXPRESSIONS[:ident_op])
        return unless op
        [OPERATORS[op]]
      end

      def op
        op = scan(REGULAR_EXPRESSIONS[:op])
        return unless op
        name = OPERATORS[op]
        @interpolation_stack << nil if name == :begin_interpolation
        [name]
      end

      def raw(rx)
        val = scan(rx)
        return unless val
        [:raw, val]
      end

      def scan(re)
        str = @scanner.scan(re)
        return unless str
        c = str.count("\n")
        @line += c
        @offset = (c == 0 ? @offset + str.size : str.size - str.rindex("\n"))
        str
      end

      def range(start_pos, end_pos = source_position)
        Sass::Source::Range.new(start_pos, end_pos, @options[:filename], @options[:importer])
      end

      def source_position
        Sass::Source::Position.new(@line, @offset)
      end
    end
  end
end
