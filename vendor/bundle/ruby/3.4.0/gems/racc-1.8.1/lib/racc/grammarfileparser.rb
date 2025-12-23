#--
#
#
#
# Copyright (c) 1999-2006 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the same terms of ruby.
# see the file "COPYING".
#
#++

require_relative '../racc'
require_relative 'compat'
require_relative 'grammar'
require_relative 'parserfilegenerator'
require_relative 'sourcetext'
require 'stringio'

module Racc

  grammar = Grammar.define {
    g = self

    g.class = seq(:CLASS, :cname, many(:param), :RULE, :rules, option(:END))

    g.cname       = seq(:rubyconst) {|name|
                      @result.params.classname = name
                    }\
                  | seq(:rubyconst, "<", :rubyconst) {|c, _, s|
                      @result.params.classname = c
                      @result.params.superclass = s
                    }

    g.rubyconst   = separated_by1(:colon2, :SYMBOL) {|syms|
                      syms.map {|s| s.to_s }.join('::')
                    }

    g.colon2 = seq(':', ':')

    g.param       = seq(:CONV, many1(:convdef), :END) {|*|
                      #@grammar.end_convert_block   # FIXME
                    }\
                  | seq(:PRECHIGH, many1(:precdef), :PRECLOW) {|*|
                      @grammar.end_precedence_declaration true
                    }\
                  | seq(:PRECLOW, many1(:precdef), :PRECHIGH) {|*|
                      @grammar.end_precedence_declaration false
                    }\
                  | seq(:START, :symbol) {|_, sym|
                      @grammar.start_symbol = sym
                    }\
                  | seq(:TOKEN, :symbols) {|_, syms|
                      syms.each do |s|
                        s.should_terminal
                      end
                    }\
                  | seq(:OPTION, :options) {|_, syms|
                      syms.each do |opt|
                        case opt
                        when 'result_var'
                          @result.params.result_var = true
                        when 'no_result_var'
                          @result.params.result_var = false
                        when 'omit_action_call'
                          @result.params.omit_action_call = true
                        when 'no_omit_action_call'
                          @result.params.omit_action_call = false
                        else
                          raise CompileError, "unknown option: #{opt}"
                        end
                      end
                    }\
                  | seq(:EXPECT, :DIGIT) {|_, num|
                      if @grammar.n_expected_srconflicts
                        raise CompileError, "`expect' seen twice"
                      end
                      @grammar.n_expected_srconflicts = num
                    }\
                  | seq(:ERROR_ON_EXPECT_MISMATCH) {|*|
                      @grammar.error_on_expect_mismatch = true
                    }

    g.convdef     = seq(:symbol, :STRING) {|sym, code|
                      sym.serialized = code
                    }

    g.precdef     = seq(:LEFT, :symbols) {|_, syms|
                      @grammar.declare_precedence :Left, syms
                    }\
                  | seq(:RIGHT, :symbols) {|_, syms|
                      @grammar.declare_precedence :Right, syms
                    }\
                  | seq(:NONASSOC, :symbols) {|_, syms|
                      @grammar.declare_precedence :Nonassoc, syms
                    }

    g.symbols     = seq(:symbol) {|sym|
                      [sym]
                    }\
                  | seq(:symbols, :symbol) {|list, sym|
                      list.push sym
                      list
                    }\
                  | seq(:symbols, "|")

    g.symbol      = seq(:SYMBOL) {|sym| @grammar.intern(sym) }\
                  | seq(:STRING) {|str| @grammar.intern(str) }

    g.options     = many(:SYMBOL) {|syms| syms.map {|s| s.to_s } }

    g.rules       = option(:rules_core) {|list|
                      add_rule_block list  unless list.empty?
                      nil
                    }

    g.rules_core  = seq(:symbol) {|sym|
                      [sym]
                    }\
                  | seq(:rules_core, :rule_item) {|list, i|
                      list.push i
                      list
                    }\
                  | seq(:rules_core, ';') {|list, *|
                      add_rule_block list  unless list.empty?
                      list.clear
                      list
                    }\
                  | seq(:rules_core, ':') {|list, *|
                      next_target = list.pop
                      add_rule_block list  unless list.empty?
                      [next_target]
                    }

    g.rule_item   = seq(:symbol)\
                  | seq("|") {|*|
                      OrMark.new(@scanner.lineno)
                    }\
                  | seq("?") {|*|
                      OptionMark.new(@scanner.lineno)
                    }\
                  | seq("*") {|*|
                      ManyMark.new(@scanner.lineno)
                    }\
                  | seq("+") {|*|
                      Many1Mark.new(@scanner.lineno)
                    }\
                  | seq("(") {|*|
                      GroupStartMark.new(@scanner.lineno)
                    }\
                  | seq(")") {|*|
                      GroupEndMark.new(@scanner.lineno)
                    }\
                  | seq("=", :symbol) {|_, sym|
                      Prec.new(sym, @scanner.lineno)
                    }\
                  | seq(:ACTION) {|src|
                      UserAction.source_text(src)
                    }
  }

  GrammarFileParser = grammar.parser_class

  if grammar.states.srconflict_exist?
    raise 'Racc boot script fatal: S/R conflict in build'
  end
  if grammar.states.rrconflict_exist?
    raise 'Racc boot script fatal: R/R conflict in build'
  end

  class GrammarFileParser   # reopen

    class Result
      def initialize(grammar)
        @grammar = grammar
        @params = ParserFileGenerator::Params.new
      end

      attr_reader :grammar
      attr_reader :params
    end

    def GrammarFileParser.parse_file(filename)
      parse(File.read(filename), filename, 1)
    end

    def GrammarFileParser.parse(src, filename = '-', lineno = 1)
      new().parse(src, filename, lineno)
    end

    def initialize(debug_flags = DebugFlags.new)
      @yydebug = debug_flags.parse
    end

    def parse(src, filename = '-', lineno = 1)
      @filename = filename
      @lineno = lineno
      @scanner = GrammarFileScanner.new(src, @filename)
      @scanner.debug = @yydebug
      @grammar = Grammar.new
      @result = Result.new(@grammar)
      @embedded_action_seq = 0
      yyparse @scanner, :yylex
      parse_user_code
      @result.grammar.init
      @result
    end

    private

    def next_token
      @scanner.scan
    end

    def on_error(tok, val, _values)
      if val.respond_to?(:id2name)
        v = val.id2name
      elsif val.kind_of?(String)
        v = val
      else
        v = val.inspect
      end
      raise CompileError, "#{location()}: unexpected token '#{v}'"
    end

    def location
      "#{@filename}:#{@lineno - 1 + @scanner.lineno}"
    end

    def add_rule_block(list)
      target = list.shift
      case target
      when OrMark, OptionMark, ManyMark, Many1Mark, GroupStartMark, GroupEndMark, UserAction, Prec
        raise CompileError, "#{target.lineno}: unexpected symbol #{target.name}"
      end
      enum = list.each.with_index
      _, sym, idx = _add_rule_block(target, enum)
      if idx
        # sym is Racc::GroupEndMark
        raise "#{sym.lineno}: unexpected symbol ')' at pos=#{idx}"
      end
    end

    def _add_rule_block(target, enum)
      rules = [] # [ [seqs, sprec], .. ]
      curr = []
      sprec = nil
      while (sym, idx = enum.next rescue nil)
        case sym
        when OrMark
          rules << [curr, sprec]
          curr = []
          sprec = nil
        when OptionMark
          curr << _add_option_rule(curr.pop)
        when ManyMark
          curr << _add_many_rule(curr.pop)
        when Many1Mark
          curr << _add_many1_rule(curr.pop)
        when GroupStartMark
          curr << _add_group_rule(enum)
        when GroupEndMark
          rules << [curr, sprec]
          return rules, sym, idx
        when Prec
          raise CompileError, "'=<prec>' used twice in one rule" if sprec
          sprec = sym.symbol
        else
          curr.push sym
        end
      end
      rules << [curr, sprec]
      rules.each do |syms, sprec|
        add_rule target, syms, sprec
      end
      nil
    end


    def _add_option_rule(prev)
      @option_rule_registry ||= {}
      target = @option_rule_registry[prev.to_s]
      return target if target
      target = _gen_target_name("option", prev)
      @option_rule_registry[prev.to_s] = target
      act = UserAction.empty
      @grammar.add Rule.new(target, [], act)
      @grammar.add Rule.new(target, [prev], act)
      target
    end

    def _add_many_rule(prev)
      @many_rule_registry ||= {}
      target = @many_rule_registry[prev.to_s]
      return target if target
      target = _gen_target_name("many", prev)
      @many_rule_registry[prev.to_s] = target
      src = SourceText.new("result = val[1] ? val[1].unshift(val[0]) : val", @filename, @scanner.lineno + 1)
      act = UserAction.source_text(src)
      @grammar.add Rule.new(target, [], act)
      @grammar.add Rule.new(target, [prev, target], act)
      target
    end

    def _add_many1_rule(prev)
      @many1_rule_registry ||= {}
      target = @many1_rule_registry[prev.to_s]
      return target if target
      target = _gen_target_name("many1", prev)
      @many1_rule_registry[prev.to_s] = target
      src = SourceText.new("result = val[1] ? val[1].unshift(val[0]) : val", @filename, @scanner.lineno + 1)
      act = UserAction.source_text(src)
      @grammar.add Rule.new(target, [prev], act)
      @grammar.add Rule.new(target, [prev, target], act)
      target
    end

    def _add_group_rule(enum)
      target = @grammar.intern("-temp-group", true)
      rules, _ = _add_rule_block(target, enum)
      target_name = rules.map{|syms, sprec| syms.join("-")}.join("|")
      @group_rule_registry ||= {}
      unless target = @group_rule_registry[target_name]
        target = @grammar.intern("-group@#{target_name}", true)
        @group_rule_registry[target_name] = target
        src = SourceText.new("result = val", @filename, @scanner.lineno + 1)
        act = UserAction.source_text(src)
        rules.each do |syms, sprec|
          rule = Rule.new(target, syms, act)
          rule.specified_prec = sprec
          @grammar.add rule
        end
      end
      target
    end

    def _gen_target_name(type, sym)
      @grammar.intern("-#{type}@#{sym.value}", true)
    end

    def add_rule(target, list, sprec)
      if list.last.kind_of?(UserAction)
        act = list.pop
      else
        act = UserAction.empty
      end
      list.map! {|s| s.kind_of?(UserAction) ? embedded_action(s) : s }
      rule = Rule.new(target, list, act)
      rule.specified_prec = sprec
      @grammar.add rule
    end

    def embedded_action(act)
      sym = @grammar.intern("@#{@embedded_action_seq += 1}".intern, true)
      @grammar.add Rule.new(sym, [], act)
      sym
    end

    #
    # User Code Block
    #

    def parse_user_code
      line = @scanner.lineno
      _, *blocks = *@scanner.epilogue.split(/^----/)
      blocks.each do |block|
        header, *body = block.lines.to_a
        label0, paths = *header.sub(/\A-+/, '').split('=', 2)
        label = canonical_label(label0)
        (paths ? paths.strip.split(' ') : []).each do |path|
          add_user_code label, SourceText.new(File.read(path), path, 1)
        end
        add_user_code label, SourceText.new(body.join(''), @filename, line + 1)
        line += (1 + body.size)
      end
    end

    USER_CODE_LABELS = {
      'header'  => :header,
      'prepare' => :header,   # obsolete
      'inner'   => :inner,
      'footer'  => :footer,
      'driver'  => :footer    # obsolete
    }

    def canonical_label(src)
      label = src.to_s.strip.downcase.slice(/\w+/)
      unless USER_CODE_LABELS.key?(label)
        raise CompileError, "unknown user code type: #{label.inspect}"
      end
      label
    end

    def add_user_code(label, src)
      @result.params.public_send(USER_CODE_LABELS[label]).push src
    end

  end


  class GrammarFileScanner

    def initialize(str, filename = '-')
      @lines  = str.b.split(/\n|\r\n|\r/)
      @filename = filename
      @lineno = -1
      @line_head   = true
      @in_rule_blk = false
      @in_conv_blk = false
      @in_block = nil
      @epilogue = ''
      @debug = false
      next_line
    end

    attr_reader :epilogue

    def lineno
      @lineno + 1
    end

    attr_accessor :debug

    def yylex(&block)
      unless @debug
        yylex0(&block)
      else
        yylex0 do |sym, tok|
          $stderr.printf "%7d %-10s %s\n", lineno(), sym.inspect, tok.inspect
          yield [sym, tok]
        end
      end
    end

    private

    def yylex0
      begin
        until @line.empty?
          @line.sub!(/\A\s+/, '')
          if /\A\#/ =~ @line
            break
          elsif /\A\/\*/ =~ @line
            skip_comment
          elsif s = reads(/\A[a-zA-Z_]\w*/)
            yield [atom_symbol(s), s.intern]
          elsif s = reads(/\A\d+/)
            yield [:DIGIT, s.to_i]
          elsif ch = reads(/\A./)
            case ch
            when '"', "'"
              yield [:STRING, eval(scan_quoted(ch))]
            when '{'
              lineno = lineno()
              yield [:ACTION, SourceText.new(scan_action(), @filename, lineno)]
            else
              if ch == '|'
                @line_head = false
              end
              yield [ch, ch]
            end
          else
          end
        end
      end while next_line()
      yield nil
    end

    def next_line
      @lineno += 1
      @line = @lines[@lineno]
      if not @line or /\A----/ =~ @line
        @epilogue = @lines.join("\n")
        @lines.clear
        @line = nil
        if @in_block
          @lineno -= 1
          scan_error! sprintf('unterminated %s', @in_block)
        end
        false
      else
        @line.sub!(/(?:\n|\r\n|\r)\z/, '')
        @line_head = true
        true
      end
    end

    ReservedWord = {
      'right'    => :RIGHT,
      'left'     => :LEFT,
      'nonassoc' => :NONASSOC,
      'preclow'  => :PRECLOW,
      'prechigh' => :PRECHIGH,
      'token'    => :TOKEN,
      'convert'  => :CONV,
      'options'  => :OPTION,
      'start'    => :START,
      'expect'   => :EXPECT,
      'error_on_expect_mismatch' => :ERROR_ON_EXPECT_MISMATCH,
      'class'    => :CLASS,
      'rule'     => :RULE,
      'end'      => :END
    }

    def atom_symbol(token)
      if token == 'end'
        symbol = :END
        @in_conv_blk = false
        @in_rule_blk = false
      else
        if @line_head and not @in_conv_blk and not @in_rule_blk
          symbol = ReservedWord[token] || :SYMBOL
        else
          symbol = :SYMBOL
        end
        case symbol
        when :RULE then @in_rule_blk = true
        when :CONV then @in_conv_blk = true
        end
      end
      @line_head = false
      symbol
    end

    def skip_comment
      @in_block = 'comment'
      until m = /\*\//.match(@line)
        next_line
      end
      @line = m.post_match
      @in_block = nil
    end

    $raccs_print_type = false

    def scan_action
      buf = String.new
      nest = 1
      pre = nil
      @in_block = 'action'
      begin
        pre = nil
        if s = reads(/\A\s+/)
          # does not set 'pre'
          buf << s
        end
        until @line.empty?
          if s = reads(/\A[^'"`{}%#\/\$]+/)
            buf << (pre = s)
            next
          end
          case ch = read(1)
          when '{'
            nest += 1
            buf << (pre = ch)
          when '}'
            nest -= 1
            if nest == 0
              @in_block = nil
              buf.sub!(/[ \t\f]+\z/, '')
              return buf
            end
            buf << (pre = ch)
          when '#'   # comment
            buf << ch << @line
            break
          when "'", '"', '`'
            buf << (pre = scan_quoted(ch))
          when '%'
            if literal_head? pre, @line
              # % string, regexp, array
              buf << ch
              case ch = read(1)
              when /[qQx]/n
                buf << ch << (pre = scan_quoted(read(1), '%string'))
              when /wW/n
                buf << ch << (pre = scan_quoted(read(1), '%array'))
              when /s/n
                buf << ch << (pre = scan_quoted(read(1), '%symbol'))
              when /r/n
                buf << ch << (pre = scan_quoted(read(1), '%regexp'))
              when /[a-zA-Z0-9= ]/n   # does not include "_"
                scan_error! "unknown type of % literal '%#{ch}'"
              else
                buf << (pre = scan_quoted(ch, '%string'))
              end
            else
              # operator
              buf << '||op->' if $raccs_print_type
              buf << (pre = ch)
            end
          when '/'
            if literal_head? pre, @line
              # regexp
              buf << (pre = scan_quoted(ch, 'regexp'))
            else
              # operator
              buf << '||op->' if $raccs_print_type
              buf << (pre = ch)
            end
          when '$'   # gvar
            buf << ch << (pre = read(1))
          else
            raise 'racc: fatal: must not happen'
          end
        end
        buf << "\n"
      end while next_line()
      raise 'racc: fatal: scan finished before parser finished'
    end

    def literal_head?(pre, post)
      (!pre || /[a-zA-Z_0-9]/n !~ pre[-1,1]) &&
          !post.empty? && /\A[\s\=]/n !~ post
    end

    def read(len)
      s = @line[0, len]
      @line = @line[len .. -1]
      s
    end

    def reads(re)
      m = re.match(@line) or return nil
      @line = m.post_match
      m[0]
    end

    def scan_quoted(left, tag = 'string')
      buf = left.dup
      buf = "||#{tag}->" + buf if $raccs_print_type
      re = get_quoted_re(left)
      sv, @in_block = @in_block, tag
      begin
        if s = reads(re)
          buf << s
          break
        else
          buf << @line
        end
      end while next_line()
      @in_block = sv
      buf << "<-#{tag}||" if $raccs_print_type
      buf
    end

    LEFT_TO_RIGHT = {
      '(' => ')',
      '{' => '}',
      '[' => ']',
      '<' => '>'
    }

    CACHE = {}

    def get_quoted_re(left)
      term = Regexp.quote(LEFT_TO_RIGHT[left] || left)
      CACHE[left] ||= /\A[^#{term}\\]*(?:\\.[^\\#{term}]*)*#{term}/
    end

    def scan_error!(msg)
      raise CompileError, "#{lineno()}: #{msg}"
    end

  end

end   # module Racc
