# frozen_string_literal: true
# encoding: UTF-8

$DEBUG = true if ENV["DEBUG"]

class RubyLexer
  # :stopdoc:
  EOF = :eof_haha!

  ESCAPES = {
    "a"    => "\007",
    "b"    => "\010",
    "e"    => "\033",
    "f"    => "\f",
    "n"    => "\n",
    "r"    => "\r",
    "s"    => " ",
    "t"    => "\t",
    "v"    => "\13",
    "\\"   => '\\',
    "\n"   => "",
    "C-\?" => 127.chr,
    "c\?"  => 127.chr,
  }

  HAS_ENC = "".respond_to? :encoding

  BTOKENS = {
    ".."  => :tBDOT2,
    "..." => :tBDOT3,
  }

  TOKENS = {
    "!"   => :tBANG,
    "!="  => :tNEQ,
    "!@"  => :tBANG,
    "!~"  => :tNMATCH,
    ","   => :tCOMMA,
    ".."  => :tDOT2,
    "..." => :tDOT3,
    "="   => :tEQL,
    "=="  => :tEQ,
    "===" => :tEQQ,
    "=>"  => :tASSOC,
    "=~"  => :tMATCH,
    "->"  => :tLAMBDA,
  }

  PERCENT_END = {
    "(" => ")",
    "[" => "]",
    "{" => "}",
    "<" => ">",
  }

  SIMPLE_RE_META = /[\$\*\+\.\?\^\|\)\]\}\>]/

  @@regexp_cache = Hash.new { |h, k| h[k] = Regexp.new(Regexp.escape(k)) }
  @@regexp_cache[nil] = nil

  def regexp_cache
    @@regexp_cache
  end

  if $DEBUG then
    attr_reader :lex_state

    def lex_state= o
      return if @lex_state == o

      from = ""
      if ENV["VERBOSE"]
        path = caller[0]
        path = caller[1] if path =~ /result/
        path, line, *_ = path.split(/:/)
        path.delete_prefix! File.dirname File.dirname __FILE__
        from = " at .%s:%s" % [path, line]
      end

      warn "lex_state: %p -> %p%s" % [lex_state, o, from]

      @lex_state = o
    end
  end

  # :startdoc:

  attr_accessor :lex_state unless $DEBUG

  attr_accessor :brace_nest
  attr_accessor :cmdarg
  attr_accessor :command_start
  attr_accessor :cmd_state # temporary--ivar to avoid passing everywhere
  attr_accessor :last_state
  attr_accessor :cond
  attr_accessor :old_ss
  attr_accessor :old_lineno

  # these are generated via ruby_lexer.rex: ss, lineno

  ##
  # Additional context surrounding tokens that both the lexer and
  # grammar use.

  attr_accessor :lex_strterm
  attr_accessor :lpar_beg
  attr_accessor :paren_nest
  attr_accessor :parser # HACK for very end of lexer... *sigh*
  attr_accessor :space_seen
  attr_accessor :string_buffer
  attr_accessor :string_nest

  # Last token read via next_token.
  attr_accessor :token

  attr_writer :comments

  def initialize _ = nil
    @lex_state = nil # remove one warning under $DEBUG
    self.lex_state = EXPR_NONE

    self.cond   = RubyParserStuff::StackState.new(:cond, $DEBUG)
    self.cmdarg = RubyParserStuff::StackState.new(:cmdarg, $DEBUG)
    self.ss     = RPStringScanner.new ""

    reset
  end

  def arg_ambiguous
    self.warning "Ambiguous first argument. make sure."
  end

  def arg_state
    is_after_operator? ? EXPR_ARG : EXPR_BEG
  end

  def ignore_body_comments
    @comments.clear
  end

  def comments # TODO: remove this... maybe comment_string + attr_accessor
    c = @comments.join
    @comments.clear
    c
  end

  def debug n
    raise "debug #{n}"
  end

  def expr_dot?
    lex_state =~ EXPR_DOT
  end

  def expr_fname? # REFACTOR
    lex_state =~ EXPR_FNAME
  end

  def expr_result token, text
    cond.push false
    cmdarg.push false
    result EXPR_BEG, token, text
  end

  def in_fname? # REFACTOR
    lex_state =~ EXPR_FNAME
  end

  def int_with_base base
    rb_compile_error "Invalid numeric format" if matched =~ /__/

    text = matched
    case
    when text.end_with?("ri")
      result EXPR_NUM, :tIMAGINARY, Complex(0, Rational(text.chop.chop.to_i(base)))
    when text.end_with?("r")
      result EXPR_NUM, :tRATIONAL, Rational(text.chop.to_i(base))
    when text.end_with?("i")
      result EXPR_NUM, :tIMAGINARY, Complex(0, text.chop.to_i(base))
    else
      result EXPR_NUM, :tINTEGER, text.to_i(base)
    end
  end

  def is_after_operator?
    lex_state =~ EXPR_FNAME|EXPR_DOT
  end

  def is_arg?
    lex_state =~ EXPR_ARG_ANY
  end

  def is_beg?
    lex_state =~ EXPR_BEG_ANY || lex_state == EXPR_LAB # yes, == EXPR_LAB
  end

  def is_end?
    lex_state =~ EXPR_END_ANY
  end

  def is_label_possible?
    (lex_state =~ EXPR_LABEL|EXPR_ENDFN && !cmd_state) || is_arg?
  end

  def is_label_suffix?
    check(/:(?!:)/)
  end

  def is_space_arg? c = "x"
    is_arg? and space_seen and c !~ /\s/
  end

  def lambda_beginning?
    lpar_beg && lpar_beg == paren_nest
  end

  def is_local_id id
    # maybe just make this false for now
    self.parser.env[id.to_sym] == :lvar # HACK: this isn't remotely right
  end

  def lvar_defined? id
    # TODO: (dyna_in_block? && dvar_defined?(id)) || local_id?(id)
    self.parser.env[id.to_sym] == :lvar
  end

  def not_end?
    not is_end?
  end

  def possibly_escape_string text, check
    content = match[1]

    if text =~ check then
      unescape_string content
    else
      content.gsub(/\\\\/, "\\").gsub(/\\\'/, "'")
    end
  end

  def process_amper text
    token = if is_arg? && space_seen && !check(/\s/) then
               warning("`&' interpreted as argument prefix")
               :tAMPER
             elsif lex_state =~ EXPR_BEG|EXPR_MID then
               :tAMPER
             else
               :tAMPER2
             end

    result :arg_state, token, "&"
  end

  def process_backref text
    token = match[1].to_sym
    # TODO: can't do lineno hack w/ symbol
    result EXPR_END, :tBACK_REF, token
  end

  def process_begin text
    @comments << matched

    unless scan(/.*?\n=end( |\t|\f)*[^\n]*(\n|\z)/m) then
      @comments.clear
      rb_compile_error("embedded document meets end of file")
    end

    @comments << matched
    self.lineno += matched.count("\n") # HACK?

    nil # TODO
  end

  def process_brace_close text
    case matched
    when "}" then
      self.brace_nest -= 1
      return :tSTRING_DEND, matched if brace_nest < 0
    end

    # matching compare/parse26.y:8099
    cond.pop
    cmdarg.pop

    case matched
    when "}" then
      self.lex_state   = ruby24minus? ? EXPR_ENDARG : EXPR_END
      return :tRCURLY, matched
    when "]" then
      self.paren_nest -= 1
      self.lex_state   = ruby24minus? ? EXPR_ENDARG : EXPR_END
      return :tRBRACK, matched
    when ")" then
      self.paren_nest -= 1
      self.lex_state   = EXPR_ENDFN
      return :tRPAREN, matched
    else
      raise "Unknown bracing: #{matched.inspect}"
    end
  end

  def process_brace_open text
    # matching compare/parse23.y:8694
    self.brace_nest += 1

    if lambda_beginning? then
      self.lpar_beg = nil
      self.paren_nest -= 1 # close arg list when lambda opens body

      return expr_result(:tLAMBEG, "{")
    end

    token = case
            when lex_state =~ EXPR_LABELED then
              :tLBRACE     # hash
            when lex_state =~ EXPR_ARG_ANY|EXPR_END|EXPR_ENDFN then
              :tLCURLY     # block (primary) "{" in parse.y
            when lex_state =~ EXPR_ENDARG then
              :tLBRACE_ARG # block (expr)
            else
              :tLBRACE     # hash
            end

    state = token == :tLBRACE_ARG ? EXPR_BEG : EXPR_PAR
    self.command_start = true if token != :tLBRACE

    cond.push false
    cmdarg.push false
    result state, token, text
  end

  def process_colon1 text
    # ?: / then / when
    if is_end? || check(/\s/) then
      return result EXPR_BEG, :tCOLON, text
    end

    case
    when scan(/\'/) then
      string STR_SSYM, matched
    when scan(/\"/) then
      string STR_DSYM, matched
    end

    result EXPR_FNAME, :tSYMBEG, text
  end

  def process_colon2 text
    if is_beg? || lex_state =~ EXPR_CLASS || is_space_arg? then
      result EXPR_BEG, :tCOLON3, text
    else
      result EXPR_DOT, :tCOLON2, text
    end
  end

  def process_dots text
    tokens = ruby27plus? && is_beg? ? BTOKENS : TOKENS

    result EXPR_BEG, tokens[text], text
  end

  def process_float text
    rb_compile_error "Invalid numeric format" if text =~ /__/

    case
    when text.end_with?("ri")
      result EXPR_NUM, :tIMAGINARY, Complex(0, Rational(text.chop.chop))
    when text.end_with?("i")
      result EXPR_NUM, :tIMAGINARY, Complex(0, text.chop.to_f)
    when text.end_with?("r")
      result EXPR_NUM, :tRATIONAL,  Rational(text.chop)
    else
      result EXPR_NUM, :tFLOAT, text.to_f
    end
  end

  def process_gvar text
    if parser.class.version > 20 && text == "$-" then
      rb_compile_error "unexpected $undefined"
    end

    result EXPR_END, :tGVAR, text
  end

  def process_gvar_oddity text
    rb_compile_error "#{text.inspect} is not allowed as a global variable name"
  end

  def process_ivar text
    tok_id = text =~ /^@@/ ? :tCVAR : :tIVAR
    result EXPR_END, tok_id, text
  end

  def process_label text
    symbol = possibly_escape_string text, /^\"/

    result EXPR_LAB, :tLABEL, symbol
  end

  def process_label_or_string text
    if @was_label && text =~ /:\Z/ then
      @was_label = nil
      return process_label text
    elsif text =~ /:\Z/ then
      self.pos -= 1 # put back ":"
      text = text[0..-2]
    end

    orig_line = lineno
    str = text[1..-2].gsub(/\\\\/, "\\").gsub(/\\\'/, "\'")
    self.lineno += str.count("\n")

    result EXPR_END, :tSTRING, str, orig_line
  end

  def process_lchevron text
    if (lex_state !~ EXPR_DOT|EXPR_CLASS &&
        !is_end? &&
        (!is_arg? || lex_state =~ EXPR_LABELED || space_seen)) then
      tok = self.heredoc_identifier
      return tok if tok
    end

    if is_after_operator? then
      self.lex_state = EXPR_ARG
    else
      self.command_start = true if lex_state =~ EXPR_CLASS
      self.lex_state = EXPR_BEG
    end

    result lex_state, :tLSHFT, "\<\<"
  end

  def process_newline_or_comment text    # ../compare/parse30.y:9126 ish
    c = matched

    if c == "#" then
      self.pos -= 1

      while scan(/\s*\#.*(\n+|\z)/) do
        self.lineno += matched.count "\n"
        @comments << matched.gsub(/^ +#/, "#").gsub(/^ +$/, "")
      end

      return nil if end_of_stream?
    end

    c = (lex_state =~ EXPR_BEG|EXPR_CLASS|EXPR_FNAME|EXPR_DOT &&
         lex_state !~ EXPR_LABELED)
    if c || self.lex_state == EXPR_LAB then # yes, == EXPR_LAB
      # ignore if !fallthrough?
      if !c && parser.in_kwarg then
        # normal newline
        self.command_start = true
        return result EXPR_BEG, :tNL, nil
      else
        maybe_pop_stack
        return # goto retry
      end
    end

    if scan(/[\ \t\r\f\v]+/) then
      self.space_seen = true
    end

    if check(/#/) then
      return # goto retry
    elsif check(/&\.|\.(?!\.)/) then # C version is a hellish obfuscated xnor
      return # goto retry
    end

    self.command_start = true

    result EXPR_BEG, :tNL, nil
  end

  def process_nthref text
    # TODO: can't do lineno hack w/ number
    result EXPR_END, :tNTH_REF, match[1].to_i
  end

  def process_paren text
    token = if is_beg? then
              :tLPAREN
            elsif !space_seen then
              # foo( ... ) => method call, no ambiguity
              :tLPAREN2
            elsif is_space_arg? then
              :tLPAREN_ARG
            elsif lex_state =~ EXPR_ENDFN && !lambda_beginning? then
              # TODO:
              # warn("parentheses after method name is interpreted as " \
              #      "an argument list, not a decomposed argument")
              :tLPAREN2
            else
              :tLPAREN2 # plain "(" in parse.y
            end

    self.paren_nest += 1

    cond.push false
    cmdarg.push false
    result EXPR_PAR, token, text
  end

  def process_percent text
    case
    when is_beg? then
      process_percent_quote
    when scan(/\=/)
      result EXPR_BEG, :tOP_ASGN, "%"
    when is_space_arg?(check(/\s/)) || (lex_state =~ EXPR_FITEM && check(/s/))
      process_percent_quote
    else
      result :arg_state, :tPERCENT, "%"
    end
  end

  def process_plus_minus text
    sign = matched
    utype, type = if sign == "+" then
                    [:tUPLUS, :tPLUS]
                  else
                    [:tUMINUS, :tMINUS]
                  end

    if is_after_operator? then
      if scan(/@/) then
        return result(EXPR_ARG, utype, "#{sign}@")
      else
        return result(EXPR_ARG, type, sign)
      end
    end

    return result(EXPR_BEG, :tOP_ASGN, sign) if scan(/\=/)

    if is_beg? || (is_arg? && space_seen && !check(/\s/)) then
      arg_ambiguous if is_arg?

      if check(/\d/) then
        return nil if utype == :tUPLUS
        return result EXPR_BEG, :tUMINUS_NUM, sign
      end

      return result EXPR_BEG, utype, sign
    end

    result EXPR_BEG, type, sign
  end

  def process_questionmark text
    if is_end? then
      return result EXPR_BEG, :tEH, "?"
    end

    if end_of_stream? then
      rb_compile_error "incomplete character syntax: parsed #{text.inspect}"
    end

    if check(/\s|\v/) then
      unless is_arg? then
        c2 = { " " => "s",
              "\n" => "n",
              "\t" => "t",
              "\v" => "v",
              "\r" => "r",
              "\f" => "f" }[matched]

        if c2 then
          warning("invalid character syntax; use ?\\" + c2)
        end
      end

      # ternary
      return result EXPR_BEG, :tEH, "?"
    elsif check(/\w(?=\w)/) then # ternary, also
      return result EXPR_BEG, :tEH, "?"
    end

    c = if scan(/\\/) then
          self.read_escape
        else
          getch
        end

    result EXPR_END, :tSTRING, c
  end

  def process_simple_string text
    orig_line = lineno
    self.lineno += text.count("\n")

    str = unescape_string text[1..-2]

    result EXPR_END, :tSTRING, str, orig_line
  end

  def process_slash text
    if is_beg? then
      string STR_REGEXP, matched

      return result nil, :tREGEXP_BEG, "/"
    end

    if scan(/\=/) then
      return result(EXPR_BEG, :tOP_ASGN, "/")
    end

    if is_arg? && space_seen then
      unless scan(/\s/) then
        arg_ambiguous
        string STR_REGEXP, "/"
        return result(nil, :tREGEXP_BEG, "/")
      end
    end

    result :arg_state, :tDIVIDE, "/"
  end

  def process_square_bracket text
    self.paren_nest += 1

    token = nil

    if is_after_operator? then
      case
      when scan(/\]\=/) then
        self.paren_nest -= 1 # HACK? I dunno, or bug in MRI
        return result EXPR_ARG, :tASET, "[]="
      when scan(/\]/) then
        self.paren_nest -= 1 # HACK? I dunno, or bug in MRI
        return result EXPR_ARG, :tAREF, "[]"
      else
        rb_compile_error "unexpected '['"
      end
    elsif is_beg? then
      token = :tLBRACK
    elsif is_arg? && (space_seen || lex_state =~ EXPR_LABELED) then
      token = :tLBRACK
    else
      token = :tLBRACK2
    end

    cond.push false
    cmdarg.push false
    result EXPR_PAR, token, text
  end

  def process_symbol text
    symbol = possibly_escape_string text, /^:\"/ # stupid emacs

    result EXPR_LIT, :tSYMBOL, symbol
  end

  def process_token text
    # matching: parse_ident in compare/parse23.y:7989
    # FIX: remove: self.last_state = lex_state

    token = self.token = text
    token << matched if scan(/[\!\?](?!=)/)

    tok_id =
      case
      when token =~ /[!?]$/ then
        :tFID
      when lex_state =~ EXPR_FNAME && scan(/=(?:(?![~>=])|(?==>))/) then
        # ident=, not =~ => == or followed by =>
        # TODO test lexing of a=>b vs a==>b
        token << matched
        :tIDENTIFIER
      when token =~ /^[A-Z]/ then
        :tCONSTANT
      else
        :tIDENTIFIER
      end

    if is_label_possible? and is_label_suffix? then
      scan(/:/)
      return result EXPR_LAB, :tLABEL, token
    end

    # TODO: mb == ENC_CODERANGE_7BIT && lex_state !~ EXPR_DOT
    if lex_state !~ EXPR_DOT then
      # See if it is a reserved word.
      keyword = RubyParserStuff::Keyword.keyword token

      return process_token_keyword keyword if keyword
    end

    # matching: compare/parse30.y:9039
    state = if lex_state =~ EXPR_BEG_ANY|EXPR_ARG_ANY|EXPR_DOT then
              cmd_state ? EXPR_CMDARG : EXPR_ARG
            elsif lex_state =~ EXPR_FNAME then
              EXPR_ENDFN
            else
              EXPR_END
            end
    self.lex_state = state

    tok_id = :tIDENTIFIER if tok_id == :tCONSTANT && is_local_id(token)

    if last_state !~ EXPR_DOT|EXPR_FNAME and
        (tok_id == :tIDENTIFIER) and # not EXPR_FNAME, not attrasgn
        lvar_defined?(token) then
      state = EXPR_END|EXPR_LABEL
    end

    result state, tok_id, token
  end

  def process_token_keyword keyword
    # matching MIDDLE of parse_ident in compare/parse23.y:8046
    state = lex_state

    return result(EXPR_ENDFN, keyword.id0, token) if lex_state =~ EXPR_FNAME

    self.lex_state = keyword.state
    self.command_start = true if lex_state =~ EXPR_BEG

    case
    when keyword.id0 == :kDO then # parse26.y line 7591
      case
      when lambda_beginning? then
        self.lpar_beg = nil # lambda_beginning? == FALSE in the body of "-> do ... end"
        self.paren_nest -= 1 # TODO: question this?
        result lex_state, :kDO_LAMBDA, token
      when cond.is_in_state then
        result lex_state, :kDO_COND, token
      when cmdarg.is_in_state && state != EXPR_CMDARG then
        result lex_state, :kDO_BLOCK, token
      else
        result lex_state, :kDO, token
      end
    when state =~ EXPR_PAD then
      result lex_state, keyword.id0, token
    when keyword.id0 != keyword.id1 then
      result EXPR_PAR, keyword.id1, token
    else
      result lex_state, keyword.id1, token
    end
  end

  def process_underscore text
    self.unscan # put back "_"

    if beginning_of_line? && scan(/\__END__(\r?\n|\Z)/) then
      ss.terminate
      [RubyLexer::EOF, RubyLexer::EOF]
    elsif scan(/#{IDENT_CHAR}+/) then
      process_token matched
    end
  end

  def rb_compile_error msg
    msg += ". near line #{self.lineno}: #{self.rest[/^.*/].inspect}"
    raise RubyParser::SyntaxError, msg
  end

  def reset
    self.lineno        = 1
    self.brace_nest    = 0
    self.command_start = true
    self.comments      = []
    self.lex_state     = EXPR_NONE
    self.lex_strterm   = nil
    self.lpar_beg      = nil
    self.paren_nest    = 0
    self.space_seen    = false
    self.string_nest   = 0
    self.token         = nil
    self.string_buffer = []
    self.old_ss        = nil
    self.old_lineno    = nil

    self.cond.reset
    self.cmdarg.reset
  end

  def result new_state, token, text, line = self.lineno # :nodoc:
    new_state = self.arg_state if new_state == :arg_state
    self.lex_state = new_state if new_state

    [token, [text, line]]
  end

  def ruby22_label?
    ruby22plus? and is_label_possible?
  end

  def ruby22plus?
    parser.class.version >= 22
  end

  def ruby23plus?
    parser.class.version >= 23
  end

  def ruby24minus?
    parser.class.version <= 24
  end

  def ruby27plus?
    parser.class.version >= 27
  end

  def space_vs_beginning space_type, beg_type, fallback
    if is_space_arg? check(/./m) then
      warning "`**' interpreted as argument prefix"
      space_type
    elsif is_beg? then
      beg_type
    else
      # TODO: warn_balanced("**", "argument prefix");
      fallback
    end
  end

  def unescape_string str
    str = str.gsub(ESC) { unescape($1).b.force_encoding Encoding::UTF_8 }
    if str.valid_encoding?
      str
    else
      str.b
    end
  end

  def unescape s
    r = ESCAPES[s]

    return r if r

    x = case s
        when /^[0-7]{1,3}/ then
          ($&.to_i(8) & 0xFF).chr
        when /^x([0-9a-fA-F]{1,2})/ then
          $1.to_i(16).chr
        when /^M-(.)/ then
          ($1[0].ord | 0x80).chr
        when /^(C-|c)(.)/ then
          ($2[0].ord & 0x9f).chr
        when /^[89a-f]/i then # bad octal or hex... ignore? that's what MRI does :(
          s
        when /^[McCx0-9]/ then
          rb_compile_error("Invalid escape character syntax")
        when /u(\h{4})/ then
          [$1.delete("{}").to_i(16)].pack("U")
        when /u(\h{1,3})/ then
          rb_compile_error("Invalid escape character syntax")
        when /u\{(\h+(?:\s+\h+)*)\}/ then
          $1.split.map { |cp| cp.to_i(16) }.pack("U*")
        else
          s
        end
    x
  end

  def warning s
    # do nothing for now
  end

  def was_label?
    @was_label = ruby22_label?
    true
  end

  class State
    attr_accessor :n
    attr_accessor :names

    # TODO: take a shared hash of strings for inspect/to_s
    def initialize o, names
      raise ArgumentError, "bad state: %p" % [o] unless Integer === o # TODO: remove

      self.n = o
      self.names = names
    end

    def == o
      self.equal?(o) || (o.class == self.class && o.n == self.n)
    end

    def =~ v
      (self.n & v.n) != 0
    end

    def | v
      raise ArgumentError, "Incompatible State: %p vs %p" % [self, v] unless
        self.names == v.names
      self.class.new(self.n | v.n, self.names)
    end

    def inspect
      return "Value(0)" if n.zero? # HACK?

      names.map { |v, k| k if self =~ v }.
        compact.
        join("|").
        gsub(/(?:EXPR_|STR_(?:FUNC_)?)/, "")
    end

    alias to_s inspect

    module Values
      expr_names = {}

      EXPR_NONE    = State.new    0x0, expr_names
      EXPR_BEG     = State.new    0x1, expr_names
      EXPR_END     = State.new    0x2, expr_names
      EXPR_ENDARG  = State.new    0x4, expr_names
      EXPR_ENDFN   = State.new    0x8, expr_names
      EXPR_ARG     = State.new   0x10, expr_names
      EXPR_CMDARG  = State.new   0x20, expr_names
      EXPR_MID     = State.new   0x40, expr_names
      EXPR_FNAME   = State.new   0x80, expr_names
      EXPR_DOT     = State.new  0x100, expr_names
      EXPR_CLASS   = State.new  0x200, expr_names
      EXPR_LABEL   = State.new  0x400, expr_names
      EXPR_LABELED = State.new  0x800, expr_names
      EXPR_FITEM   = State.new 0x1000, expr_names

      EXPR_BEG_ANY = EXPR_BEG | EXPR_MID    | EXPR_CLASS
      EXPR_ARG_ANY = EXPR_ARG | EXPR_CMDARG
      EXPR_END_ANY = EXPR_END | EXPR_ENDARG | EXPR_ENDFN

      # extra fake lex_state names to make things a bit cleaner

      EXPR_LAB = EXPR_ARG|EXPR_LABELED
      EXPR_LIT = EXPR_END|EXPR_ENDARG
      EXPR_PAR = EXPR_BEG|EXPR_LABEL
      EXPR_PAD = EXPR_BEG|EXPR_LABELED

      EXPR_NUM = EXPR_LIT

      expr_names.merge!(EXPR_NONE    => "EXPR_NONE",
                        EXPR_BEG     => "EXPR_BEG",
                        EXPR_END     => "EXPR_END",
                        EXPR_ENDARG  => "EXPR_ENDARG",
                        EXPR_ENDFN   => "EXPR_ENDFN",
                        EXPR_ARG     => "EXPR_ARG",
                        EXPR_CMDARG  => "EXPR_CMDARG",
                        EXPR_MID     => "EXPR_MID",
                        EXPR_FNAME   => "EXPR_FNAME",
                        EXPR_DOT     => "EXPR_DOT",
                        EXPR_CLASS   => "EXPR_CLASS",
                        EXPR_LABEL   => "EXPR_LABEL",
                        EXPR_LABELED => "EXPR_LABELED",
                        EXPR_FITEM   => "EXPR_FITEM")

      # ruby constants for strings

      str_func_names = {}

      STR_FUNC_BORING = State.new 0x00,    str_func_names
      STR_FUNC_ESCAPE = State.new 0x01,    str_func_names
      STR_FUNC_EXPAND = State.new 0x02,    str_func_names
      STR_FUNC_REGEXP = State.new 0x04,    str_func_names
      STR_FUNC_QWORDS = State.new 0x08,    str_func_names
      STR_FUNC_SYMBOL = State.new 0x10,    str_func_names
      STR_FUNC_INDENT = State.new 0x20,    str_func_names # <<-HEREDOC
      STR_FUNC_LABEL  = State.new 0x40,    str_func_names
      STR_FUNC_LIST   = State.new 0x4000,  str_func_names
      STR_FUNC_TERM   = State.new 0x8000,  str_func_names
      STR_FUNC_DEDENT = State.new 0x10000, str_func_names # <<~HEREDOC

      # TODO: check parser25.y on how they do STR_FUNC_INDENT

      STR_SQUOTE = STR_FUNC_BORING
      STR_DQUOTE = STR_FUNC_EXPAND
      STR_XQUOTE = STR_FUNC_EXPAND
      STR_REGEXP = STR_FUNC_REGEXP | STR_FUNC_ESCAPE | STR_FUNC_EXPAND
      STR_SWORD  = STR_FUNC_QWORDS | STR_FUNC_LIST
      STR_DWORD  = STR_FUNC_QWORDS | STR_FUNC_EXPAND | STR_FUNC_LIST
      STR_SSYM   = STR_FUNC_SYMBOL
      STR_DSYM   = STR_FUNC_SYMBOL | STR_FUNC_EXPAND
      STR_LABEL  = STR_FUNC_LABEL

      str_func_names.merge!(STR_FUNC_ESCAPE => "STR_FUNC_ESCAPE",
                            STR_FUNC_EXPAND => "STR_FUNC_EXPAND",
                            STR_FUNC_REGEXP => "STR_FUNC_REGEXP",
                            STR_FUNC_QWORDS => "STR_FUNC_QWORDS",
                            STR_FUNC_SYMBOL => "STR_FUNC_SYMBOL",
                            STR_FUNC_INDENT => "STR_FUNC_INDENT",
                            STR_FUNC_LABEL  => "STR_FUNC_LABEL",
                            STR_FUNC_LIST   => "STR_FUNC_LIST",
                            STR_FUNC_TERM   => "STR_FUNC_TERM",
                            STR_FUNC_DEDENT => "STR_FUNC_DEDENT",
                            STR_SQUOTE      => "STR_SQUOTE")
    end

    include Values
  end

  include State::Values
end

class RubyLexer
  module SSWrapper
    def string= s
      ss.string= s
    end

    def beginning_of_line?
      ss.bol?
    end

    alias bol? beginning_of_line? # to make .rex file more readable

    def check re
      maybe_pop_stack

      ss.check re
    end

    def end_of_stream?
      ss.eos?
    end

    alias eos? end_of_stream?

    def getch
      c = ss.getch
      c = ss.getch if c == "\r" && ss.peek(1) == "\n"
      c
    end

    def match
      ss
    end

    def matched
      ss.matched
    end

    def in_heredoc?
      !!self.old_ss
    end

    def maybe_pop_stack
      if ss.eos? && in_heredoc? then
        self.ss_pop
        self.lineno_pop
      end
    end

    def pos
      ss.pos
    end

    def pos= n
      ss.pos = n
    end

    def rest
      ss.rest
    end

    def scan re
      maybe_pop_stack

      ss.scan re
    end

    def scanner_class # TODO: design this out of oedipus_lex. or something.
      RPStringScanner
    end

    def ss_string
      ss.string
    end

    def ss_string= s
      raise "Probably not"
      ss.string = s
    end

    def unscan
      ss.unscan
    end
  end

  include SSWrapper
end

class RubyLexer
  module SSStackish
    def lineno_push new_lineno
      self.old_lineno = self.lineno
      self.lineno     = new_lineno
    end

    def lineno_pop
      self.lineno     = self.old_lineno
      self.old_lineno = nil
    end

    def ss= o
      raise "Clearing ss while in heredoc!?!" if in_heredoc?
      @old_ss = nil
      super
    end

    def ss_push new_ss
      @old_ss = self.ss
      @ss     = new_ss
    end

    def ss_pop
      @ss     = self.old_ss
      @old_ss = nil
    end
  end

  prepend SSStackish
end

if ENV["RP_STRTERM_DEBUG"] then
  class RubyLexer
    def d o
      $stderr.puts o.inspect
    end

    alias old_lex_strterm= lex_strterm=

    def lex_strterm= o
      self.old_lex_strterm= o
      where = caller.first.split(/:/).first(2).join(":")
      $stderr.puts
      d :lex_strterm => [o, where]
    end
  end
end

require_relative "./ruby_lexer.rex.rb"
require_relative "./ruby_lexer_strings.rb"

if ENV["RP_LINENO_DEBUG"] then
  class RubyLexer
    def d o
      $stderr.puts o.inspect
    end

    alias old_lineno= lineno=

    def lineno= n
      self.old_lineno= n
      where = caller.first.split(/:/).first(2).join(":")
      $stderr.puts
      d :lineno => [n, where]
    end
  end
end
