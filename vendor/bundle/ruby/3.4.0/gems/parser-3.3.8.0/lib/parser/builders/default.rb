# frozen_string_literal: true

module Parser

  ##
  # Default AST builder. Uses {AST::Node}s.
  #
  class Builders::Default
    class << self
      ##
      # AST compatibility attribute; since `-> {}` is not semantically
      # equivalent to `lambda {}`, all new code should set this attribute
      # to true.
      #
      # If set to false (the default), `-> {}` is emitted as
      # `s(:block, s(:send, nil, :lambda), s(:args), nil)`.
      #
      # If set to true, `-> {}` is emitted as
      # `s(:block, s(:lambda), s(:args), nil)`.
      #
      # @return [Boolean]
      attr_accessor :emit_lambda
    end

    @emit_lambda = false

    class << self
      ##
      # AST compatibility attribute; block arguments of `m { |a| }` are
      # not semantically equivalent to block arguments of `m { |a,| }` or `m { |a, b| }`,
      # all new code should set this attribute to true.
      #
      # If set to false (the default), arguments of `m { |a| }` are emitted as
      # `s(:args, s(:arg, :a))`.
      #
      # If set to true, arguments of `m { |a| }` are emitted as
      # `s(:args, s(:procarg0, :a)).
      #
      # @return [Boolean]
      attr_accessor :emit_procarg0
    end

    @emit_procarg0 = false

    class << self
      ##
      # AST compatibility attribute; locations of `__ENCODING__` are not the same
      # as locations of `Encoding::UTF_8` causing problems during rewriting,
      # all new code should set this attribute to true.
      #
      # If set to false (the default), `__ENCODING__` is emitted as
      # ` s(:const, s(:const, nil, :Encoding), :UTF_8)`.
      #
      # If set to true, `__ENCODING__` is emitted as
      # `s(:__ENCODING__)`.
      #
      # @return [Boolean]
      attr_accessor :emit_encoding
    end

    @emit_encoding = false

    class << self
      ##
      # AST compatibility attribute; indexed assignment, `x[] = 1`, is not
      # semantically equivalent to calling the method directly, `x.[]=(1)`.
      # Specifically, in the former case, the expression's value is always 1,
      # and in the latter case, the expression's value is the return value
      # of the `[]=` method.
      #
      # If set to false (the default), `self[1]` is emitted as
      # `s(:send, s(:self), :[], s(:int, 1))`, and `self[1] = 2` is
      # emitted as `s(:send, s(:self), :[]=, s(:int, 1), s(:int, 2))`.
      #
      # If set to true, `self[1]` is emitted as
      # `s(:index, s(:self), s(:int, 1))`, and `self[1] = 2` is
      # emitted as `s(:indexasgn, s(:self), s(:int, 1), s(:int, 2))`.
      #
      # @return [Boolean]
      attr_accessor :emit_index
    end

    @emit_index = false

    class << self
      ##
      # AST compatibility attribute; causes a single non-mlhs
      # block argument to be wrapped in s(:procarg0).
      #
      # If set to false (the default), block arguments `|a|` are emitted as
      # `s(:args, s(:procarg0, :a))`
      #
      # If set to true, block arguments `|a|` are emitted as
      # `s(:args, s(:procarg0, s(:arg, :a))`
      #
      # @return [Boolean]
      attr_accessor :emit_arg_inside_procarg0
    end

    @emit_arg_inside_procarg0 = false

    class << self
      ##
      # AST compatibility attribute; arguments forwarding initially
      # didn't have support for leading arguments
      # (i.e. `def m(a, ...); end` was a syntax error). However, Ruby 3.0
      # added support for any number of arguments in front of the `...`.
      #
      # If set to false (the default):
      #   1. `def m(...) end` is emitted as
      #      s(:def, :m, s(:forward_args), nil)
      #   2. `def m(a, b, ...) end` is emitted as
      #      s(:def, :m,
      #        s(:args, s(:arg, :a), s(:arg, :b), s(:forward_arg)))
      #
      # If set to true it uses a single format:
      #   1. `def m(...) end` is emitted as
      #      s(:def, :m, s(:args, s(:forward_arg)))
      #   2. `def m(a, b, ...) end` is emitted as
      #      s(:def, :m, s(:args, s(:arg, :a), s(:arg, :b), s(:forward_arg)))
      #
      # It does't matter that much on 2.7 (because there can't be any leading arguments),
      # but on 3.0 it should be better enabled to use a single AST format.
      #
      # @return [Boolean]
      attr_accessor :emit_forward_arg
    end

    @emit_forward_arg = false

    class << self
      ##
      # AST compatibility attribute; Starting from Ruby 2.7 keyword arguments
      # of method calls that are passed explicitly as a hash (i.e. with curly braces)
      # are treated as positional arguments and Ruby 2.7 emits a warning on such method
      # call. Ruby 3.0 given an ArgumentError.
      #
      # If set to false (the default) the last hash argument is emitted as `hash`:
      #
      # ```
      # (send nil :foo
      #   (hash
      #     (pair
      #       (sym :bar)
      #       (int 42))))
      # ```
      #
      # If set to true it is emitted as `kwargs`:
      #
      # ```
      # (send nil :foo
      #   (kwargs
      #     (pair
      #       (sym :bar)
      #       (int 42))))
      # ```
      #
      # Note that `kwargs` node is just a replacement for `hash` argument,
      # so if there's are multiple arguments (or a `kwsplat`) all of them
      # are wrapped into `kwargs` instead of `hash`:
      #
      # ```
      # (send nil :foo
      #   (kwargs
      #     (pair
      #       (sym :a)
      #       (int 42))
      #     (kwsplat
      #       (send nil :b))
      #     (pair
      #       (sym :c)
      #       (int 10))))
      # ```
      attr_accessor :emit_kwargs
    end

    @emit_kwargs = false

    class << self
      ##
      # AST compatibility attribute; Starting from 3.0 Ruby returns
      # true/false from single-line pattern matching with `in` keyword.
      #
      # Before 3.0 there was an exception if given value doesn't match pattern.
      #
      # NOTE: This attribute affects only Ruby 2.7 grammar.
      # 3.0 grammar always emits `match_pattern`/`match_pattern_p`
      #
      # If compatibility attribute set to false `foo in bar` is emitted as `in_match`:
      #
      # ```
      # (in-match
      #   (send nil :foo)
      #   (match-var :bar))
      # ```
      #
      # If set to true it's emitted as `match_pattern_p`:
      # ```
      # (match-pattern-p
      #   (send nil :foo)
      #   (match-var :bar))
      # ```
      attr_accessor :emit_match_pattern
    end

    @emit_match_pattern = false

    class << self
      ##
      # @api private
      def modernize
        @emit_lambda = true
        @emit_procarg0 = true
        @emit_encoding = true
        @emit_index = true
        @emit_arg_inside_procarg0 = true
        @emit_forward_arg = true
        @emit_kwargs = true
        @emit_match_pattern = true
      end
    end

    ##
    # @api private
    attr_accessor :parser

    ##
    # If set to true (the default), `__FILE__` and `__LINE__` are transformed to
    # literal nodes. For example, `s(:str, "lib/foo.rb")` and `s(:int, 10)`.
    #
    # If set to false, `__FILE__` and `__LINE__` are emitted as-is,
    # i.e. as `s(:__FILE__)` and `s(:__LINE__)` nodes.
    #
    # Source maps are identical in both cases.
    #
    # @return [Boolean]
    attr_accessor :emit_file_line_as_literals

    ##
    # Initializes attributes:
    #
    #   * `emit_file_line_as_literals`: `true`
    def initialize
      @emit_file_line_as_literals = true
    end

    # @!parse private

    #
    # Literals
    #

    # Singletons

    def nil(nil_t)
      n0(:nil,
        token_map(nil_t))
    end

    def true(true_t)
      n0(:true,
        token_map(true_t))
    end

    def false(false_t)
      n0(:false,
        token_map(false_t))
    end

    # Numerics

    def integer(integer_t)
      numeric(:int, integer_t)
    end

    def float(float_t)
      numeric(:float, float_t)
    end

    def rational(rational_t)
      numeric(:rational, rational_t)
    end

    def complex(complex_t)
      numeric(:complex, complex_t)
    end

    def numeric(kind, token)
      n(kind, [ value(token) ],
        Source::Map::Operator.new(nil, loc(token)))
    end
    private :numeric

    def unary_num(unary_t, numeric)
      value, = *numeric
      operator_loc = loc(unary_t)

      case value(unary_t)
      when '+'
        value = +value
      when '-'
        value = -value
      end

      numeric.updated(nil, [ value ],
        :location =>
          Source::Map::Operator.new(
            operator_loc,
            operator_loc.join(numeric.loc.expression)))
    end

    def __LINE__(__LINE__t)
      n0(:__LINE__,
        token_map(__LINE__t))
    end

    # Strings

    def string(string_t)
      n(:str, [ string_value(string_t) ],
        delimited_string_map(string_t))
    end

    def string_internal(string_t)
      n(:str, [ string_value(string_t) ],
        unquoted_map(string_t))
    end

    def string_compose(begin_t, parts, end_t)
      if collapse_string_parts?(parts)
        if begin_t.nil? && end_t.nil?
          parts.first
        else
          n(:str, parts.first.children,
            string_map(begin_t, parts, end_t))
        end
      else
        n(:dstr, [ *parts ],
          string_map(begin_t, parts, end_t))
      end
    end

    def character(char_t)
      n(:str, [ string_value(char_t) ],
        prefix_string_map(char_t))
    end

    def __FILE__(__FILE__t)
      n0(:__FILE__,
        token_map(__FILE__t))
    end

    # Symbols

    def symbol(symbol_t)
      n(:sym, [ string_value(symbol_t).to_sym ],
        prefix_string_map(symbol_t))
    end

    def symbol_internal(symbol_t)
      n(:sym, [ string_value(symbol_t).to_sym ],
        unquoted_map(symbol_t))
    end

    def symbol_compose(begin_t, parts, end_t)
      if collapse_string_parts?(parts)
        str = parts.first

        n(:sym, [ str.children.first.to_sym ],
          collection_map(begin_t, str.loc.expression, end_t))
      elsif @parser.version == 18 && parts.empty?
        diagnostic :error, :empty_symbol, nil, loc(begin_t).join(loc(end_t))
      else
        n(:dsym, [ *parts ],
          collection_map(begin_t, parts, end_t))
      end
    end

    # Executable strings

    def xstring_compose(begin_t, parts, end_t)
      n(:xstr, [ *parts ],
        string_map(begin_t, parts, end_t))
    end

    # Indented (interpolated, noninterpolated, executable) strings

    def dedent_string(node, dedent_level)
      if !dedent_level.nil?
        dedenter = Lexer::Dedenter.new(dedent_level)

        case node.type
        when :str
          str = node.children.first
          dedenter.dedent(str)
        when :dstr, :xstr
          children = node.children.map do |str_node|
            if str_node.type == :str
              str = str_node.children.first
              dedenter.dedent(str)
              next nil if str.empty?
            else
              dedenter.interrupt
            end
            str_node
          end

          node = node.updated(nil, children.compact)
        end
      end

      node
    end

    # Regular expressions

    def regexp_options(regopt_t)
      options = value(regopt_t).
        each_char.sort.uniq.
        map(&:to_sym)

      n(:regopt, options,
        token_map(regopt_t))
    end

    def regexp_compose(begin_t, parts, end_t, options)
      begin
        static_regexp(parts, options)
      rescue RegexpError, Encoding::UndefinedConversionError => e
        diagnostic :error, :invalid_regexp, { :message => e.message },
                   loc(begin_t).join(loc(end_t))
      end

      n(:regexp, (parts << options),
        regexp_map(begin_t, end_t, options))
    end

    # Arrays

    def array(begin_t, elements, end_t)
      n(:array, elements,
        collection_map(begin_t, elements, end_t))
    end

    def splat(star_t, arg=nil)
      if arg.nil?
        n0(:splat,
          unary_op_map(star_t))
      else
        n(:splat, [ arg ],
          unary_op_map(star_t, arg))
      end
    end

    def word(parts)
      if collapse_string_parts?(parts)
        parts.first
      else
        n(:dstr, [ *parts ],
          collection_map(nil, parts, nil))
      end
    end

    def words_compose(begin_t, parts, end_t)
      n(:array, [ *parts ],
        collection_map(begin_t, parts, end_t))
    end

    def symbols_compose(begin_t, parts, end_t)
      parts = parts.map do |part|
        case part.type
        when :str
          value, = *part
          part.updated(:sym, [ value.to_sym ])
        when :dstr
          part.updated(:dsym)
        else
          part
        end
      end

      n(:array, [ *parts ],
        collection_map(begin_t, parts, end_t))
    end

    # Hashes

    def pair(key, assoc_t, value)
      n(:pair, [ key, value ],
        binary_op_map(key, assoc_t, value))
    end

    def pair_list_18(list)
      if list.size % 2 != 0
        diagnostic :error, :odd_hash, nil, list.last.loc.expression
      else
        list.
          each_slice(2).map do |key, value|
            n(:pair, [ key, value ],
              binary_op_map(key, nil, value))
          end
      end
    end

    def pair_keyword(key_t, value)
      key_map, pair_map = pair_keyword_map(key_t, value)

      key = n(:sym, [ value(key_t).to_sym ], key_map)

      n(:pair, [ key, value ], pair_map)
    end

    def pair_quoted(begin_t, parts, end_t, value)
      end_t, pair_map = pair_quoted_map(begin_t, end_t, value)

      key = symbol_compose(begin_t, parts, end_t)

      n(:pair, [ key, value ], pair_map)
    end

    def pair_label(key_t)
      key_l = loc(key_t)
      value_l = key_l.adjust(end_pos: -1)

      label = value(key_t)
      value =
        if label =~ /\A[[:upper:]]/
          n(:const, [ nil, label.to_sym ], Source::Map::Constant.new(nil, value_l, value_l))
        else
          n(:ident, [ label.to_sym ], Source::Map::Variable.new(value_l))
        end
      pair_keyword(key_t, accessible(value))
    end

    def kwsplat(dstar_t, arg)
      n(:kwsplat, [ arg ],
        unary_op_map(dstar_t, arg))
    end

    def associate(begin_t, pairs, end_t)
      key_set = Set.new

      pairs.each do |pair|
        next unless pair.type.eql?(:pair)

        key, = *pair

        case key.type
        when :sym, :str, :int, :float
        when :rational, :complex, :regexp
          next unless @parser.version >= 31
        else
          next
        end

        unless key_set.add?(key)
          diagnostic :warning, :duplicate_hash_key, nil, key.loc.expression
        end
      end

      n(:hash, [ *pairs ],
        collection_map(begin_t, pairs, end_t))
    end

    # Ranges

    def range_inclusive(lhs, dot2_t, rhs)
      n(:irange, [ lhs, rhs ],
        range_map(lhs, dot2_t, rhs))
    end

    def range_exclusive(lhs, dot3_t, rhs)
      n(:erange, [ lhs, rhs ],
        range_map(lhs, dot3_t, rhs))
    end

    #
    # Access
    #

    def self(token)
      n0(:self,
        token_map(token))
    end

    def ident(token)
      n(:ident, [ value(token).to_sym ],
        variable_map(token))
    end

    def ivar(token)
      n(:ivar, [ value(token).to_sym ],
        variable_map(token))
    end

    def gvar(token)
      gvar_name = value(token)

      if gvar_name.start_with?('$0') && gvar_name.length > 2
        diagnostic :error, :gvar_name, { :name => gvar_name }, loc(token)
      end

      n(:gvar, [ gvar_name.to_sym ],
        variable_map(token))
    end

    def cvar(token)
      n(:cvar, [ value(token).to_sym ],
        variable_map(token))
    end

    def back_ref(token)
      n(:back_ref, [ value(token).to_sym ],
        token_map(token))
    end

    def nth_ref(token)
      n(:nth_ref, [ value(token) ],
        token_map(token))
    end

    def accessible(node)
      case node.type
      when :__FILE__
        if @emit_file_line_as_literals
          n(:str, [ node.loc.expression.source_buffer.name ],
            node.loc.dup)
        else
          node
        end

      when :__LINE__
        if @emit_file_line_as_literals
          n(:int, [ node.loc.expression.line ],
            node.loc.dup)
        else
          node
        end

      when :__ENCODING__
        if !self.class.emit_encoding
          n(:const, [ n(:const, [ nil, :Encoding], nil), :UTF_8 ],
            node.loc.dup)
        else
          node
        end

      when :ident
        name, = *node

        if %w[? !].any? { |c| name.to_s.end_with?(c) }
          diagnostic :error, :invalid_id_to_get,
                     { :identifier => name.to_s }, node.loc.expression
        end

        # Numbered parameters are not declared anywhere,
        # so they take precedence over method calls in numblock contexts
        if @parser.version >= 27 && @parser.try_declare_numparam(node)
          return node.updated(:lvar)
        end

        unless @parser.static_env.declared?(name)
          if @parser.version == 33 &&
              name == :it &&
              @parser.context.in_block &&
              !@parser.max_numparam_stack.has_ordinary_params?
            diagnostic :warning, :ambiguous_it_call, nil, node.loc.expression
          end

          return n(:send, [ nil, name ],
            var_send_map(node))
        end

        if name.to_s == parser.current_arg_stack.top
          diagnostic :error, :circular_argument_reference,
                     { :var_name => name.to_s }, node.loc.expression
        end

        node.updated(:lvar)

      else
        node
      end
    end

    def const(name_t)
      n(:const, [ nil, value(name_t).to_sym ],
        constant_map(nil, nil, name_t))
    end

    def const_global(t_colon3, name_t)
      cbase = n0(:cbase, token_map(t_colon3))

      n(:const, [ cbase, value(name_t).to_sym ],
        constant_map(cbase, t_colon3, name_t))
    end

    def const_fetch(scope, t_colon2, name_t)
      n(:const, [ scope, value(name_t).to_sym ],
        constant_map(scope, t_colon2, name_t))
    end

    def __ENCODING__(__ENCODING__t)
      n0(:__ENCODING__,
        token_map(__ENCODING__t))
    end

    #
    # Assignment
    #

    def assignable(node)
      case node.type
      when :cvar
        node.updated(:cvasgn)

      when :ivar
        node.updated(:ivasgn)

      when :gvar
        node.updated(:gvasgn)

      when :const
        if @parser.context.in_def
          diagnostic :error, :dynamic_const, nil, node.loc.expression
        end

        node.updated(:casgn)

      when :ident
        name, = *node

        var_name = node.children[0].to_s
        name_loc = node.loc.expression

        check_assignment_to_numparam(var_name, name_loc)
        check_reserved_for_numparam(var_name, name_loc)

        @parser.static_env.declare(name)

        node.updated(:lvasgn)

      when :match_var
        name, = *node

        var_name = node.children[0].to_s
        name_loc = node.loc.expression

        check_assignment_to_numparam(var_name, name_loc)
        check_reserved_for_numparam(var_name, name_loc)

        node

      when :nil, :self, :true, :false,
           :__FILE__, :__LINE__, :__ENCODING__
        diagnostic :error, :invalid_assignment, nil, node.loc.expression

      when :back_ref, :nth_ref
        diagnostic :error, :backref_assignment, nil, node.loc.expression
      end
    end

    def const_op_assignable(node)
      node.updated(:casgn)
    end

    def assign(lhs, eql_t, rhs)
      (lhs << rhs).updated(nil, nil,
        :location => lhs.loc.
          with_operator(loc(eql_t)).
          with_expression(join_exprs(lhs, rhs)))
    end

    def op_assign(lhs, op_t, rhs)
      case lhs.type
      when :gvasgn, :ivasgn, :lvasgn, :cvasgn, :casgn, :send, :csend, :index
        operator   = value(op_t)[0..-1].to_sym
        source_map = lhs.loc.
                        with_operator(loc(op_t)).
                        with_expression(join_exprs(lhs, rhs))

        if lhs.type  == :index
          lhs = lhs.updated(:indexasgn)
        end

        case operator
        when :'&&'
          n(:and_asgn, [ lhs, rhs ], source_map)
        when :'||'
          n(:or_asgn, [ lhs, rhs ], source_map)
        else
          n(:op_asgn, [ lhs, operator, rhs ], source_map)
        end

      when :back_ref, :nth_ref
        diagnostic :error, :backref_assignment, nil, lhs.loc.expression
      end
    end

    def multi_lhs(begin_t, items, end_t)
      n(:mlhs, [ *items ],
        collection_map(begin_t, items, end_t))
    end

    def multi_assign(lhs, eql_t, rhs)
      n(:masgn, [ lhs, rhs ],
        binary_op_map(lhs, eql_t, rhs))
    end

    #
    # Class and module definition
    #

    def def_class(class_t, name,
                  lt_t, superclass,
                  body, end_t)
      n(:class, [ name, superclass, body ],
        module_definition_map(class_t, name, lt_t, end_t))
    end

    def def_sclass(class_t, lshft_t, expr,
                   body, end_t)
      n(:sclass, [ expr, body ],
        module_definition_map(class_t, nil, lshft_t, end_t))
    end

    def def_module(module_t, name,
                   body, end_t)
      n(:module, [ name, body ],
        module_definition_map(module_t, name, nil, end_t))
    end

    #
    # Method (un)definition
    #

    def def_method(def_t, name_t, args,
                   body, end_t)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:def, [ value(name_t).to_sym, args, body ],
        definition_map(def_t, nil, name_t, end_t))
    end

    def def_endless_method(def_t, name_t, args,
                           assignment_t, body)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:def, [ value(name_t).to_sym, args, body ],
        endless_definition_map(def_t, nil, name_t, assignment_t, body))
    end

    def def_singleton(def_t, definee, dot_t,
                      name_t, args,
                      body, end_t)
      validate_definee(definee)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:defs, [ definee, value(name_t).to_sym, args, body ],
        definition_map(def_t, dot_t, name_t, end_t))
    end

    def def_endless_singleton(def_t, definee, dot_t,
                              name_t, args,
                              assignment_t, body)
      validate_definee(definee)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:defs, [ definee, value(name_t).to_sym, args, body ],
        endless_definition_map(def_t, dot_t, name_t, assignment_t, body))
    end

    def undef_method(undef_t, names)
      n(:undef, [ *names ],
        keyword_map(undef_t, nil, names, nil))
    end

    def alias(alias_t, to, from)
      n(:alias, [ to, from ],
        keyword_map(alias_t, nil, [to, from], nil))
    end

    #
    # Formal arguments
    #

    def args(begin_t, args, end_t, check_args=true)
      args = check_duplicate_args(args) if check_args
      validate_no_forward_arg_after_restarg(args)

      map = collection_map(begin_t, args, end_t)
      if !self.class.emit_forward_arg && args.length == 1 && args[0].type == :forward_arg
        n(:forward_args, [], map)
      else
        n(:args, args, map)
      end
    end

    def numargs(max_numparam)
      n(:numargs, [ max_numparam ], nil)
    end

    def forward_only_args(begin_t, dots_t, end_t)
      if self.class.emit_forward_arg
        arg = forward_arg(dots_t)
        n(:args, [ arg ],
          collection_map(begin_t, [ arg ], end_t))
      else
        n(:forward_args, [], collection_map(begin_t, token_map(dots_t), end_t))
      end
    end

    def forward_arg(dots_t)
      n(:forward_arg, [], token_map(dots_t))
    end

    def arg(name_t)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:arg, [ value(name_t).to_sym ],
        variable_map(name_t))
    end

    def optarg(name_t, eql_t, value)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:optarg, [ value(name_t).to_sym, value ],
        variable_map(name_t).
          with_operator(loc(eql_t)).
          with_expression(loc(name_t).join(value.loc.expression)))
    end

    def restarg(star_t, name_t=nil)
      if name_t
        check_reserved_for_numparam(value(name_t), loc(name_t))
        n(:restarg, [ value(name_t).to_sym ],
          arg_prefix_map(star_t, name_t))
      else
        n0(:restarg,
          arg_prefix_map(star_t))
      end
    end

    def kwarg(name_t)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:kwarg, [ value(name_t).to_sym ],
        kwarg_map(name_t))
    end

    def kwoptarg(name_t, value)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:kwoptarg, [ value(name_t).to_sym, value ],
        kwarg_map(name_t, value))
    end

    def kwrestarg(dstar_t, name_t=nil)
      if name_t
        check_reserved_for_numparam(value(name_t), loc(name_t))

        n(:kwrestarg, [ value(name_t).to_sym ],
          arg_prefix_map(dstar_t, name_t))
      else
        n0(:kwrestarg,
          arg_prefix_map(dstar_t))
      end
    end

    def kwnilarg(dstar_t, nil_t)
      n0(:kwnilarg,
        arg_prefix_map(dstar_t, nil_t))
    end

    def shadowarg(name_t)
      check_reserved_for_numparam(value(name_t), loc(name_t))

      n(:shadowarg, [ value(name_t).to_sym ],
        variable_map(name_t))
    end

    def blockarg(amper_t, name_t)
      if !name_t.nil?
        check_reserved_for_numparam(value(name_t), loc(name_t))
      end

      arg_name = name_t ? value(name_t).to_sym : nil
      n(:blockarg, [ arg_name ],
        arg_prefix_map(amper_t, name_t))
    end

    def procarg0(arg)
      if self.class.emit_procarg0
        if arg.type == :arg && self.class.emit_arg_inside_procarg0
          n(:procarg0, [ arg ],
            Source::Map::Collection.new(nil, nil, arg.location.expression))
        else
          arg.updated(:procarg0)
        end
      else
        arg
      end
    end

    # Ruby 1.8 block arguments

    def arg_expr(expr)
      if expr.type == :lvasgn
        expr.updated(:arg)
      else
        n(:arg_expr, [ expr ],
          expr.loc.dup)
      end
    end

    def restarg_expr(star_t, expr=nil)
      if expr.nil?
        n0(:restarg, token_map(star_t))
      elsif expr.type == :lvasgn
        expr.updated(:restarg)
      else
        n(:restarg_expr, [ expr ],
          expr.loc.dup)
      end
    end

    def blockarg_expr(amper_t, expr)
      if expr.type == :lvasgn
        expr.updated(:blockarg)
      else
        n(:blockarg_expr, [ expr ],
          expr.loc.dup)
      end
    end

    # MacRuby Objective-C arguments

    def objc_kwarg(kwname_t, assoc_t, name_t)
      kwname_l = loc(kwname_t)
      if assoc_t.nil? # a: b, not a => b
        kwname_l   = kwname_l.resize(kwname_l.size - 1)
        operator_l = kwname_l.end.resize(1)
      else
        operator_l = loc(assoc_t)
      end

      n(:objc_kwarg, [ value(kwname_t).to_sym, value(name_t).to_sym ],
        Source::Map::ObjcKwarg.new(kwname_l, operator_l, loc(name_t),
                                   kwname_l.join(loc(name_t))))
    end

    def objc_restarg(star_t, name=nil)
      if name.nil?
        n0(:restarg, arg_prefix_map(star_t))
      elsif name.type == :arg # regular restarg
        name.updated(:restarg, nil,
          { :location => name.loc.with_operator(loc(star_t)) })
      else # restarg with objc_kwarg inside
        n(:objc_restarg, [ name ],
          unary_op_map(star_t, name))
      end
    end

    #
    # Method calls
    #

    def call_type_for_dot(dot_t)
      if !dot_t.nil? && value(dot_t) == :anddot
        :csend
      else
        # This case is a bit tricky. ruby23.y returns the token tDOT with
        # the value :dot, and the token :tANDDOT with the value :anddot.
        #
        # But, ruby{18..22}.y (which unconditionally expect tDOT) just
        # return "." there, since they are to be kept close to the corresponding
        # Ruby MRI grammars.
        #
        # Thankfully, we don't have to care.
        :send
      end
    end

    def forwarded_args(dots_t)
      n(:forwarded_args, [], token_map(dots_t))
    end

    def forwarded_restarg(star_t)
      n(:forwarded_restarg, [], token_map(star_t))
    end

    def forwarded_kwrestarg(dstar_t)
      n(:forwarded_kwrestarg, [], token_map(dstar_t))
    end

    def call_method(receiver, dot_t, selector_t,
                    lparen_t=nil, args=[], rparen_t=nil)
      type = call_type_for_dot(dot_t)

      if self.class.emit_kwargs
        rewrite_hash_args_to_kwargs(args)
      end

      if selector_t.nil?
        n(type, [ receiver, :call, *args ],
          send_map(receiver, dot_t, nil, lparen_t, args, rparen_t))
      else
        n(type, [ receiver, value(selector_t).to_sym, *args ],
          send_map(receiver, dot_t, selector_t, lparen_t, args, rparen_t))
      end
    end

    def call_lambda(lambda_t)
      if self.class.emit_lambda
        n0(:lambda, expr_map(loc(lambda_t)))
      else
        n(:send, [ nil, :lambda ],
          send_map(nil, nil, lambda_t))
      end
    end

    def block(method_call, begin_t, args, body, end_t)
      if method_call.type == :yield
        diagnostic :error, :block_given_to_yield, nil, method_call.loc.keyword, [loc(begin_t)]
      end

      if method_call.type == :super
        *_args, last_arg = *method_call
      else
        _receiver, _selector, *_args, last_arg = *method_call
      end
      if last_arg && (last_arg.type == :block_pass || last_arg.type == :forwarded_args)
        if (@parser.version == 33 && method_call.type != :super) || @parser.version != 33
          diagnostic :error, :block_and_blockarg, nil, last_arg.loc.expression, [loc(begin_t)]
        end
      end

      if args.type == :numargs
        block_type = :numblock
        args = args.children[0]
      else
        block_type = :block
      end

      if [:send, :csend, :index, :super, :zsuper, :lambda].include?(method_call.type)
        n(block_type, [ method_call, args, body ],
          block_map(method_call.loc.expression, begin_t, end_t))
      else
        # Code like "return foo 1 do end" is reduced in a weird sequence.
        # Here, method_call is actually (return).
        actual_send, = *method_call
        block =
          n(block_type, [ actual_send, args, body ],
            block_map(actual_send.loc.expression, begin_t, end_t))

        n(method_call.type, [ block ],
          method_call.loc.with_expression(join_exprs(method_call, block)))
      end
    end

    def block_pass(amper_t, arg)
      n(:block_pass, [ arg ],
        unary_op_map(amper_t, arg))
    end

    def objc_varargs(pair, rest_of_varargs)
      value, first_vararg = *pair
      vararg_array = array(nil, [ first_vararg, *rest_of_varargs ], nil).
        updated(:objc_varargs)
      pair.updated(nil, [ value, vararg_array ],
        { :location => pair.loc.with_expression(
              pair.loc.expression.join(vararg_array.loc.expression)) })
    end

    def attr_asgn(receiver, dot_t, selector_t)
      method_name = (value(selector_t) + '=').to_sym
      type = call_type_for_dot(dot_t)

      # Incomplete method call.
      n(type, [ receiver, method_name ],
        send_map(receiver, dot_t, selector_t))
    end

    def index(receiver, lbrack_t, indexes, rbrack_t)
      if self.class.emit_kwargs
        rewrite_hash_args_to_kwargs(indexes)
      end

      if self.class.emit_index
        n(:index, [ receiver, *indexes ],
          index_map(receiver, lbrack_t, rbrack_t))
      else
        n(:send, [ receiver, :[], *indexes ],
          send_index_map(receiver, lbrack_t, rbrack_t))
      end
    end

    def index_asgn(receiver, lbrack_t, indexes, rbrack_t)
      if self.class.emit_kwargs
        rewrite_hash_args_to_kwargs(indexes)
      end

      if self.class.emit_index
        n(:indexasgn, [ receiver, *indexes ],
          index_map(receiver, lbrack_t, rbrack_t))
      else
        # Incomplete method call.
        n(:send, [ receiver, :[]=, *indexes ],
          send_index_map(receiver, lbrack_t, rbrack_t))
      end
    end

    def binary_op(receiver, operator_t, arg)
      source_map = send_binary_op_map(receiver, operator_t, arg)

      if @parser.version == 18
        operator = value(operator_t)

        if operator == '!='
          method_call = n(:send, [ receiver, :==, arg ], source_map)
        elsif operator == '!~'
          method_call = n(:send, [ receiver, :=~, arg ], source_map)
        end

        if %w(!= !~).include?(operator)
          return n(:not, [ method_call ],
                   expr_map(source_map.expression))
        end
      end

      n(:send, [ receiver, value(operator_t).to_sym, arg ],
        source_map)
    end

    def match_op(receiver, match_t, arg)
      source_map = send_binary_op_map(receiver, match_t, arg)

      if (regexp = static_regexp_node(receiver))
        regexp.names.each do |name|
          @parser.static_env.declare(name)
        end

        n(:match_with_lvasgn, [ receiver, arg ],
          source_map)
      else
        n(:send, [ receiver, :=~, arg ],
          source_map)
      end
    end

    def unary_op(op_t, receiver)
      case value(op_t)
      when '+', '-'
        method = value(op_t) + '@'
      else
        method = value(op_t)
      end

      n(:send, [ receiver, method.to_sym ],
        send_unary_op_map(op_t, receiver))
    end

    def not_op(not_t, begin_t=nil, receiver=nil, end_t=nil)
      if @parser.version == 18
        n(:not, [ check_condition(receiver) ],
          unary_op_map(not_t, receiver))
      else
        if receiver.nil?
          nil_node = n0(:begin, collection_map(begin_t, nil, end_t))

          n(:send, [
            nil_node, :'!'
          ], send_unary_op_map(not_t, nil_node))
        else
          n(:send, [ check_condition(receiver), :'!' ],
            send_map(nil, nil, not_t, begin_t, [receiver], end_t))
        end
      end
    end

    #
    # Control flow
    #

    # Logical operations: and, or

    def logical_op(type, lhs, op_t, rhs)
      n(type, [ lhs, rhs ],
        binary_op_map(lhs, op_t, rhs))
    end

    # Conditionals

    def condition(cond_t, cond, then_t,
                  if_true, else_t, if_false, end_t)
      n(:if, [ check_condition(cond), if_true, if_false ],
        condition_map(cond_t, cond, then_t, if_true, else_t, if_false, end_t))
    end

    def condition_mod(if_true, if_false, cond_t, cond)
      n(:if, [ check_condition(cond), if_true, if_false ],
        keyword_mod_map(if_true || if_false, cond_t, cond))
    end

    def ternary(cond, question_t, if_true, colon_t, if_false)
      n(:if, [ check_condition(cond), if_true, if_false ],
        ternary_map(cond, question_t, if_true, colon_t, if_false))
    end

    # Case matching

    def when(when_t, patterns, then_t, body)
      children = patterns << body
      n(:when, children,
        keyword_map(when_t, then_t, children, nil))
    end

    def case(case_t, expr, when_bodies, else_t, else_body, end_t)
      n(:case, [ expr, *(when_bodies << else_body)],
        condition_map(case_t, expr, nil, nil, else_t, else_body, end_t))
    end

    # Loops

    def loop(type, keyword_t, cond, do_t, body, end_t)
      n(type, [ check_condition(cond), body ],
        keyword_map(keyword_t, do_t, nil, end_t))
    end

    def loop_mod(type, body, keyword_t, cond)
      if body.type == :kwbegin
        type = :"#{type}_post"
      end

      n(type, [ check_condition(cond), body ],
        keyword_mod_map(body, keyword_t, cond))
    end

    def for(for_t, iterator, in_t, iteratee,
            do_t, body, end_t)
      n(:for, [ iterator, iteratee, body ],
        for_map(for_t, in_t, do_t, end_t))
    end

    # Keywords

    def keyword_cmd(type, keyword_t, lparen_t=nil, args=[], rparen_t=nil)
      if type == :yield && args.count > 0
        last_arg = args.last
        if last_arg.type == :block_pass
          diagnostic :error, :block_given_to_yield, nil, loc(keyword_t), [last_arg.loc.expression]
        end
      end

      if %i[yield super].include?(type) && self.class.emit_kwargs
        rewrite_hash_args_to_kwargs(args)
      end

      n(type, args,
        keyword_map(keyword_t, lparen_t, args, rparen_t))
    end

    # BEGIN, END

    def preexe(preexe_t, lbrace_t, compstmt, rbrace_t)
      n(:preexe, [ compstmt ],
        keyword_map(preexe_t, lbrace_t, [], rbrace_t))
    end

    def postexe(postexe_t, lbrace_t, compstmt, rbrace_t)
      n(:postexe, [ compstmt ],
        keyword_map(postexe_t, lbrace_t, [], rbrace_t))
    end

    # Exception handling

    def rescue_body(rescue_t,
                    exc_list, assoc_t, exc_var,
                    then_t, compound_stmt)
      n(:resbody, [ exc_list, exc_var, compound_stmt ],
        rescue_body_map(rescue_t, exc_list, assoc_t,
                        exc_var, then_t, compound_stmt))
    end

    def begin_body(compound_stmt, rescue_bodies=[],
                   else_t=nil,    else_=nil,
                   ensure_t=nil,  ensure_=nil)
      if rescue_bodies.any?
        if else_t
          compound_stmt =
            n(:rescue,
              [ compound_stmt, *(rescue_bodies + [ else_ ]) ],
              eh_keyword_map(compound_stmt, nil, rescue_bodies, else_t, else_))
        else
          compound_stmt =
            n(:rescue,
              [ compound_stmt, *(rescue_bodies + [ nil ]) ],
              eh_keyword_map(compound_stmt, nil, rescue_bodies, nil, nil))
        end
      elsif else_t
        statements = []
        if !compound_stmt.nil?
          if compound_stmt.type == :begin
            statements += compound_stmt.children
          else
            statements.push(compound_stmt)
          end
        end
        statements.push(
          n(:begin, [ else_ ],
            collection_map(else_t, [ else_ ], nil)))
        compound_stmt =
          n(:begin, statements,
            collection_map(nil, statements, nil))
      end

      if ensure_t
        compound_stmt =
          n(:ensure,
            [ compound_stmt, ensure_ ],
            eh_keyword_map(compound_stmt, ensure_t, [ ensure_ ], nil, nil))
      end

      compound_stmt
    end

    #
    # Expression grouping
    #

    def compstmt(statements)
      case
      when statements.none?
        nil
      when statements.one?
        statements.first
      else
        n(:begin, statements,
          collection_map(nil, statements, nil))
      end
    end

    def begin(begin_t, body, end_t)
      if body.nil?
        # A nil expression: `()'.
        n0(:begin,
          collection_map(begin_t, nil, end_t))
      elsif body.type == :mlhs  ||
           (body.type == :begin &&
            body.loc.begin.nil? && body.loc.end.nil?)
        # Synthesized (begin) from compstmt "a; b" or (mlhs)
        # from multi_lhs "(a, b) = *foo".
        n(body.type, body.children,
          collection_map(begin_t, body.children, end_t))
      else
        n(:begin, [ body ],
          collection_map(begin_t, [ body ], end_t))
      end
    end

    def begin_keyword(begin_t, body, end_t)
      if body.nil?
        # A nil expression: `begin end'.
        n0(:kwbegin,
          collection_map(begin_t, nil, end_t))
      elsif (body.type == :begin &&
             body.loc.begin.nil? && body.loc.end.nil?)
        # Synthesized (begin) from compstmt "a; b".
        n(:kwbegin, body.children,
          collection_map(begin_t, body.children, end_t))
      else
        n(:kwbegin, [ body ],
          collection_map(begin_t, [ body ], end_t))
      end
    end

    #
    # PATTERN MATCHING
    #

    def case_match(case_t, expr, in_bodies, else_t, else_body, end_t)
      else_body = n(:empty_else, nil, token_map(else_t)) if else_t && !else_body
      n(:case_match, [ expr, *(in_bodies << else_body)],
        condition_map(case_t, expr, nil, nil, else_t, else_body, end_t))
    end

    def in_match(lhs, in_t, rhs)
      n(:in_match, [lhs, rhs],
        binary_op_map(lhs, in_t, rhs))
    end

    def match_pattern(lhs, match_t, rhs)
      n(:match_pattern, [lhs, rhs],
        binary_op_map(lhs, match_t, rhs))
    end

    def match_pattern_p(lhs, match_t, rhs)
      n(:match_pattern_p, [lhs, rhs],
        binary_op_map(lhs, match_t, rhs))
    end

    def in_pattern(in_t, pattern, guard, then_t, body)
      children = [pattern, guard, body]
      n(:in_pattern, children,
        keyword_map(in_t, then_t, children.compact, nil))
    end

    def if_guard(if_t, if_body)
      n(:if_guard, [if_body], guard_map(if_t, if_body))
    end

    def unless_guard(unless_t, unless_body)
      n(:unless_guard, [unless_body], guard_map(unless_t, unless_body))
    end

    def match_var(name_t)
      name = value(name_t).to_sym
      name_l = loc(name_t)

      check_lvar_name(name, name_l)
      check_duplicate_pattern_variable(name, name_l)
      @parser.static_env.declare(name)

      n(:match_var, [ name ],
        variable_map(name_t))
    end

    def match_hash_var(name_t)
      name = value(name_t).to_sym

      expr_l = loc(name_t)
      name_l = expr_l.adjust(end_pos: -1)

      check_lvar_name(name, name_l)
      check_duplicate_pattern_variable(name, name_l)
      @parser.static_env.declare(name)

      n(:match_var, [ name ],
        Source::Map::Variable.new(name_l, expr_l))
    end

    def match_hash_var_from_str(begin_t, strings, end_t)
      if strings.length > 1
        diagnostic :error, :pm_interp_in_var_name, nil, loc(begin_t).join(loc(end_t))
      end

      string = strings[0]

      case string.type
      when :str
        # MRI supports plain strings in hash pattern matching
        name, = *string
        name_l = string.loc.expression

        check_lvar_name(name, name_l)
        check_duplicate_pattern_variable(name, name_l)

        @parser.static_env.declare(name)

        if (begin_l = string.loc.begin)
          # exclude beginning of the string from the location of the variable
          name_l = name_l.adjust(begin_pos: begin_l.length)
        end

        if (end_l = string.loc.end)
          # exclude end of the string from the location of the variable
          name_l = name_l.adjust(end_pos: -end_l.length)
        end

        expr_l = loc(begin_t).join(string.loc.expression).join(loc(end_t))
        n(:match_var, [ name.to_sym ],
          Source::Map::Variable.new(name_l, expr_l))
      when :begin
        match_hash_var_from_str(begin_t, string.children, end_t)
      else
        # we only can get here if there is an interpolation, e.g., ``in "#{ a }":`
        diagnostic :error, :pm_interp_in_var_name, nil, loc(begin_t).join(loc(end_t))
      end
    end

    def match_rest(star_t, name_t = nil)
      if name_t.nil?
        n0(:match_rest,
          unary_op_map(star_t))
      else
        name = match_var(name_t)
        n(:match_rest, [ name ],
          unary_op_map(star_t, name))
      end
    end

    def hash_pattern(lbrace_t, kwargs, rbrace_t)
      args = check_duplicate_args(kwargs)
      n(:hash_pattern, args,
        collection_map(lbrace_t, args, rbrace_t))
    end

    def array_pattern(lbrack_t, elements, rbrack_t)
      return n(:array_pattern, nil, collection_map(lbrack_t, [], rbrack_t)) if elements.nil?

      trailing_comma = false

      node_elements = elements.map do |element|
        if element.type == :match_with_trailing_comma
          trailing_comma = true
          element.children.first
        else
          trailing_comma = false
          element
        end
      end

      node_type = trailing_comma ? :array_pattern_with_tail : :array_pattern

      n(node_type, node_elements,
        collection_map(lbrack_t, elements, rbrack_t))
    end

    def find_pattern(lbrack_t, elements, rbrack_t)
      n(:find_pattern, elements,
        collection_map(lbrack_t, elements, rbrack_t))
    end

    def match_with_trailing_comma(match, comma_t)
      n(:match_with_trailing_comma, [ match ], expr_map(match.loc.expression.join(loc(comma_t))))
    end

    def const_pattern(const, ldelim_t, pattern, rdelim_t)
      n(:const_pattern, [const, pattern],
        Source::Map::Collection.new(
          loc(ldelim_t), loc(rdelim_t),
          const.loc.expression.join(loc(rdelim_t))
        )
      )
    end

    def pin(pin_t, var)
      n(:pin, [ var ],
        send_unary_op_map(pin_t, var))
    end

    def match_alt(left, pipe_t, right)
      source_map = binary_op_map(left, pipe_t, right)

      n(:match_alt, [ left, right ],
        source_map)
    end

    def match_as(value, assoc_t, as)
      source_map = binary_op_map(value, assoc_t, as)

      n(:match_as, [ value, as ],
        source_map)
    end

    def match_nil_pattern(dstar_t, nil_t)
      n0(:match_nil_pattern,
        arg_prefix_map(dstar_t, nil_t))
    end

    def match_pair(label_type, label, value)
      if label_type == :label
        check_duplicate_pattern_key(label[0], label[1])
        pair_keyword(label, value)
      else
        begin_t, parts, end_t = label
        label_loc = loc(begin_t).join(loc(end_t))

        # quoted label like "label": value
        if (var_name = static_string(parts))
          check_duplicate_pattern_key(var_name, label_loc)
        else
          diagnostic :error, :pm_interp_in_var_name, nil, label_loc
        end

        pair_quoted(begin_t, parts, end_t, value)
      end
    end

    def match_label(label_type, label)
      if label_type == :label
        match_hash_var(label)
      else
        # quoted label like "label": value
        begin_t, strings, end_t = label
        match_hash_var_from_str(begin_t, strings, end_t)
      end
    end

    private

    #
    # VERIFICATION
    #

    def check_condition(cond)
      case cond.type
      when :masgn
        if @parser.version <= 23
          diagnostic :error, :masgn_as_condition, nil, cond.loc.expression
        else
          cond
        end

      when :begin
        if cond.children.count == 1
          cond.updated(nil, [
            check_condition(cond.children.last)
          ])
        else
          cond
        end

      when :and, :or
        lhs, rhs = *cond

        if @parser.version == 18
          cond
        else
          cond.updated(cond.type, [
            check_condition(lhs),
            check_condition(rhs)
          ])
        end

      when :irange, :erange
        lhs, rhs = *cond

        type = case cond.type
        when :irange then :iflipflop
        when :erange then :eflipflop
        end

        lhs_condition = check_condition(lhs) unless lhs.nil?
        rhs_condition = check_condition(rhs) unless rhs.nil?

        return cond.updated(type, [
          lhs_condition,
          rhs_condition
        ])

      when :regexp
        n(:match_current_line, [ cond ], expr_map(cond.loc.expression))

      else
        cond
      end
    end

    def check_duplicate_args(args, map={})
      args.each do |this_arg|
        case this_arg.type
        when :arg, :optarg, :restarg, :blockarg,
             :kwarg, :kwoptarg, :kwrestarg,
             :shadowarg

          check_duplicate_arg(this_arg, map)

        when :procarg0

          if this_arg.children[0].is_a?(Symbol)
            # s(:procarg0, :a)
            check_duplicate_arg(this_arg, map)
          else
            # s(:procarg0, s(:arg, :a), ...)
            check_duplicate_args(this_arg.children, map)
          end

        when :mlhs
          check_duplicate_args(this_arg.children, map)
        end
      end
    end

    def check_duplicate_arg(this_arg, map={})
      this_name, = *this_arg

      that_arg   = map[this_name]
      that_name, = *that_arg

      if that_arg.nil?
        map[this_name] = this_arg
      elsif arg_name_collides?(this_name, that_name)
        diagnostic :error, :duplicate_argument, nil,
                   this_arg.loc.name, [ that_arg.loc.name ]
      end
    end

    def validate_no_forward_arg_after_restarg(args)
      restarg = nil
      forward_arg = nil
      args.each do |arg|
        case arg.type
        when :restarg then restarg = arg
        when :forward_arg then forward_arg = arg
        end
      end

      if !forward_arg.nil? && !restarg.nil?
        diagnostic :error, :forward_arg_after_restarg, nil, forward_arg.loc.expression, [restarg.loc.expression]
      end
    end

    def check_assignment_to_numparam(name, loc)
      # MRI < 2.7 treats numbered parameters as regular variables
      # and so it's allowed to perform assignments like `_1 = 42`.
      return if @parser.version < 27

      assigning_to_numparam =
        @parser.context.in_dynamic_block? &&
        name =~ /\A_([1-9])\z/ &&
        @parser.max_numparam_stack.has_numparams?

      if assigning_to_numparam
        diagnostic :error, :cant_assign_to_numparam, { :name => name }, loc
      end
    end

    def check_reserved_for_numparam(name, loc)
      # MRI < 3.0 accepts assignemnt to variables like _1
      # if it's not a numbered parameter. MRI 3.0 and newer throws an error.
      return if @parser.version < 30

      if name =~ /\A_([1-9])\z/
        diagnostic :error, :reserved_for_numparam, { :name => name }, loc
      end
    end

    def arg_name_collides?(this_name, that_name)
      case @parser.version
      when 18
        this_name == that_name
      when 19
        # Ignore underscore.
        this_name != :_ &&
          this_name == that_name
      else
        # Ignore everything beginning with underscore.
        this_name && this_name[0] != '_' &&
          this_name == that_name
      end
    end

    def check_lvar_name(name, loc)
      if name =~ /\A[[[:lower:]]_][[[:alnum:]]_]*\z/
        # OK
      else
        diagnostic :error, :lvar_name, { name: name }, loc
      end
    end

    def check_duplicate_pattern_variable(name, loc)
      return if name.to_s.start_with?('_')

      if @parser.pattern_variables.declared?(name)
        diagnostic :error, :duplicate_variable_name, { name: name.to_s }, loc
      end

      @parser.pattern_variables.declare(name)
    end

    def check_duplicate_pattern_key(name, loc)
      if @parser.pattern_hash_keys.declared?(name)
        diagnostic :error, :duplicate_pattern_key, { name: name.to_s }, loc
      end

      @parser.pattern_hash_keys.declare(name)
    end

    #
    # SOURCE MAPS
    #

    def n(type, children, source_map)
      AST::Node.new(type, children, :location => source_map)
    end

    def n0(type, source_map)
      n(type, [], source_map)
    end

    def join_exprs(left_expr, right_expr)
      left_expr.loc.expression.
        join(right_expr.loc.expression)
    end

    def token_map(token)
      Source::Map.new(loc(token))
    end

    def delimited_string_map(string_t)
      str_range = loc(string_t)

      begin_l = str_range.with(end_pos: str_range.begin_pos + 1)

      end_l   = str_range.with(begin_pos: str_range.end_pos - 1)

      Source::Map::Collection.new(begin_l, end_l,
                                  loc(string_t))
    end

    def prefix_string_map(symbol)
      str_range = loc(symbol)

      begin_l = str_range.with(end_pos: str_range.begin_pos + 1)

      Source::Map::Collection.new(begin_l, nil,
                                  loc(symbol))
    end

    def unquoted_map(token)
      Source::Map::Collection.new(nil, nil,
                                  loc(token))
    end

    def pair_keyword_map(key_t, value_e)
      key_range = loc(key_t)

      key_l   = key_range.adjust(end_pos: -1)

      colon_l = key_range.with(begin_pos: key_range.end_pos - 1)

      [ # key map
        Source::Map::Collection.new(nil, nil,
                                    key_l),
        # pair map
        Source::Map::Operator.new(colon_l,
                                  key_range.join(value_e.loc.expression)) ]
    end

    def pair_quoted_map(begin_t, end_t, value_e)
      end_l = loc(end_t)

      quote_l = end_l.with(begin_pos: end_l.end_pos - 2,
                           end_pos: end_l.end_pos - 1)

      colon_l = end_l.with(begin_pos: end_l.end_pos - 1)

      [ # modified end token
        [ value(end_t), quote_l ],
        # pair map
        Source::Map::Operator.new(colon_l,
                                  loc(begin_t).join(value_e.loc.expression)) ]
    end

    def expr_map(loc)
      Source::Map.new(loc)
    end

    def collection_map(begin_t, parts, end_t)
      if begin_t.nil? || end_t.nil?
        if parts.any?
          expr_l = join_exprs(parts.first, parts.last)
        elsif !begin_t.nil?
          expr_l = loc(begin_t)
        elsif !end_t.nil?
          expr_l = loc(end_t)
        end
      else
        expr_l = loc(begin_t).join(loc(end_t))
      end

      Source::Map::Collection.new(loc(begin_t), loc(end_t), expr_l)
    end

    def string_map(begin_t, parts, end_t)
      if begin_t && value(begin_t).start_with?('<<')
        if parts.any?
          expr_l = join_exprs(parts.first, parts.last)
        else
          expr_l = loc(end_t).begin
        end

        Source::Map::Heredoc.new(loc(begin_t), expr_l, loc(end_t))
      else
        collection_map(begin_t, parts, end_t)
      end
    end

    def regexp_map(begin_t, end_t, options_e)
      Source::Map::Collection.new(loc(begin_t), loc(end_t),
                                  loc(begin_t).join(options_e.loc.expression))
    end

    def constant_map(scope, colon2_t, name_t)
      if scope.nil?
        expr_l = loc(name_t)
      else
        expr_l = scope.loc.expression.join(loc(name_t))
      end

      Source::Map::Constant.new(loc(colon2_t), loc(name_t), expr_l)
    end

    def variable_map(name_t)
      Source::Map::Variable.new(loc(name_t))
    end

    def binary_op_map(left_e, op_t, right_e)
      Source::Map::Operator.new(loc(op_t), join_exprs(left_e, right_e))
    end

    def unary_op_map(op_t, arg_e=nil)
      if arg_e.nil?
        expr_l = loc(op_t)
      else
        expr_l = loc(op_t).join(arg_e.loc.expression)
      end

      Source::Map::Operator.new(loc(op_t), expr_l)
    end

    def range_map(start_e, op_t, end_e)
      if start_e && end_e
        expr_l = join_exprs(start_e, end_e)
      elsif start_e
        expr_l = start_e.loc.expression.join(loc(op_t))
      elsif end_e
        expr_l = loc(op_t).join(end_e.loc.expression)
      end

      Source::Map::Operator.new(loc(op_t), expr_l)
    end

    def arg_prefix_map(op_t, name_t=nil)
      if name_t.nil?
        expr_l = loc(op_t)
      else
        expr_l = loc(op_t).join(loc(name_t))
      end

      Source::Map::Variable.new(loc(name_t), expr_l)
    end

    def kwarg_map(name_t, value_e=nil)
      label_range = loc(name_t)
      name_range  = label_range.adjust(end_pos: -1)

      if value_e
        expr_l = loc(name_t).join(value_e.loc.expression)
      else
        expr_l = loc(name_t)
      end

      Source::Map::Variable.new(name_range, expr_l)
    end

    def module_definition_map(keyword_t, name_e, operator_t, end_t)
      if name_e
        name_l = name_e.loc.expression
      end

      Source::Map::Definition.new(loc(keyword_t),
                                  loc(operator_t), name_l,
                                  loc(end_t))
    end

    def definition_map(keyword_t, operator_t, name_t, end_t)
      Source::Map::MethodDefinition.new(loc(keyword_t),
                                        loc(operator_t), loc(name_t),
                                        loc(end_t), nil, nil)
    end

    def endless_definition_map(keyword_t, operator_t, name_t, assignment_t, body_e)
      body_l = body_e.loc.expression

      Source::Map::MethodDefinition.new(loc(keyword_t),
                                        loc(operator_t), loc(name_t), nil,
                                        loc(assignment_t), body_l)
    end

    def send_map(receiver_e, dot_t, selector_t, begin_t=nil, args=[], end_t=nil)
      if receiver_e
        begin_l = receiver_e.loc.expression
      elsif selector_t
        begin_l = loc(selector_t)
      end

      if end_t
        end_l   = loc(end_t)
      elsif args.any?
        end_l   = args.last.loc.expression
      elsif selector_t
        end_l   = loc(selector_t)
      end

      Source::Map::Send.new(loc(dot_t),   loc(selector_t),
                            loc(begin_t), loc(end_t),
                            begin_l.join(end_l))
    end

    def var_send_map(variable_e)
      Source::Map::Send.new(nil, variable_e.loc.expression,
                            nil, nil,
                            variable_e.loc.expression)
    end

    def send_binary_op_map(lhs_e, selector_t, rhs_e)
      Source::Map::Send.new(nil, loc(selector_t),
                            nil, nil,
                            join_exprs(lhs_e, rhs_e))
    end

    def send_unary_op_map(selector_t, arg_e)
      if arg_e.nil?
        expr_l = loc(selector_t)
      else
        expr_l = loc(selector_t).join(arg_e.loc.expression)
      end

      Source::Map::Send.new(nil, loc(selector_t),
                            nil, nil,
                            expr_l)
    end

    def index_map(receiver_e, lbrack_t, rbrack_t)
      Source::Map::Index.new(loc(lbrack_t), loc(rbrack_t),
                             receiver_e.loc.expression.join(loc(rbrack_t)))
    end

    def send_index_map(receiver_e, lbrack_t, rbrack_t)
      Source::Map::Send.new(nil, loc(lbrack_t).join(loc(rbrack_t)),
                            nil, nil,
                            receiver_e.loc.expression.join(loc(rbrack_t)))
    end

    def block_map(receiver_l, begin_t, end_t)
      Source::Map::Collection.new(loc(begin_t), loc(end_t),
                                  receiver_l.join(loc(end_t)))
    end

    def keyword_map(keyword_t, begin_t, args, end_t)
      args ||= []

      if end_t
        end_l = loc(end_t)
      elsif args.any? && !args.last.nil?
        end_l = args.last.loc.expression
      elsif args.any? && args.count > 1
        end_l = args[-2].loc.expression
      else
        end_l = loc(keyword_t)
      end

      Source::Map::Keyword.new(loc(keyword_t), loc(begin_t), loc(end_t),
                               loc(keyword_t).join(end_l))
    end

    def keyword_mod_map(pre_e, keyword_t, post_e)
      Source::Map::Keyword.new(loc(keyword_t), nil, nil,
                               join_exprs(pre_e, post_e))
    end

    def condition_map(keyword_t, cond_e, begin_t, body_e, else_t, else_e, end_t)
      if end_t
        end_l = loc(end_t)
      elsif else_e && else_e.loc.expression
        end_l = else_e.loc.expression
      elsif loc(else_t)
        end_l = loc(else_t)
      elsif body_e && body_e.loc.expression
        end_l = body_e.loc.expression
      elsif loc(begin_t)
        end_l = loc(begin_t)
      else
        end_l = cond_e.loc.expression
      end

      Source::Map::Condition.new(loc(keyword_t),
                                 loc(begin_t), loc(else_t), loc(end_t),
                                 loc(keyword_t).join(end_l))
    end

    def ternary_map(begin_e, question_t, mid_e, colon_t, end_e)
      Source::Map::Ternary.new(loc(question_t), loc(colon_t),
                               join_exprs(begin_e, end_e))
    end

    def for_map(keyword_t, in_t, begin_t, end_t)
      Source::Map::For.new(loc(keyword_t), loc(in_t),
                           loc(begin_t), loc(end_t),
                           loc(keyword_t).join(loc(end_t)))
    end

    def rescue_body_map(keyword_t, exc_list_e, assoc_t,
                        exc_var_e, then_t,
                        compstmt_e)
      end_l = compstmt_e.loc.expression if compstmt_e
      end_l = loc(then_t)               if end_l.nil? && then_t
      end_l = exc_var_e.loc.expression  if end_l.nil? && exc_var_e
      end_l = exc_list_e.loc.expression if end_l.nil? && exc_list_e
      end_l = loc(keyword_t)            if end_l.nil?

      Source::Map::RescueBody.new(loc(keyword_t), loc(assoc_t), loc(then_t),
                                  loc(keyword_t).join(end_l))
    end

    def eh_keyword_map(compstmt_e, keyword_t, body_es,
                       else_t, else_e)
      if compstmt_e.nil?
        if keyword_t.nil?
          begin_l = body_es.first.loc.expression
        else
          begin_l = loc(keyword_t)
        end
      else
        begin_l = compstmt_e.loc.expression
      end

      if else_t
        if else_e.nil?
          end_l = loc(else_t)
        else
          end_l = else_e.loc.expression
        end
      elsif !body_es.last.nil?
        end_l = body_es.last.loc.expression
      else
        end_l = loc(keyword_t)
      end

      Source::Map::Condition.new(loc(keyword_t), nil, loc(else_t), nil,
                                 begin_l.join(end_l))
    end

    def guard_map(keyword_t, guard_body_e)
      keyword_l = loc(keyword_t)
      guard_body_l = guard_body_e.loc.expression

      Source::Map::Keyword.new(keyword_l, nil, nil, keyword_l.join(guard_body_l))
    end

    #
    # HELPERS
    #

    # Extract a static string from e.g. a regular expression,
    # honoring the fact that MRI expands interpolations like #{""}
    # at parse time.
    def static_string(nodes)
      nodes.map do |node|
        case node.type
        when :str
          node.children[0]
        when :begin
          if (string = static_string(node.children))
            string
          else
            return nil
          end
        else
          return nil
        end
      end.join
    end

    def static_regexp(parts, options)
      source = static_string(parts)
      return nil if source.nil?

      source = case
      when options.children.include?(:u)
        source.encode(Encoding::UTF_8)
      when options.children.include?(:e)
        source.encode(Encoding::EUC_JP)
      when options.children.include?(:s)
        source.encode(Encoding::WINDOWS_31J)
      when options.children.include?(:n)
        source.encode(Encoding::BINARY)
      else
        source
      end

      begin
        old_verbose, $VERBOSE = $VERBOSE, nil
        Regexp.new(source, (Regexp::EXTENDED if options.children.include?(:x)))
      ensure
        $VERBOSE = old_verbose
      end
    end

    def static_regexp_node(node)
      if node.type == :regexp
        if @parser.version >= 33 && node.children[0..-2].any? { |child| child.type != :str }
          return nil
        end

        parts, options = node.children[0..-2], node.children[-1]
        static_regexp(parts, options)
      end
    end

    def collapse_string_parts?(parts)
      parts.one? &&
          [:str, :dstr].include?(parts.first.type)
    end

    def value(token)
      token[0]
    end

    def string_value(token)
      unless token[0].valid_encoding?
        diagnostic(:error, :invalid_encoding, nil, token[1])
      end

      token[0]
    end

    def loc(token)
      # Pass through `nil`s and return nil for tNL.
      token[1] if token && token[0]
    end

    def diagnostic(type, reason, arguments, location, highlights=[])
      @parser.diagnostics.process(
          Diagnostic.new(type, reason, arguments, location, highlights))

      if type == :error
        @parser.send :yyerror
      end
    end

    def validate_definee(definee)
      case definee.type
      when :int, :str, :dstr, :sym, :dsym,
           :regexp, :array, :hash

        diagnostic :error, :singleton_literal, nil, definee.loc.expression
        false
      else
        true
      end
    end

    def rewrite_hash_args_to_kwargs(args)
      if args.any? && kwargs?(args.last)
        # foo(..., bar: baz)
        args[args.length - 1] = args[args.length - 1].updated(:kwargs)
      elsif args.length > 1 && args.last.type == :block_pass && kwargs?(args[args.length - 2])
        # foo(..., bar: baz, &blk)
        args[args.length - 2] = args[args.length - 2].updated(:kwargs)
      end
    end

    def kwargs?(node)
      node.type == :hash && node.loc.begin.nil? && node.loc.end.nil?
    end
  end

end
