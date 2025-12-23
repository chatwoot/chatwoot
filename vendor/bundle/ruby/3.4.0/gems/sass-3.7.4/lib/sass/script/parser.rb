require 'sass/script/lexer'

module Sass
  module Script
    # The parser for SassScript.
    # It parses a string of code into a tree of {Script::Tree::Node}s.
    class Parser
      # The line number of the parser's current position.
      #
      # @return [Integer]
      def line
        @lexer.line
      end

      # The column number of the parser's current position.
      #
      # @return [Integer]
      def offset
        @lexer.offset
      end

      # @param str [String, StringScanner] The source text to parse
      # @param line [Integer] The line on which the SassScript appears.
      #   Used for error reporting and sourcemap building
      # @param offset [Integer] The character (not byte) offset where the script starts in the line.
      #   Used for error reporting and sourcemap building
      # @param options [{Symbol => Object}] An options hash; see
      #   {file:SASS_REFERENCE.md#Options the Sass options documentation}.
      #   This supports an additional `:allow_extra_text` option that controls
      #   whether the parser throws an error when extra text is encountered
      #   after the parsed construct.
      def initialize(str, line, offset, options = {})
        @options = options
        @allow_extra_text = options.delete(:allow_extra_text)
        @lexer = lexer_class.new(str, line, offset, options)
        @stop_at = nil
      end

      # Parses a SassScript expression within an interpolated segment (`#{}`).
      # This means that it stops when it comes across an unmatched `}`,
      # which signals the end of an interpolated segment,
      # it returns rather than throwing an error.
      #
      # @param warn_for_color [Boolean] Whether raw color values passed to
      #   interoplation should cause a warning.
      # @return [Script::Tree::Node] The root node of the parse tree
      # @raise [Sass::SyntaxError] if the expression isn't valid SassScript
      def parse_interpolated(warn_for_color = false)
        # Start two characters back to compensate for #{
        start_pos = Sass::Source::Position.new(line, offset - 2)
        expr = assert_expr :expr
        assert_tok :end_interpolation
        expr = Sass::Script::Tree::Interpolation.new(
          nil, expr, nil, false, false, :warn_for_color => warn_for_color)
        check_for_interpolation expr
        expr.options = @options
        node(expr, start_pos)
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses a SassScript expression.
      #
      # @return [Script::Tree::Node] The root node of the parse tree
      # @raise [Sass::SyntaxError] if the expression isn't valid SassScript
      def parse
        expr = assert_expr :expr
        assert_done
        expr.options = @options
        check_for_interpolation expr
        expr
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses a SassScript expression,
      # ending it when it encounters one of the given identifier tokens.
      #
      # @param tokens [#include?(String | Symbol)] A set of strings or symbols that delimit the expression.
      # @return [Script::Tree::Node] The root node of the parse tree
      # @raise [Sass::SyntaxError] if the expression isn't valid SassScript
      def parse_until(tokens)
        @stop_at = tokens
        expr = assert_expr :expr
        assert_done
        expr.options = @options
        check_for_interpolation expr
        expr
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses the argument list for a mixin include.
      #
      # @return [(Array<Script::Tree::Node>,
      #          {String => Script::Tree::Node},
      #          Script::Tree::Node,
      #          Script::Tree::Node)]
      #   The root nodes of the positional arguments, keyword arguments, and
      #   splat argument(s). Keyword arguments are in a hash from names to values.
      # @raise [Sass::SyntaxError] if the argument list isn't valid SassScript
      def parse_mixin_include_arglist
        args, keywords = [], {}
        if try_tok(:lparen)
          args, keywords, splat, kwarg_splat = mixin_arglist
          assert_tok(:rparen)
        end
        assert_done

        args.each do |a|
          check_for_interpolation a
          a.options = @options
        end

        keywords.each do |_, v|
          check_for_interpolation v
          v.options = @options
        end

        if splat
          check_for_interpolation splat
          splat.options = @options
        end

        if kwarg_splat
          check_for_interpolation kwarg_splat
          kwarg_splat.options = @options
        end

        return args, keywords, splat, kwarg_splat
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses the argument list for a mixin definition.
      #
      # @return [(Array<Script::Tree::Node>, Script::Tree::Node)]
      #   The root nodes of the arguments, and the splat argument.
      # @raise [Sass::SyntaxError] if the argument list isn't valid SassScript
      def parse_mixin_definition_arglist
        args, splat = defn_arglist!(false)
        assert_done

        args.each do |k, v|
          check_for_interpolation k
          k.options = @options

          if v
            check_for_interpolation v
            v.options = @options
          end
        end

        if splat
          check_for_interpolation splat
          splat.options = @options
        end

        return args, splat
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses the argument list for a function definition.
      #
      # @return [(Array<Script::Tree::Node>, Script::Tree::Node)]
      #   The root nodes of the arguments, and the splat argument.
      # @raise [Sass::SyntaxError] if the argument list isn't valid SassScript
      def parse_function_definition_arglist
        args, splat = defn_arglist!(true)
        assert_done

        args.each do |k, v|
          check_for_interpolation k
          k.options = @options

          if v
            check_for_interpolation v
            v.options = @options
          end
        end

        if splat
          check_for_interpolation splat
          splat.options = @options
        end

        return args, splat
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parse a single string value, possibly containing interpolation.
      # Doesn't assert that the scanner is finished after parsing.
      #
      # @return [Script::Tree::Node] The root node of the parse tree.
      # @raise [Sass::SyntaxError] if the string isn't valid SassScript
      def parse_string
        unless (peek = @lexer.peek) &&
            (peek.type == :string ||
            (peek.type == :funcall && peek.value.downcase == 'url'))
          lexer.expected!("string")
        end

        expr = assert_expr :funcall
        check_for_interpolation expr
        expr.options = @options
        @lexer.unpeek!
        expr
      rescue Sass::SyntaxError => e
        e.modify_backtrace :line => @lexer.line, :filename => @options[:filename]
        raise e
      end

      # Parses a SassScript expression.
      #
      # @overload parse(str, line, offset, filename = nil)
      # @return [Script::Tree::Node] The root node of the parse tree
      # @see Parser#initialize
      # @see Parser#parse
      def self.parse(*args)
        new(*args).parse
      end

      PRECEDENCE = [
        :comma, :single_eq, :space, :or, :and,
        [:eq, :neq],
        [:gt, :gte, :lt, :lte],
        [:plus, :minus],
        [:times, :div, :mod],
      ]

      ASSOCIATIVE = [:plus, :times]

      class << self
        # Returns an integer representing the precedence
        # of the given operator.
        # A lower integer indicates a looser binding.
        #
        # @private
        def precedence_of(op)
          PRECEDENCE.each_with_index do |e, i|
            return i if Array(e).include?(op)
          end
          raise "[BUG] Unknown operator #{op.inspect}"
        end

        # Returns whether or not the given operation is associative.
        #
        # @private
        def associative?(op)
          ASSOCIATIVE.include?(op)
        end

        private

        # Defines a simple left-associative production.
        # name is the name of the production,
        # sub is the name of the production beneath it,
        # and ops is a list of operators for this precedence level
        def production(name, sub, *ops)
          class_eval <<RUBY, __FILE__, __LINE__ + 1
            def #{name}
              interp = try_ops_after_interp(#{ops.inspect}, #{name.inspect})
              return interp if interp
              return unless e = #{sub}

              while tok = peek_toks(#{ops.map {|o| o.inspect}.join(', ')})
                return e if @stop_at && @stop_at.include?(tok.type)
                @lexer.next

                if interp = try_op_before_interp(tok, e)
                  other_interp = try_ops_after_interp(#{ops.inspect}, #{name.inspect}, interp)
                  return interp unless other_interp
                  return other_interp
                end

                e = node(Tree::Operation.new(e, assert_expr(#{sub.inspect}), tok.type),
                         e.source_range.start_pos)
              end
              e
            end
RUBY
        end

        def unary(op, sub)
          class_eval <<RUBY, __FILE__, __LINE__ + 1
            def unary_#{op}
              return #{sub} unless tok = try_tok(:#{op})
              interp = try_op_before_interp(tok)
              return interp if interp
              start_pos = source_position
              node(Tree::UnaryOperation.new(assert_expr(:unary_#{op}), :#{op}), start_pos)
            end
RUBY
        end
      end

      private

      def source_position
        Sass::Source::Position.new(line, offset)
      end

      def range(start_pos, end_pos = source_position)
        Sass::Source::Range.new(start_pos, end_pos, @options[:filename], @options[:importer])
      end

      # @private
      def lexer_class; Lexer; end

      def map
        start_pos = source_position
        e = interpolation
        return unless e
        return list e, start_pos unless @lexer.peek && @lexer.peek.type == :colon

        pair = map_pair(e)
        map = node(Sass::Script::Tree::MapLiteral.new([pair]), start_pos)
        while try_tok(:comma)
          pair = map_pair
          return map unless pair
          map.pairs << pair
          map.source_range.end_pos = map.pairs.last.last.source_range.end_pos
        end
        map
      end

      def map_pair(key = nil)
        return unless key ||= interpolation
        assert_tok :colon
        return key, assert_expr(:interpolation)
      end

      def expr
        start_pos = source_position
        e = interpolation
        return unless e
        list e, start_pos
      end

      def list(first, start_pos)
        return first unless @lexer.peek && @lexer.peek.type == :comma

        list = node(Sass::Script::Tree::ListLiteral.new([first], separator: :comma), start_pos)
        while (tok = try_tok(:comma))
          element_before_interp = list.elements.length == 1 ? list.elements.first : list
          if (interp = try_op_before_interp(tok, element_before_interp))
            other_interp = try_ops_after_interp([:comma], :expr, interp)
            return interp unless other_interp
            return other_interp
          end
          return list unless (e = interpolation)
          list.elements << e
          list.source_range.end_pos = list.elements.last.source_range.end_pos
        end
        list
      end

      production :equals, :interpolation, :single_eq

      def try_op_before_interp(op, prev = nil, after_interp = false)
        return unless @lexer.peek && @lexer.peek.type == :begin_interpolation
        unary = !prev && !after_interp
        wb = @lexer.whitespace?(op)
        str = literal_node(Script::Value::String.new(Lexer::OPERATORS_REVERSE[op.type]),
                           op.source_range)

        deprecation =
          case op.type
          when :comma; :potential
          when :div, :single_eq; :none
          when :plus; unary ? :none : :immediate
          when :minus; @lexer.whitespace?(@lexer.peek) ? :immediate : :none
          else; :immediate
          end

        interp = node(
          Script::Tree::Interpolation.new(
            prev, str, nil, wb, false, :originally_text => true, :deprecation => deprecation),
          (prev || str).source_range.start_pos)
        interpolation(first: interp)
      end

      def try_ops_after_interp(ops, name, prev = nil)
        return unless @lexer.after_interpolation?
        op = peek_toks(*ops)
        return unless op
        return if @stop_at && @stop_at.include?(op.type)
        @lexer.next

        interp = try_op_before_interp(op, prev, :after_interp)
        return interp if interp

        wa = @lexer.whitespace?
        str = literal_node(Script::Value::String.new(Lexer::OPERATORS_REVERSE[op.type]),
                           op.source_range)
        str.line = @lexer.line

        deprecation =
          case op.type
          when :comma; :potential
          when :div, :single_eq; :none
          when :minus; @lexer.whitespace?(op) ? :immediate : :none
          else; :immediate
          end
        interp = node(
          Script::Tree::Interpolation.new(
            prev, str, assert_expr(name), false, wa,
            :originally_text => true, :deprecation => deprecation),
          (prev || str).source_range.start_pos)
        interp
      end

      def interpolation(first: nil, inner: :space)
        e = first || send(inner)
        while (interp = try_tok(:begin_interpolation))
          wb = @lexer.whitespace?(interp)
          char_before = @lexer.char(interp.pos - 1)
          mid = without_stop_at {assert_expr :expr}
          assert_tok :end_interpolation
          wa = @lexer.whitespace?
          char_after = @lexer.char

          after = send(inner)
          before_deprecation = e.is_a?(Script::Tree::Interpolation) ? e.deprecation : :none
          after_deprecation = after.is_a?(Script::Tree::Interpolation) ? after.deprecation : :none

          deprecation =
            if before_deprecation == :immediate || after_deprecation == :immediate ||
               # Warn for #{foo}$var and #{foo}(1) but not #{$foo}1.
               (after && !wa && char_after =~ /[$(]/) ||
               # Warn for $var#{foo} and (a)#{foo} but not a#{foo}.
               (e && !wb && is_unsafe_before?(e, char_before))
              :immediate
            else
              :potential
            end

          e = node(
            Script::Tree::Interpolation.new(e, mid, after, wb, wa, :deprecation => deprecation),
            (e || interp).source_range.start_pos)
        end
        e
      end

      # Returns whether `expr` is unsafe to include before an interpolation.
      #
      # @param expr [Node] The expression to check.
      # @param char_before [String] The character immediately before the
      #   interpolation being checked (and presumably the last character of
      #   `expr`).
      # @return [Boolean]
      def is_unsafe_before?(expr, char_before)
        return char_before == ')' if is_safe_value?(expr)

        # Otherwise, it's only safe if it was another interpolation.
        !expr.is_a?(Script::Tree::Interpolation)
      end

      # Returns whether `expr` is safe as the value immediately before an
      # interpolation.
      #
      # It's safe as long as the previous expression is an identifier or number,
      # or a list whose last element is also safe.
      def is_safe_value?(expr)
        return is_safe_value?(expr.elements.last) if expr.is_a?(Script::Tree::ListLiteral)
        return false unless expr.is_a?(Script::Tree::Literal)
        expr.value.is_a?(Script::Value::Number) ||
          (expr.value.is_a?(Script::Value::String) && expr.value.type == :identifier)
      end

      def space
        start_pos = source_position
        e = or_expr
        return unless e
        arr = [e]
        while (e = or_expr)
          arr << e
        end
        if arr.size == 1
          arr.first
        else
          node(Sass::Script::Tree::ListLiteral.new(arr, separator: :space), start_pos)
        end
      end

      production :or_expr, :and_expr, :or
      production :and_expr, :eq_or_neq, :and
      production :eq_or_neq, :relational, :eq, :neq
      production :relational, :plus_or_minus, :gt, :gte, :lt, :lte
      production :plus_or_minus, :times_div_or_mod, :plus, :minus
      production :times_div_or_mod, :unary_plus, :times, :div, :mod

      unary :plus, :unary_minus
      unary :minus, :unary_div
      unary :div, :unary_not # For strings, so /foo/bar works
      unary :not, :ident

      def ident
        return css_min_max unless @lexer.peek && @lexer.peek.type == :ident
        return if @stop_at && @stop_at.include?(@lexer.peek.value)

        name = @lexer.next
        if (color = Sass::Script::Value::Color::COLOR_NAMES[name.value.downcase])
          literal_node(Sass::Script::Value::Color.new(color, name.value), name.source_range)
        elsif name.value == "true"
          literal_node(Sass::Script::Value::Bool.new(true), name.source_range)
        elsif name.value == "false"
          literal_node(Sass::Script::Value::Bool.new(false), name.source_range)
        elsif name.value == "null"
          literal_node(Sass::Script::Value::Null.new, name.source_range)
        else
          literal_node(Sass::Script::Value::String.new(name.value, :identifier), name.source_range)
        end
      end

      def css_min_max
        @lexer.try do
          next unless tok = try_tok(:funcall)
          next unless %w[min max].include?(tok.value.downcase)
          next unless contents = min_max_contents
          node(array_to_interpolation(["#{tok.value}(", *contents]),
               tok.source_range.start_pos, source_position)
        end || funcall
      end

      def min_max_contents(allow_comma: true)
        result = []
        loop do
          if tok = try_tok(:number)
            result << tok.value.to_s
          elsif value = min_max_interpolation
            result << value
          elsif value = min_max_calc
            result << value.value
          elsif value = min_max_function ||
                        min_max_parens ||
                        nested_min_max
            result.concat value
          else
            return
          end

          if try_tok(:rparen)
            result << ")"
            return result
          elsif tok = try_tok(:plus) || try_tok(:minus) || try_tok(:times) || try_tok(:div)
            result << " #{Lexer::OPERATORS_REVERSE[tok.type]} "
          elsif allow_comma && try_tok(:comma)
            result << ", "
          else
            return
          end
        end
      end

      def min_max_interpolation
        without_stop_at do
          tok = try_tok(:begin_interpolation)
          return unless tok
          expr = without_stop_at {assert_expr :expr}
          assert_tok :end_interpolation
          expr
        end
      end

      def min_max_function
        return unless tok = peek_tok(:funcall)
        return unless %w[calc env var].include?(tok.value.downcase)
        @lexer.next
        result = [tok.value, '(', *declaration_value, ')']
        assert_tok :rparen
        result
      end

      def min_max_calc
        return unless tok = peek_tok(:special_fun)
        return unless tok.value.value.downcase.start_with?("calc(")
        @lexer.next.value
      end

      def min_max_parens
        return unless try_tok :lparen
        return unless contents = min_max_contents(allow_comma: false)
        ['(', *contents]
      end

      def nested_min_max
        return unless tok = peek_tok(:funcall)
        return unless %w[min max].include?(tok.value.downcase)
        @lexer.next
        return unless contents = min_max_contents
        [tok.value, '(', *contents]
      end

      def declaration_value
        result = []
        brackets = []
        loop do
          result << @lexer.str do
            until @lexer.done? ||
                  peek_toks(:begin_interpolation,
                            :end_interpolation,
                            :lcurly,
                            :lparen,
                            :lsquare,
                            :rparen,
                            :rsquare)
              @lexer.next || @lexer.next_char
            end
          end

          if try_tok(:begin_interpolation)
            result << assert_expr(:expr)
            assert_tok :end_interpolation
          elsif tok = try_toks(:lcurly, :lparen, :lsquare)
            brackets << case tok.type
                        when :lcurly; :end_interpolation
                        when :lparen; :rparen
                        when :lsquare; :rsquare
                        end
            result << Lexer::OPERATORS_REVERSE[tok.type]
          elsif brackets.empty?
            return result
          else
            bracket = brackets.pop
            assert_tok bracket
            result << Lexer::OPERATORS_REVERSE[bracket]
          end
        end
      end

      def funcall
        tok = try_tok(:funcall)
        return raw unless tok
        args, keywords, splat, kwarg_splat = fn_arglist
        assert_tok(:rparen)
        node(Script::Tree::Funcall.new(tok.value, args, keywords, splat, kwarg_splat),
          tok.source_range.start_pos, source_position)
      end

      def defn_arglist!(must_have_parens)
        if must_have_parens
          assert_tok(:lparen)
        else
          return [], nil unless try_tok(:lparen)
        end

        without_stop_at do
          res = []
          splat = nil
          must_have_default = false
          loop do
            break if peek_tok(:rparen)
            c = assert_tok(:const)
            var = node(Script::Tree::Variable.new(c.value), c.source_range)
            if try_tok(:colon)
              val = assert_expr(:space)
              must_have_default = true
            elsif try_tok(:splat)
              splat = var
              break
            elsif must_have_default
              raise SyntaxError.new(
                "Required argument #{var.inspect} must come before any optional arguments.")
            end
            res << [var, val]
            break unless try_tok(:comma)
          end
          assert_tok(:rparen)
          return res, splat
        end
      end

      def fn_arglist
        arglist(:equals, "function argument")
      end

      def mixin_arglist
        arglist(:interpolation, "mixin argument")
      end

      def arglist(subexpr, description)
        without_stop_at do
          args = []
          keywords = Sass::Util::NormalizedMap.new
          splat = nil
          while (e = send(subexpr))
            if @lexer.peek && @lexer.peek.type == :colon
              name = e
              @lexer.expected!("comma") unless name.is_a?(Tree::Variable)
              assert_tok(:colon)
              value = assert_expr(subexpr, description)

              if keywords[name.name]
                raise SyntaxError.new("Keyword argument \"#{name.to_sass}\" passed more than once")
              end

              keywords[name.name] = value
            else
              if try_tok(:splat)
                return args, keywords, splat, e if splat
                splat, e = e, nil
              elsif splat
                raise SyntaxError.new("Only keyword arguments may follow variable arguments (...).")
              elsif !keywords.empty?
                raise SyntaxError.new("Positional arguments must come before keyword arguments.")
              end
              args << e if e
            end

            return args, keywords, splat unless try_tok(:comma)
          end
          return args, keywords
        end
      end

      def raw
        tok = try_tok(:raw)
        return special_fun unless tok
        literal_node(Script::Value::String.new(tok.value), tok.source_range)
      end

      def special_fun
        first = try_tok(:special_fun)
        return square_list unless first
        str = literal_node(first.value, first.source_range)
        return str unless try_tok(:string_interpolation)
        mid = without_stop_at {assert_expr :expr}
        assert_tok :end_interpolation
        last = assert_expr(:special_fun)
        node(
          Tree::Interpolation.new(str, mid, last, false, false),
          first.source_range.start_pos)
      end

      def square_list
        start_pos = source_position
        return paren unless try_tok(:lsquare)

        without_stop_at do
          space_start_pos = source_position
          e = interpolation(inner: :or_expr)
          separator = nil
          if e
            elements = [e]
            while (e = interpolation(inner: :or_expr))
              elements << e
            end

            # If there's a comma after a space-separated list, it's actually a
            # space-separated list nested in a comma-separated list.
            if try_tok(:comma)
              e = if elements.length == 1
                    elements.first
                  else
                    node(
                      Sass::Script::Tree::ListLiteral.new(elements, separator: :space),
                      space_start_pos)
                  end
              elements = [e]

              while (e = space)
                elements << e
                break unless try_tok(:comma)
              end
              separator = :comma
            else
              separator = :space if elements.length > 1
            end
          else
            elements = []
          end

          assert_tok(:rsquare)
          end_pos = source_position

          node(Sass::Script::Tree::ListLiteral.new(elements, separator: separator, bracketed: true),
               start_pos, end_pos)
        end
      end

      def paren
        return variable unless try_tok(:lparen)
        without_stop_at do
          start_pos = source_position
          e = map
          e.force_division! if e
          end_pos = source_position
          assert_tok(:rparen)
          e || node(Sass::Script::Tree::ListLiteral.new([]), start_pos, end_pos)
        end
      end

      def variable
        start_pos = source_position
        c = try_tok(:const)
        return string unless c
        node(Tree::Variable.new(*c.value), start_pos)
      end

      def string
        first = try_tok(:string)
        return number unless first
        str = literal_node(first.value, first.source_range)
        return str unless try_tok(:string_interpolation)
        mid = assert_expr :expr
        assert_tok :end_interpolation
        last = without_stop_at {assert_expr(:string)}
        node(Tree::StringInterpolation.new(str, mid, last), first.source_range.start_pos)
      end

      def number
        tok = try_tok(:number)
        return selector unless tok
        num = tok.value
        num.options = @options
        num.original = num.to_s
        literal_node(num, tok.source_range.start_pos)
      end

      def selector
        tok = try_tok(:selector)
        return literal unless tok
        node(tok.value, tok.source_range.start_pos)
      end

      def literal
        t = try_tok(:color)
        return literal_node(t.value, t.source_range) if t
      end

      # It would be possible to have unified #assert and #try methods,
      # but detecting the method/token difference turns out to be quite expensive.

      EXPR_NAMES = {
        :string => "string",
        :default => "expression (e.g. 1px, bold)",
        :mixin_arglist => "mixin argument",
        :fn_arglist => "function argument",
        :splat => "...",
        :special_fun => '")"',
      }

      def assert_expr(name, expected = nil)
        e = send(name)
        return e if e
        @lexer.expected!(expected || EXPR_NAMES[name] || EXPR_NAMES[:default])
      end

      def assert_tok(name)
        # Avoids an array allocation caused by argument globbing in assert_toks.
        t = try_tok(name)
        return t if t
        @lexer.expected!(Lexer::TOKEN_NAMES[name] || name.to_s)
      end

      def assert_toks(*names)
        t = try_toks(*names)
        return t if t
        @lexer.expected!(names.map {|tok| Lexer::TOKEN_NAMES[tok] || tok}.join(" or "))
      end

      def peek_tok(name)
        # Avoids an array allocation caused by argument globbing in the try_toks method.
        peeked = @lexer.peek
        peeked && name == peeked.type && peeked
      end

      def peek_toks(*names)
        peeked = @lexer.peek
        peeked && names.include?(peeked.type) && peeked
      end

      def try_tok(name)
        peek_tok(name) && @lexer.next
      end

      def try_toks(*names)
        peek_toks(*names) && @lexer.next
      end

      def assert_done
        if @allow_extra_text
          # If extra text is allowed, just rewind the lexer so that the
          # StringScanner is pointing to the end of the parsed text.
          @lexer.unpeek!
        else
          return if @lexer.done?
          @lexer.expected!(EXPR_NAMES[:default])
        end
      end

      def without_stop_at
        old_stop_at = @stop_at
        @stop_at = nil
        yield
      ensure
        @stop_at = old_stop_at
      end

      # @overload node(value, source_range)
      #   @param value [Sass::Script::Value::Base]
      #   @param source_range [Sass::Source::Range]
      # @overload node(value, start_pos, end_pos = source_position)
      #   @param value [Sass::Script::Value::Base]
      #   @param start_pos [Sass::Source::Position]
      #   @param end_pos [Sass::Source::Position]
      def literal_node(value, source_range_or_start_pos, end_pos = source_position)
        node(Sass::Script::Tree::Literal.new(value), source_range_or_start_pos, end_pos)
      end

      # @overload node(node, source_range)
      #   @param node [Sass::Script::Tree::Node]
      #   @param source_range [Sass::Source::Range]
      # @overload node(node, start_pos, end_pos = source_position)
      #   @param node [Sass::Script::Tree::Node]
      #   @param start_pos [Sass::Source::Position]
      #   @param end_pos [Sass::Source::Position]
      def node(node, source_range_or_start_pos, end_pos = source_position)
        source_range =
          if source_range_or_start_pos.is_a?(Sass::Source::Range)
            source_range_or_start_pos
          else
            range(source_range_or_start_pos, end_pos)
          end

        node.line = source_range.start_pos.line
        node.source_range = source_range
        node.filename = @options[:filename]
        node
      end

      # Converts an array of strings and expressions to a string interoplation
      # object.
      #
      # @param array [Array<Script::Tree:Node | String>]
      # @return [Script::Tree::StringInterpolation]
      def array_to_interpolation(array)
        Sass::Util.merge_adjacent_strings(array).reverse.inject(nil) do |after, value|
          if value.is_a?(::String)
            literal = Sass::Script::Tree::Literal.new(
              Sass::Script::Value::String.new(value))
            next literal unless after
            Sass::Script::Tree::StringInterpolation.new(literal, after.mid, after.after)
          else
            Sass::Script::Tree::StringInterpolation.new(
              Sass::Script::Tree::Literal.new(
                Sass::Script::Value::String.new('')),
              value,
              after || Sass::Script::Tree::Literal.new(
                Sass::Script::Value::String.new('')))
          end
        end
      end

      # Checks a script node for any immediately-deprecated interpolations, and
      # emits warnings for them.
      #
      # @param node [Sass::Script::Tree::Node]
      def check_for_interpolation(node)
        nodes = [node]
        until nodes.empty?
          node = nodes.pop
          unless node.is_a?(Sass::Script::Tree::Interpolation) &&
                 node.deprecation == :immediate
            nodes.concat node.children
            next
          end

          interpolation_deprecation(node)
        end
      end

      # Emits a deprecation warning for an interpolation node.
      #
      # @param node [Sass::Script::Tree::Node]
      def interpolation_deprecation(interpolation)
        return if @options[:_convert]
        location = "on line #{interpolation.line}"
        location << " of #{interpolation.filename}" if interpolation.filename
        Sass::Util.sass_warn <<WARNING
DEPRECATION WARNING #{location}:
\#{} interpolation near operators will be simplified in a future version of Sass.
To preserve the current behavior, use quotes:

  #{interpolation.to_quoted_equivalent.to_sass}

You can use the sass-convert command to automatically fix most cases.
WARNING
      end
    end
  end
end
