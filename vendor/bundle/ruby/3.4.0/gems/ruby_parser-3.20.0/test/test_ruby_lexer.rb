require "minitest/autorun"
require "ruby_lexer"
require "ruby_parser"

class TestRubyLexer < Minitest::Test
  include RubyLexer::State::Values

  attr_accessor :processor, :lex, :parser_class, :lex_state

  alias lexer  lex # lets me copy/paste code from parser
  alias lexer= lex=

  def setup
    self.lex_state = EXPR_BEG
    setup_lexer_class RubyParser.latest.class
  end

  def setup_lexer input, exp_sexp = nil
    setup_new_parser
    lex.ss = RPStringScanner.new(input)
    lex.lex_state = lex_state
  end

  def setup_lexer_class parser_class
    self.parser_class = parser_class
    setup_new_parser
    setup_lexer "blah blah"
  end

  def setup_new_parser
    self.processor = parser_class.new
    self.lex = processor.lexer
  end

  def assert_lex input, exp_sexp, *args
    setup_lexer input
    assert_parse input, exp_sexp if exp_sexp

    yield if block_given?

    args.each_slice(5) do |token, value, state, paren, brace|
      assert_next_lexeme token, value, state, paren, brace
    end

    refute_lexeme
  end

  def assert_lex3 input, exp_sexp, *args, &block
    # TODO: refute_nil exp_sexp, "Get off your lazy butt and write one"

    args = args.each_slice(3).map { |a, b, c| [a, b, c, nil, nil] }.flatten

    assert_lex(input, exp_sexp, *args, &block)
  end

  def refute_lex3 input, *args # TODO: re-sort
    args = args.each_slice(3).map { |a, b, c| [a, b, c, nil, nil] }.flatten

    assert_raises RubyParser::SyntaxError do
      assert_lex(input, nil, *args)
    end
  end

  def assert_lex_fname name, type, end_state = EXPR_ARG # TODO: swap name/type
    assert_lex3("def #{name} ",
                nil,

                :kDEF, "def", EXPR_FNAME,
                type,  name,  end_state)
  end

  def assert_next_lexeme token=nil, value=nil, state=nil, paren=nil, brace=nil
    adv = @lex.next_token

    assert adv, "no more tokens, expecting: %p %p %p %p %p" % [token, value, state, paren, brace]

    act_token, act_value = adv

    msg = message {
      act = [act_token, act_value, @lex.lex_state, @lex.paren_nest, @lex.brace_nest]
      exp = [token, value, state, paren, brace]
      "#{exp.inspect} vs #{act.inspect}"
    }

    act_value = act_value.first if Array === act_value

    assert_equal token, act_token, msg
    case value
    when Float then
      assert_in_epsilon value, act_value, 0.001, msg
    when NilClass then
      assert_nil act_value, msg
    when String then
      assert_equal value, act_value.b.force_encoding(value.encoding), msg
    else
      assert_equal value, act_value, msg
    end
    assert_match state, @lex.lex_state,  msg if state
    assert_equal paren, @lex.paren_nest, msg if paren
    assert_equal brace, @lex.brace_nest, msg if brace
  end

  def assert_parse input, exp_sexp
    assert_equal exp_sexp, processor.class.new.parse(input)
  end

  def assert_read_escape expected, input
    setup_lexer input
    enc = expected.encoding
    assert_equal expected, lex.read_escape.b.force_encoding(enc), input
  end

  def assert_read_escape_bad input # TODO: rename refute_read_escape
    setup_lexer input
    assert_raises RubyParser::SyntaxError do
      lex.read_escape
    end
  end

  def refute_lex input, *args # TODO: re-sort
    args = args.each_slice(2).map { |a, b| [a, b, nil, nil, nil] }.flatten

    assert_raises RubyParser::SyntaxError do
      assert_lex(input, nil, *args)
    end
  end

  def refute_lex5 input, *args
    assert_raises RubyParser::SyntaxError do
      assert_lex(input, *args)
    end
  end

  def refute_lexeme
    x = y = @lex.next_token

    refute x, "not empty: #{y.inspect}: #{@lex.rest.inspect}"
  end

  ## Utility Methods:

  def emulate_string_interpolation
    lex_strterm = lexer.lex_strterm
    string_nest = lexer.string_nest
    brace_nest  = lexer.brace_nest

    lexer.string_nest = 0
    lexer.brace_nest  = 0
    lexer.cond.push false
    lexer.cmdarg.push false

    lexer.lex_strterm = nil
    lexer.lex_state = EXPR_BEG

    yield

    lexer.lex_state = EXPR_ENDARG
    assert_next_lexeme :tSTRING_DEND, "}", EXPR_END|EXPR_ENDARG, 0

    lexer.lex_strterm = lex_strterm
    lexer.lex_state   = EXPR_BEG
    lexer.string_nest = string_nest
    lexer.brace_nest  = brace_nest

    lexer.cond.lexpop
    lexer.cmdarg.lexpop
  end

  ## Tests:

  def test_next_token
    assert_equal [:tIDENTIFIER, ["blah", 1]], @lex.next_token
    assert_equal [:tIDENTIFIER, ["blah", 1]], @lex.next_token
    assert_nil @lex.next_token
  end

  def test_pct_w_backslashes
    ["\t", "\n", "\r", "\v", "\f"].each do |char|
      next if !RubyLexer::HAS_ENC and char == "\v"

      assert_lex("%w[foo#{char}bar]",
                 s(:array, s(:str, "foo"), s(:str, "bar")),

                 :tQWORDS_BEG,     "%w[", EXPR_BEG, 0, 0,
                 :tSTRING_CONTENT, "foo", EXPR_BEG, 0, 0,
                 :tSPACE,          " ",   EXPR_BEG, 0, 0,
                 :tSTRING_CONTENT, "bar", EXPR_BEG, 0, 0,
                 :tSPACE,          "]",   EXPR_BEG, 0, 0,
                 :tSTRING_END,     "]",   EXPR_LIT, 0, 0)
    end
  end

  def test_read_escape
    assert_read_escape "\\",   "\\"
    assert_read_escape "\n",   "n"
    assert_read_escape "\t",   "t"
    assert_read_escape "\r",   "r"
    assert_read_escape "\f",   "f"
    assert_read_escape "\13",  "v"
    assert_read_escape "\0",   "0"
    assert_read_escape "\07",  "a"
    assert_read_escape "\007", "a"
    assert_read_escape "\033", "e"
    assert_read_escape "\377", "377"
    assert_read_escape "\377", "xff"
    assert_read_escape "\010", "b"
    assert_read_escape " ",    "s"
    assert_read_escape "q",    "q" # plain vanilla escape

    assert_read_escape "8", "8" # ugh... mri... WHY?!?
    assert_read_escape "9", "9" # ugh... mri... WHY?!?

    assert_read_escape "$",    "444" # ugh
  end

  def test_read_escape_c
    assert_read_escape "\030", "C-x"
    assert_read_escape "\030", "cx"
    assert_read_escape "\230", 'C-\M-x'
    assert_read_escape "\230", 'c\M-x'

    assert_read_escape "\177", "C-?"
    assert_read_escape "\177", "c?"
  end

  def test_read_escape_errors
    assert_read_escape_bad ""

    assert_read_escape_bad "M"
    assert_read_escape_bad "M-"
    assert_read_escape_bad "Mx"

    assert_read_escape_bad "Cx"
    assert_read_escape_bad "C"
    assert_read_escape_bad "C-"

    assert_read_escape_bad "c"
  end

  def test_read_escape_m
    assert_read_escape "\370", "M-x"
    assert_read_escape "\230", 'M-\C-x'
    assert_read_escape "\230", 'M-\cx'
  end

  def test_ruby21_imaginary_literal
    setup_lexer_class RubyParser::V21

    assert_lex3("1i",      nil, :tIMAGINARY, Complex(0, 1),      EXPR_NUM)
    assert_lex3("0x10i",   nil, :tIMAGINARY, Complex(0, 16),     EXPR_NUM)
    assert_lex3("0o10i",   nil, :tIMAGINARY, Complex(0, 8),      EXPR_NUM)
    assert_lex3("0oi",     nil, :tIMAGINARY, Complex(0, 0),      EXPR_NUM)
    assert_lex3("0b10i",   nil, :tIMAGINARY, Complex(0, 2),      EXPR_NUM)
    assert_lex3("1.5i",    nil, :tIMAGINARY, Complex(0, 1.5),    EXPR_NUM)
    assert_lex3("15e3i",   nil, :tIMAGINARY, Complex(0, 15000),  EXPR_NUM)
    assert_lex3("15e-3i",  nil, :tIMAGINARY, Complex(0, 0.015),  EXPR_NUM)
    assert_lex3("1.5e3i",  nil, :tIMAGINARY, Complex(0, 1500),   EXPR_NUM)
    assert_lex3("1.5e-3i", nil, :tIMAGINARY, Complex(0, 0.0015), EXPR_NUM)

    c010 = Complex(0, 10)
    assert_lex3("-10i", nil,
                :tUMINUS_NUM, "-",  EXPR_BEG,
                :tIMAGINARY,  c010, EXPR_NUM)
  end

  def test_ruby21_imaginary_literal_with_succeeding_keyword
    setup_lexer_class RubyParser::V21

    # 2/4 scenarios are syntax errors on all tested versions so I
    # deleted them.

    assert_lex3("1if", nil,
                :tINTEGER, 1,    EXPR_NUM,
                :kIF_MOD,  "if", EXPR_PAR)
    assert_lex3("1.0if", nil,
                :tFLOAT,  1.0,  EXPR_NUM,
                :kIF_MOD, "if", EXPR_PAR)
  end

  def test_ruby21_rational_imaginary_literal
    setup_lexer_class RubyParser::V21

    assert_lex3 "1ri",      nil, :tIMAGINARY, Complex(0, Rational(1)),        EXPR_NUM
    assert_lex3 "0x10ri",   nil, :tIMAGINARY, Complex(0, Rational(16)),       EXPR_NUM
    assert_lex3 "0o10ri",   nil, :tIMAGINARY, Complex(0, Rational(8)),        EXPR_NUM
    assert_lex3 "0ori",     nil, :tIMAGINARY, Complex(0, Rational(0)),        EXPR_NUM
    assert_lex3 "0b10ri",   nil, :tIMAGINARY, Complex(0, Rational(2)),        EXPR_NUM
    assert_lex3 "1.5ri",    nil, :tIMAGINARY, Complex(0, Rational("1.5")),    EXPR_NUM
    assert_lex3 "15e3ri",   nil, :tIMAGINARY, Complex(0, Rational("15e3")),   EXPR_NUM
    assert_lex3 "15e-3ri",  nil, :tIMAGINARY, Complex(0, Rational("15e-3")),  EXPR_NUM
    assert_lex3 "1.5e3ri",  nil, :tIMAGINARY, Complex(0, Rational("1.5e3")),  EXPR_NUM
    assert_lex3 "1.5e-3ri", nil, :tIMAGINARY, Complex(0, Rational("1.5e-3")), EXPR_NUM

    assert_lex3("-10ri", nil,
                :tUMINUS_NUM, "-", EXPR_BEG,
                :tIMAGINARY, Complex(0, Rational(10)), EXPR_NUM)
  end

  def test_ruby21_rational_literal
    setup_lexer_class RubyParser::V21

    assert_lex3("10r",     nil, :tRATIONAL, Rational(10),        EXPR_NUM)
    assert_lex3("0x10r",   nil, :tRATIONAL, Rational(16),        EXPR_NUM)
    assert_lex3("0o10r",   nil, :tRATIONAL, Rational(8),         EXPR_NUM)
    assert_lex3("0or",     nil, :tRATIONAL, Rational(0),         EXPR_NUM)
    assert_lex3("0b10r",   nil, :tRATIONAL, Rational(2),         EXPR_NUM)
    assert_lex3("1.5r",    nil, :tRATIONAL, Rational(15, 10),    EXPR_NUM)
    assert_lex3("15e3r",   nil, :tRATIONAL, Rational(15000),     EXPR_NUM)
    assert_lex3("15e-3r",  nil, :tRATIONAL, Rational(15, 1000),  EXPR_NUM)
    assert_lex3("1.5e3r",  nil, :tRATIONAL, Rational(1500),      EXPR_NUM)
    assert_lex3("1.5e-3r", nil, :tRATIONAL, Rational(15, 10000), EXPR_NUM)

    r10 = Rational(10)
    assert_lex3("-10r", nil,
                :tUMINUS_NUM, "-", EXPR_BEG,
                :tRATIONAL,   r10, EXPR_NUM)
  end

  def test_unicode_ident
    s = "@\u1088\u1077\u1093\u1072"
    assert_lex3(s.dup, nil, :tIVAR, s.dup, EXPR_END)
  end

  def test_why_does_ruby_hate_me?
    assert_lex3("\"Nl%\\000\\000A\\000\\999\"", # you should be ashamed
                nil,
                :tSTRING, %W[ Nl% \u0000 \u0000 A \u0000 999 ].join, EXPR_END)
  end

  def test_yylex_ambiguous_uminus
    assert_lex3("m -3",
                nil,
                :tIDENTIFIER, "m", EXPR_CMDARG,
                :tUMINUS_NUM, "-", EXPR_BEG,
                :tINTEGER,    3,   EXPR_NUM)

    # TODO: verify warning
  end

  def test_yylex_ambiguous_uplus
    assert_lex3("m +3",
                nil,
                :tIDENTIFIER, "m", EXPR_CMDARG,
                :tINTEGER,    3,   EXPR_NUM)

    # TODO: verify warning
  end

  def test_yylex_and
    assert_lex3("&", nil, :tAMPER, "&", EXPR_BEG)
  end

  def test_yylex_and2
    assert_lex3("&&", nil, :tANDOP, "&&", EXPR_BEG)
  end

  def test_yylex_and2_equals
    assert_lex3("&&=", nil, :tOP_ASGN, "&&", EXPR_BEG)
  end

  def test_yylex_and_arg
    self.lex_state = EXPR_ARG

    assert_lex3(" &y",
                nil,
                :tAMPER,      "&", EXPR_BEG,
                :tIDENTIFIER, "y", EXPR_ARG)
  end

  def test_yylex_and_dot
    setup_lexer_class RubyParser::V23

    assert_lex3("&.", nil, :tLONELY, "&.", EXPR_DOT)
  end

  def test_yylex_and_dot_call
    setup_lexer_class RubyParser::V23

    assert_lex3("x&.y", nil,
                :tIDENTIFIER, "x",  EXPR_CMDARG,
                :tLONELY,     "&.", EXPR_DOT,
                :tIDENTIFIER, "y")
  end

  def test_yylex_and_dot_call_newline
    setup_lexer_class Ruby23Parser

    assert_lex3("x\n&.y", nil,
                :tIDENTIFIER, "x",  EXPR_CMDARG,
                :tLONELY,     "&.", EXPR_DOT,
                :tIDENTIFIER, "y")
  end

  def test_yylex_and_equals
    assert_lex3("&=", nil, :tOP_ASGN, "&", EXPR_BEG)
  end

  def test_yylex_and_expr
    self.lex_state = EXPR_ARG

    assert_lex3("x & y",
                nil,
                :tIDENTIFIER, "x", EXPR_CMDARG,
                :tAMPER2,     "&", EXPR_BEG,
                :tIDENTIFIER, "y", EXPR_ARG)
  end

  def test_yylex_and_meth
    assert_lex_fname "&", :tAMPER2
  end

  def test_yylex_assoc
    assert_lex3 "=>", nil, :tASSOC, "=>", EXPR_BEG
  end

  def test_yylex_back_ref
    assert_lex3("[$&, $`, $', $+]",
                nil,
                :tLBRACK,   "[",  EXPR_PAR,
                :tBACK_REF, :&,   EXPR_END, :tCOMMA, ",", EXPR_PAR,
                :tBACK_REF, :"`", EXPR_END, :tCOMMA, ",", EXPR_PAR,
                :tBACK_REF, :"'", EXPR_END, :tCOMMA, ",", EXPR_PAR,
                :tBACK_REF, :+,   EXPR_END,
                :tRBRACK,   "]",  EXPR_END)
  end

  def test_yylex_backslash
    assert_lex3("1 \\\n+ 2",
                nil,
                :tINTEGER, 1,   EXPR_NUM,
                :tPLUS,    "+", EXPR_BEG,
                :tINTEGER, 2,   EXPR_NUM)
  end

  def test_yylex_backslash_bad
    refute_lex("1 \\ + 2", :tINTEGER, 1)
  end

  def test_yylex_backtick
    assert_lex3("`ls`",
                nil,
                :tXSTRING_BEG,    "`",  EXPR_BEG,
                :tSTRING_CONTENT, "ls", EXPR_BEG,
                :tSTRING_END,     "`",  EXPR_LIT)
  end

  def test_yylex_backtick_cmdarg
    self.lex_state = EXPR_DOT

    # \n ensures expr_cmd (TODO: why?)
    assert_lex3("\n`", nil, :tBACK_REF2, "`", EXPR_CMDARG)
  end

  def test_yylex_backtick_dot
    self.lex_state = EXPR_DOT

    assert_lex3("a.`(3)",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tDOT,        ".", EXPR_DOT,
                :tBACK_REF2,  "`", EXPR_ARG,
                :tLPAREN2,    "(", EXPR_PAR,
                :tINTEGER,    3,   EXPR_NUM,
                :tRPAREN,     ")", EXPR_ENDFN)
  end

  def test_yylex_backtick_method
    self.lex_state = EXPR_FNAME

    assert_lex3("`",
                nil,
                :tBACK_REF2, "`", EXPR_END)
  end

  def test_yylex_bad_char
    refute_lex(" \010 ")
  end

  def test_yylex_bang
    assert_lex3("!", nil, :tBANG, "!", EXPR_BEG)
  end

  def test_yylex_bang_equals
    assert_lex3("!=", nil, :tNEQ, "!=", EXPR_BEG)
  end

  def test_yylex_bang_tilde
    assert_lex3("!~", nil, :tNMATCH, "!~", EXPR_BEG)
  end

  def test_yylex_bdot2
    assert_lex3("..42",
                nil, # TODO: s(:dot2, nil, s(:lit, 42)),

                :tBDOT2,   "..", EXPR_BEG,
                :tINTEGER, 42,   EXPR_END|EXPR_ENDARG)
  end

  def test_yylex_bdot3
    assert_lex3("...42",
                nil, # TODO: s(:dot2, nil, s(:lit, 42)),

                :tBDOT3,   "...", EXPR_BEG,
                :tINTEGER, 42,    EXPR_END|EXPR_ENDARG)
  end

  def test_yylex_block_bug_1
    assert_lex3("a do end",
                s(:iter, s(:call, nil, :a), 0),

                :tIDENTIFIER, "a",   EXPR_CMDARG,
                :kDO,         "do",  EXPR_BEG,
                :kEND,        "end", EXPR_END)
  end

  def test_yylex_block_bug_2
    assert_lex3("a = 1\na do\nend",
                s(:block,
                  s(:lasgn, :a, s(:lit, 1)),
                  s(:iter, s(:call, nil, :a), 0)),

                :tIDENTIFIER, "a",   EXPR_CMDARG,
                :tEQL,        "=",   EXPR_BEG,
                :tINTEGER,    1,     EXPR_NUM,
                :tNL,         nil,   EXPR_BEG,
                :tIDENTIFIER, "a",   EXPR_CMDARG,
                :kDO,         "do",  EXPR_BEG,
                :kEND,        "end", EXPR_END)
  end

  def test_yylex_block_bug_3
    assert_lex3("a { }",
                s(:iter, s(:call, nil, :a), 0),

                :tIDENTIFIER, "a", EXPR_CMDARG, # verified
                :tLCURLY,     "{", EXPR_PAR,
                :tRCURLY,     "}", EXPR_END)
  end

  def test_yylex_carat
    assert_lex3("^", nil, :tCARET, "^", EXPR_BEG)
  end

  def test_yylex_carat_equals
    assert_lex3("^=", nil, :tOP_ASGN, "^", EXPR_BEG)
  end

  def test_yylex_colon2
    assert_lex3("A::B",
                nil,
                :tCONSTANT, "A",  EXPR_CMDARG,
                :tCOLON2,   "::", EXPR_DOT,
                :tCONSTANT, "B",  EXPR_ARG)
  end

  def test_yylex_colon2_argh
    assert_lex3("module X::Y\n  c\nend",
                nil,
                :kMODULE,     "module", EXPR_BEG,
                :tCONSTANT,   "X",      EXPR_CMDARG,
                :tCOLON2,     "::",     EXPR_DOT,
                :tCONSTANT,   "Y",      EXPR_ARG,
                :tNL,         nil,      EXPR_BEG,
                :tIDENTIFIER, "c",      EXPR_CMDARG,
                :tNL,         nil,      EXPR_BEG,
                :kEND,        "end",    EXPR_END)
  end

  def test_yylex_colon3
    assert_lex3("::Array",
                nil,
                :tCOLON3,   "::",    EXPR_BEG,
                :tCONSTANT, "Array", EXPR_ARG)
  end

  def test_yylex_comma
    assert_lex3(",", nil, :tCOMMA, ",", EXPR_PAR)
  end

  def test_yylex_comment
    assert_lex3("1 # one\n# two\n2",
                nil,
                :tINTEGER, 1,   EXPR_NUM,
                :tNL,      nil, EXPR_BEG,
                :tINTEGER, 2,   EXPR_NUM)

    assert_equal "# one\n# two\n", @lex.comments
  end

  def test_yylex_comment_begin
    assert_lex3("=begin\nblah\nblah\n=end\n42",
                nil,
                :tINTEGER, 42, EXPR_NUM)

    assert_equal "=begin\nblah\nblah\n=end\n", @lex.comments
  end

  def test_yylex_comment_begin_bad
    refute_lex("=begin\nblah\nblah\n")

    assert_equal "", @lex.comments
  end

  def test_yylex_comment_begin_not_comment
    assert_lex3("beginfoo = 5\np x \\\n=beginfoo",
                nil,
                :tIDENTIFIER, "beginfoo", EXPR_CMDARG,
                :tEQL,        "=",        EXPR_BEG,
                :tINTEGER,    5,          EXPR_NUM,
                :tNL,         nil,        EXPR_BEG,
                :tIDENTIFIER, "p",        EXPR_CMDARG,
                :tIDENTIFIER, "x",        EXPR_ARG,
                :tEQL,        "=",        EXPR_BEG,
                :tIDENTIFIER, "beginfoo", EXPR_ARG)
  end

  def test_yylex_comment_begin_space
    assert_lex3("=begin blah\nblah\n=end\n", nil)

    assert_equal "=begin blah\nblah\n=end\n", @lex.comments
  end

  def test_yylex_comment_end_space_and_text
    assert_lex3("=begin blah\nblah\n=end blab\n", nil)

    assert_equal "=begin blah\nblah\n=end blab\n", @lex.comments
  end

  def test_yylex_comment_eos
    assert_lex3("# comment", nil)
  end

  def test_yylex_const_call_same_name
    assert_lex("X = a { }; b { f :c }",
               s(:block,
                 s(:cdecl, :X, s(:iter, s(:call, nil, :a), 0)),
                 s(:iter,
                   s(:call, nil, :b),
                   0,
                   s(:call, nil, :f, s(:lit, :c)))),

               :tCONSTANT,   "X", EXPR_CMDARG, 0, 0,
               :tEQL,        "=", EXPR_BEG,    0, 0,
               :tIDENTIFIER, "a", EXPR_ARG,    0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tRCURLY,     "}", EXPR_END,    0, 0,
               :tSEMI,       ";", EXPR_BEG,    0, 0,

               :tIDENTIFIER, "b", EXPR_CMDARG, 0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tIDENTIFIER, "f", EXPR_CMDARG, 0, 1, # different
               :tSYMBOL,     "c", EXPR_LIT,    0, 1,
               :tRCURLY,     "}", EXPR_END,    0, 0)

    assert_lex("X = a { }; b { X :c }",
               s(:block,
                 s(:cdecl, :X, s(:iter, s(:call, nil, :a), 0)),
                 s(:iter,
                   s(:call, nil, :b),
                   0,
                   s(:call, nil, :X, s(:lit, :c)))),

               :tCONSTANT,   "X", EXPR_CMDARG, 0, 0,
               :tEQL,        "=", EXPR_BEG,    0, 0,
               :tIDENTIFIER, "a", EXPR_ARG,    0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tRCURLY,     "}", EXPR_END,    0, 0,
               :tSEMI,       ";", EXPR_BEG,    0, 0,

               :tIDENTIFIER, "b", EXPR_CMDARG, 0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tCONSTANT,   "X", EXPR_CMDARG, 0, 1, # same
               :tSYMBOL,     "c", EXPR_LIT,    0, 1,
               :tRCURLY,     "}", EXPR_END,    0, 0)
  end

  def test_yylex_constant
    assert_lex3("ArgumentError", nil, :tCONSTANT, "ArgumentError", EXPR_CMDARG)
  end

  def test_yylex_constant_semi
    assert_lex3("ArgumentError;",
                nil,
                :tCONSTANT, "ArgumentError", EXPR_CMDARG,
                :tSEMI,     ";",             EXPR_BEG)
  end

  def test_yylex_cvar
    assert_lex3("@@blah", nil, :tCVAR, "@@blah", EXPR_END)
  end

  def test_yylex_cvar_bad
    assert_raises RubyParser::SyntaxError do
      assert_lex3("@@1", nil)
    end
  end

  def test_yylex_def_bad_name
    refute_lex3("def [ ",
                :kDEF,    "def", EXPR_FNAME)
  end

  def test_yylex_div
    assert_lex3("a / 2",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tDIVIDE,     "/", EXPR_BEG,
                :tINTEGER,    2,   EXPR_NUM)
  end

  def test_yylex_div_equals
    assert_lex3("a /= 2",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tOP_ASGN,    "/", EXPR_BEG,
                :tINTEGER,    2,   EXPR_NUM)
  end

  def test_yylex_do
    assert_lex3("x do 42 end",
                nil,
                :tIDENTIFIER, "x",   EXPR_CMDARG,
                :kDO,         "do",  EXPR_BEG,
                :tINTEGER,    42,    EXPR_NUM,
                :kEND,        "end", EXPR_END)
  end

  def test_yylex_do_block
    self.lex_state = EXPR_ENDARG

    assert_lex3("x.y do 42 end",
                nil,
                :tIDENTIFIER, "x",   EXPR_END,
                :tDOT,        ".",   EXPR_DOT,
                :tIDENTIFIER, "y",   EXPR_ARG,
                :kDO_BLOCK,   "do",  EXPR_BEG,
                :tINTEGER,    42,    EXPR_NUM,
                :kEND,        "end", EXPR_END) do
      @lex.cmdarg.push true
    end
  end

  def test_yylex_do_block2
    self.lex_state = EXPR_ENDARG

    assert_lex3("do 42 end",
                nil,
                :kDO,       "do",  EXPR_BEG,
                :tINTEGER,  42,    EXPR_NUM,
                :kEND,      "end", EXPR_END)
  end

  def test_yylex_do_cond
    assert_lex3("x do 42 end",
                nil,
                :tIDENTIFIER, "x",   EXPR_CMDARG,
                :kDO_COND,    "do",  EXPR_BEG,
                :tINTEGER,    42,    EXPR_NUM,
                :kEND,        "end", EXPR_END) do
      @lex.cond.push true
    end
  end

  def test_yylex_dollar_bad
    e = refute_lex("$%")
    assert_includes(e.message, "is not allowed as a global variable name")
  end

  def test_yylex_dot # HINT message sends
    assert_lex3(".", nil, :tDOT, ".", EXPR_DOT)
  end

  def test_yylex_dot2
    assert_lex3("1..2",
                s(:lit, 1..2),

                :tINTEGER, 1,    EXPR_END|EXPR_ENDARG,
                :tDOT2,    "..", EXPR_BEG,
                :tINTEGER, 2,    EXPR_END|EXPR_ENDARG)

    self.lex_state = EXPR_END|EXPR_ENDARG
    assert_lex3("..", nil, :tDOT2, "..", EXPR_BEG)
  end

  def test_yylex_dot3
    assert_lex3("1...2",
                s(:lit, 1...2),

                :tINTEGER, 1,     EXPR_END|EXPR_ENDARG,
                :tDOT3,    "...", EXPR_BEG,
                :tINTEGER, 2,     EXPR_END|EXPR_ENDARG)

    self.lex_state = EXPR_END|EXPR_ENDARG
    assert_lex3("...", nil, :tDOT3, "...", EXPR_BEG)
  end

  def test_yylex_equals
    # FIX: this sucks
    assert_lex3("=", nil, :tEQL, "=", EXPR_BEG)
  end

  def test_yylex_equals2
    assert_lex3("==", nil, :tEQ, "==", EXPR_BEG)
  end

  def test_yylex_equals3
    assert_lex3("===", nil, :tEQQ, "===", EXPR_BEG)
  end

  def test_yylex_equals_tilde
    assert_lex3("=~", nil, :tMATCH, "=~", EXPR_BEG)
  end

  def test_yylex_float
    assert_lex3("1.0", nil, :tFLOAT, 1.0, EXPR_NUM)
  end

  def test_yylex_float_bad_no_underscores
    refute_lex "1__0.0"
  end

  def test_yylex_float_bad_no_zero_leading
    refute_lex ".0"
  end

  def test_yylex_float_bad_trailing_underscore
    refute_lex "123_.0"
  end

  def test_yylex_float_call
    assert_lex3("1.0.to_s",
                nil,
                :tFLOAT,      1.0,    EXPR_NUM,
                :tDOT,        ".",    EXPR_DOT,
                :tIDENTIFIER, "to_s", EXPR_ARG)
  end

  def test_yylex_float_dot_E
    assert_lex3("1.0E10",
                nil,
                :tFLOAT, 10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_dot_E_neg
    assert_lex3("-1.0E10",
                nil,
                :tUMINUS_NUM, "-",           EXPR_BEG,
                :tFLOAT,      10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_dot_e
    assert_lex3("1.0e10",
                nil,
                :tFLOAT, 10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_dot_e_neg
    assert_lex3("-1.0e10",
                nil,
                :tUMINUS_NUM, "-",           EXPR_BEG,
                :tFLOAT,      10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_e
    assert_lex3("1e10",
                nil,
                :tFLOAT, 10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_e_bad_double_e
    assert_lex3("1e2e3",
                nil,
                :tFLOAT, 100,       EXPR_NUM,
                :tIDENTIFIER, "e3", EXPR_END)
  end

  def test_yylex_float_e_bad_trailing_underscore
    refute_lex "123_e10"
  end

  def test_yylex_float_e_minus
    assert_lex3("1e-10", nil, :tFLOAT, 1.0e-10, EXPR_NUM)
  end

  def test_yylex_float_e_neg
    assert_lex3("-1e10",
                nil,
                :tUMINUS_NUM, "-",           EXPR_BEG,
                :tFLOAT,      10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_e_neg_minus
    assert_lex3("-1e-10",
                nil,
                :tUMINUS_NUM, "-",     EXPR_BEG,
                :tFLOAT,      1.0e-10, EXPR_NUM)
  end

  def test_yylex_float_e_neg_plus
    assert_lex3("-1e+10",
                nil,
                :tUMINUS_NUM, "-",           EXPR_BEG,
                :tFLOAT,      10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_e_plus
    assert_lex3("1e+10", nil, :tFLOAT, 10000000000.0, EXPR_NUM)
  end

  def test_yylex_float_e_zero
    assert_lex3("0e0", nil, :tFLOAT, 0.0, EXPR_NUM)
  end

  def test_yylex_float_if_modifier
    assert_lex3("1e2if",
                nil,
                :tFLOAT, 100,   EXPR_NUM,
                :kIF_MOD, "if", EXPR_PAR)
  end

  def test_yylex_float_neg
    assert_lex3("-1.0",
                nil,
                :tUMINUS_NUM, "-", EXPR_BEG,
                :tFLOAT,      1.0, EXPR_NUM)
  end

  def test_yylex_ge
    assert_lex3("a >= 2",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tGEQ,        ">=", EXPR_BEG,
                :tINTEGER,    2,    EXPR_NUM)
  end

  def test_yylex_global
    assert_lex3("$blah", nil, :tGVAR, "$blah", EXPR_END)
  end

  def test_yylex_global_backref
    self.lex_state = EXPR_FNAME

    assert_lex3("$`", nil, :tGVAR, "$`", EXPR_END)
  end

  def test_yylex_global_dash_nothing
    refute_lex3("$- ", nil) # fails 2.1+

    setup_lexer_class RubyParser::V20
    assert_lex3("$- ", nil, :tGVAR, "$-", EXPR_END)
  end

  def test_yylex_global_dash_something
    assert_lex3("$-x", nil, :tGVAR, "$-x", EXPR_END)
  end

  def test_yylex_global_number
    self.lex_state = EXPR_FNAME

    assert_lex3("$1", nil, :tGVAR, "$1", EXPR_END)
  end

  def test_yylex_global_number_big
    self.lex_state = EXPR_FNAME

    assert_lex3("$1234", nil, :tGVAR, "$1234", EXPR_END)
  end

  def test_yylex_global_I_have_no_words
    assert_lex3("$x\xE2\x80\x8B = 42", # zero width space?!?!?
                nil,
                :tGVAR, "$x\xE2\x80\x8B", EXPR_END,
                :tEQL,  "=", EXPR_BEG,
                :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_global_other
    assert_lex3("[$~, $*, $$, $?, $!, $@, $/, $\\, $;, $,, $., $=, $:, $<, $>, $\"]",
                nil,
                :tLBRACK, "[",   EXPR_PAR,
                :tGVAR,   "$~",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$*",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$$",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$?",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$!",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$@",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$/",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$\\", EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$;",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$,",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$.",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$=",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$:",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$<",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$>",  EXPR_END, :tCOMMA,  ",", EXPR_PAR,
                :tGVAR,   "$\"", EXPR_END,
                :tRBRACK, "]",   EXPR_END)
  end

  def test_yylex_global_underscore
    assert_lex3("$_", nil, :tGVAR, "$_", EXPR_END)
  end

  def test_yylex_global_wierd
    assert_lex3("$__blah", nil, :tGVAR, "$__blah", EXPR_END)
  end

  def test_yylex_global_zero
    assert_lex3("$0", nil, :tGVAR, "$0", EXPR_END)
  end

  def test_yylex_gt
    assert_lex3("a > 2",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tGT,         ">", EXPR_BEG,
                :tINTEGER,    2,   EXPR_NUM)
  end

  def test_yylex_hash_colon
    assert_lex("{a:1}",
               s(:hash, s(:lit, :a), s(:lit, 1)),

               :tLBRACE, "{",  EXPR_PAR,    0, 1,
               :tLABEL,  "a",  EXPR_LAB,    0, 1,
               :tINTEGER, 1,   EXPR_NUM,    0, 1,
               :tRCURLY, "}", EXPR_END,     0, 0)
  end

  def test_yylex_hash_colon_double_quoted_symbol
    assert_lex('{"abc": :b}',
               s(:hash, s(:lit, :abc), s(:lit, :b)),

               :tLBRACE, "{",   EXPR_PAR, 0, 1,
               :tLABEL,  "abc", EXPR_LAB, 0, 1,
               :tSYMBOL, "b",   EXPR_LIT, 0, 1,
               :tRCURLY, "}",   EXPR_END, 0, 0)
  end

  def test_yylex_hash_colon_double_quoted_symbol_22
    setup_lexer_class RubyParser::V22

    assert_lex('{"abc": :b}',
               s(:hash, s(:lit, :abc), s(:lit, :b)),

               :tLBRACE, "{",   EXPR_PAR,    0, 1,
               :tLABEL,  "abc", EXPR_LAB,    0, 1,
               :tSYMBOL, "b",   EXPR_LIT,    0, 1,
               :tRCURLY, "}",   EXPR_ENDARG, 0, 0)
  end

  def test_yylex_hash_colon_double_quoted_with_escapes
    assert_lex3("{\"s\\tr\\i\\ng\\\\foo\\'bar\":1}",
               nil,

               :tLBRACE, "{",                  EXPR_PAR,
               :tLABEL,  "s\tr\i\ng\\foo'bar", EXPR_LAB,
               :tINTEGER, 1,                   EXPR_NUM,
               :tRCURLY, "}",                  EXPR_END)
  end

  def test_yylex_hash_colon_quoted_22
    setup_lexer_class RubyParser::V22

    assert_lex("{'a':1}",
               s(:hash, s(:lit, :a), s(:lit, 1)),

               :tLBRACE, "{", EXPR_PAR,    0, 1,
               :tLABEL,  "a", EXPR_LAB,    0, 1,
               :tINTEGER, 1,  EXPR_NUM,    0, 1,
               :tRCURLY, "}", EXPR_ENDARG, 0, 0)
  end

  def test_yylex_hash_colon_quoted_symbol
    assert_lex("{'abc': :b}",
               s(:hash, s(:lit, :abc), s(:lit, :b)),

               :tLBRACE, "{",   EXPR_PAR, 0, 1,
               :tLABEL,  "abc", EXPR_LAB, 0, 1,
               :tSYMBOL, "b",   EXPR_LIT, 0, 1,
               :tRCURLY, "}",   EXPR_END, 0, 0)
  end

  def test_yylex_hash_colon_quoted_symbol_22
    setup_lexer_class RubyParser::V22

    assert_lex("{'abc': :b}",
               s(:hash, s(:lit, :abc), s(:lit, :b)),

               :tLBRACE, "{",   EXPR_PAR,    0, 1,
               :tLABEL,  "abc", EXPR_LAB,    0, 1,
               :tSYMBOL, "b",   EXPR_LIT,    0, 1,
               :tRCURLY, "}",   EXPR_ENDARG, 0, 0)
  end

  def test_yylex_hash_colon_quoted_with_escapes
    assert_lex3("{'s\\tr\\i\\ng\\\\foo\\'bar':1}",
               nil,

               :tLBRACE, "{",                     EXPR_PAR,
               :tLABEL,  "s\\tr\\i\\ng\\foo'bar", EXPR_LAB,
               :tINTEGER, 1,                      EXPR_NUM,
               :tRCURLY, "}",                     EXPR_END)
  end

  def test_yylex_heredoc_backtick
    assert_lex3("a = <<`EOF`\n  blah blah\nEOF\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tXSTRING_BEG,    "`",             EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)
  end

  def test_yylex_heredoc_double
    assert_lex3("a = <<\"EOF\"\n  blah blah\nEOF\n\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "\"",            EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)
  end

  def test_yylex_heredoc_double_dash
    assert_lex3("a = \"  blah blah\n\".strip\n42",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING,         "  blah blah\n", EXPR_END,
                :tDOT,            ".",             EXPR_DOT,
                :tIDENTIFIER,     "strip",         EXPR_ARG,
                :tNL,             nil,             EXPR_BEG,

                :tINTEGER,        42,              EXPR_END
               )

    assert_lex3("a = <<-\"EOF\".strip\n  blah blah\n  EOF\n42",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "\"",            EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,

                :tDOT,            ".",             EXPR_DOT,
                :tIDENTIFIER,     "strip",         EXPR_ARG,

                :tNL,             nil,             EXPR_BEG,

                :tINTEGER,        42,              EXPR_END
               )
  end

  def test_yylex_heredoc_double_eos
    refute_lex("a = <<\"EOF\"\nblah",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "\"",
               :tSTRING_CONTENT, "blah")
  end

  def test_yylex_heredoc_double_eos_nl
    refute_lex("a = <<\"EOF\"\nblah\n",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "\"")
  end

  def test_yylex_heredoc_double_interp
    assert_lex3("a = <<\"EOF\"\n#x a \#@a b \#$b c \#@@d \#{3} \nEOF\n\n",
                nil,
                :tIDENTIFIER,     "a",     EXPR_CMDARG,
                :tEQL,            "=",     EXPR_BEG,
                :tSTRING_BEG,     "\"",    EXPR_BEG,
                :tSTRING_CONTENT, "#x a ", EXPR_BEG,
                :tSTRING_DVAR,    "#",     EXPR_BEG,
                :tSTRING_CONTENT, "@a b ", EXPR_BEG, # HUH?
                :tSTRING_DVAR,    "#",     EXPR_BEG,
                :tSTRING_CONTENT, "$b c ", EXPR_BEG, # HUH?
                :tSTRING_DVAR,    "#",     EXPR_BEG,
                :tSTRING_CONTENT, "@@d ",  EXPR_BEG, # HUH?
                :tSTRING_DBEG,    "\#{",   EXPR_BEG,
                :tSTRING_CONTENT, "3} \n", EXPR_BEG,
                :tSTRING_END,     "EOF",   EXPR_LIT,
                :tNL,             nil,     EXPR_BEG)
  end

  def test_yylex_heredoc_double_squiggly
    setup_lexer_class Ruby23Parser

    assert_lex3("a = <<~\"EOF\"\n  blah blah\n  EOF\n\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "\"",            EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)
  end

  def test_yylex_heredoc_empty
    assert_lex3("<<\"\"\n\#{x}\nblah2\n\n\n",
                nil,
                :tSTRING_BEG,     "\"",          EXPR_BEG,
                :tSTRING_DBEG,    "\#{",         EXPR_BEG,
                :tSTRING_CONTENT, "x}\nblah2\n", EXPR_BEG,
                :tSTRING_END,     "",            EXPR_LIT,
                :tNL,             nil,           EXPR_BEG)
  end

  def test_yylex_heredoc_none
    assert_lex3("a = <<EOF\nblah\nblah\nEOF\n",
                nil,
                :tIDENTIFIER,     "a",            EXPR_CMDARG,
                :tEQL,            "=",            EXPR_BEG,
                :tSTRING_BEG,     "\"",           EXPR_BEG,
                :tSTRING_CONTENT, "blah\nblah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",          EXPR_LIT,
                :tNL,             nil,            EXPR_BEG)
  end

  def test_yylex_heredoc_none_bad_eos
    refute_lex("a = <<EOF",
                   :tIDENTIFIER, "a",
                   :tEQL,        "=",
                   :tSTRING_BEG, "\"")
  end

  def test_yylex_heredoc_none_dash
    assert_lex3("a = <<-EOF\nblah\nblah\n  EOF\n",
                nil,
                :tIDENTIFIER,     "a",            EXPR_CMDARG,
                :tEQL,            "=",            EXPR_BEG,
                :tSTRING_BEG,     "\"",           EXPR_BEG,
                :tSTRING_CONTENT, "blah\nblah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",          EXPR_LIT,
                :tNL,             nil,            EXPR_BEG)
  end

  def test_yylex_heredoc_none_squiggly
    setup_lexer_class Ruby23Parser

    assert_lex3("a = <<~EOF\n  blah\n  blah\n  EOF\n",
                nil,
                :tIDENTIFIER,     "a",                EXPR_CMDARG,
                :tEQL,            "=",                EXPR_BEG,
                :tSTRING_BEG,     "\"",               EXPR_BEG,
                :tSTRING_CONTENT, "  blah\n  blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",              EXPR_LIT,
                :tNL,             nil,                EXPR_BEG)
  end

  def test_yylex_heredoc_single
    assert_lex3("a = <<'EOF'\n  blah blah\nEOF\n\n\n\n42\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "'",             EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG,
                :tINTEGER,        42,              EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)

    assert_nil lex.old_ss
  end

  def test_yylex_heredoc_single_bad_eos_body
    refute_lex("a = <<'EOF'\nblah",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "'")
  end

  def test_yylex_heredoc_single_bad_eos_empty
    refute_lex("a = <<''\n",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "'")
  end

  def test_yylex_heredoc_single_bad_eos_term
    refute_lex("a = <<'EOF",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "\"")
  end

  def test_yylex_heredoc_single_bad_eos_term_nl
    refute_lex("a = <<'EOF\ns = 'blah blah'",
               :tIDENTIFIER, "a",
               :tEQL,        "=",
               :tSTRING_BEG, "\"")
  end

  def test_yylex_heredoc_single_dash
    assert_lex3("a = <<-'EOF'\n  blah blah\n  EOF\n\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "'",             EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)
  end

  def test_yylex_heredoc_single_squiggly
    setup_lexer_class Ruby23Parser

    assert_lex3("a = <<~'EOF'\n  blah blah\n  EOF\n\n",
                nil,
                :tIDENTIFIER,     "a",             EXPR_CMDARG,
                :tEQL,            "=",             EXPR_BEG,
                :tSTRING_BEG,     "'",             EXPR_BEG,
                :tSTRING_CONTENT, "  blah blah\n", EXPR_BEG,
                :tSTRING_END,     "EOF",           EXPR_LIT,
                :tNL,             nil,             EXPR_BEG)
  end

  def test_yylex_identifier
    assert_lex3("identifier",
                nil,
                :tIDENTIFIER, "identifier", EXPR_CMDARG)
  end

  def test_yylex_identifier_bang
    assert_lex3("identifier!",
                nil,
                :tFID, "identifier!", EXPR_CMDARG)
  end

  def test_yylex_identifier_cmp
    assert_lex_fname "<=>", :tCMP
  end

  def test_yylex_identifier_def__20
    setup_lexer_class RubyParser::V20

    assert_lex_fname "identifier", :tIDENTIFIER, EXPR_ENDFN
  end

  def test_yylex_identifier_eh
    assert_lex3("identifier?", nil, :tFID, "identifier?", EXPR_CMDARG)
  end

  def test_yylex_identifier_equals3
    assert_lex3(":a===b",
                nil,
                :tSYMBOL,     "a",   EXPR_LIT,
                :tEQQ,        "===", EXPR_BEG,
                :tIDENTIFIER, "b",   EXPR_ARG)
  end

  def test_yylex_identifier_equals_arrow
    assert_lex3(":blah==>",
                nil,
                :tSYMBOL, "blah=", EXPR_LIT,
                :tASSOC,  "=>",    EXPR_BEG)
  end

  def test_yylex_identifier_equals_caret
    assert_lex_fname "^", :tCARET
  end

  def test_yylex_identifier_equals_def2
    assert_lex_fname "==", :tEQ
  end

  def test_yylex_identifier_equals_def__20
    setup_lexer_class RubyParser::V20

    assert_lex_fname "identifier=", :tIDENTIFIER, EXPR_ENDFN
  end

  def test_yylex_identifier_equals_equals_arrow
    assert_lex3(":a==>b",
                nil,
                :tSYMBOL, "a=", EXPR_LIT,
                :tASSOC, "=>", EXPR_BEG,
                :tIDENTIFIER, "b", EXPR_ARG)
  end

  def test_yylex_identifier_equals_expr
    self.lex_state = EXPR_DOT
    assert_lex3("y = arg",
                nil,
                :tIDENTIFIER, "y",   EXPR_CMDARG,
                :tEQL,        "=",   EXPR_BEG,
                :tIDENTIFIER, "arg", EXPR_ARG)
  end

  def test_yylex_identifier_equals_or
    assert_lex_fname "|", :tPIPE
  end

  def test_yylex_identifier_equals_slash
    assert_lex_fname "/", :tDIVIDE
  end

  def test_yylex_identifier_equals_tilde
    self.lex_state = EXPR_FNAME # can only set via parser's defs

    assert_lex3("identifier=~",
                nil,
                :tIDENTIFIER, "identifier", EXPR_ENDFN,
                :tMATCH,      "=~",         EXPR_BEG)
  end

  def test_yylex_identifier_gt
    assert_lex_fname ">", :tGT
  end

  def test_yylex_identifier_le
    assert_lex_fname "<=", :tLEQ
  end

  def test_yylex_identifier_lt
    assert_lex_fname "<", :tLT
  end

  def test_yylex_identifier_tilde
    assert_lex_fname "~", :tTILDE
  end

  def test_yylex_index
    assert_lex_fname "[]", :tAREF
  end

  def test_yylex_index_equals
    assert_lex_fname "[]=", :tASET
  end

  def test_yylex_integer
    assert_lex3("42", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_bin
    assert_lex3("0b101010", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_bin_bad_none
    refute_lex "0b "
  end

  def test_yylex_integer_bin_bad_underscores
    refute_lex "0b10__01"
  end

  def test_yylex_integer_dec
    assert_lex3("42", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_dec_bad_underscores
    refute_lex "42__24"
  end

  def test_yylex_integer_dec_d
    assert_lex3("0d42", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_dec_d_bad_none
    refute_lex "0d"
  end

  def test_yylex_integer_dec_d_bad_underscores
    refute_lex "0d42__24"
  end

  def test_yylex_integer_hex
    assert_lex3 "0x2a", nil, :tINTEGER, 42, EXPR_NUM
  end

  def test_yylex_integer_hex_bad_none
    refute_lex "0x "
  end

  def test_yylex_integer_hex_bad_underscores
    refute_lex "0xab__cd"
  end

  def test_yylex_integer_if_modifier
    assert_lex3("123if",
                nil,
                :tINTEGER, 123, EXPR_NUM,
                :kIF_MOD, "if", EXPR_PAR)
  end

  def test_yylex_integer_oct
    assert_lex3("052", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_oct_O
    assert_lex3 "0O52", nil, :tINTEGER, 42, EXPR_NUM
  end

  def test_yylex_integer_oct_O_bad_range
    refute_lex "0O8"
  end

  def test_yylex_integer_oct_O_bad_underscores
    refute_lex "0O1__23"
  end

  def test_yylex_integer_oct_O_not_bad_none
    assert_lex3 "0O ", nil, :tINTEGER, 0, EXPR_NUM
  end

  def test_yylex_integer_oct_bad_range
    refute_lex "08"
  end

  def test_yylex_integer_oct_bad_range2
    refute_lex "08"
  end

  def test_yylex_integer_oct_bad_underscores
    refute_lex "01__23"
  end

  def test_yylex_integer_oct_o
    assert_lex3 "0o52", nil, :tINTEGER, 42, EXPR_NUM
  end

  def test_yylex_integer_oct_o_bad_range
    refute_lex "0o8"
  end

  def test_yylex_integer_oct_o_bad_underscores
    refute_lex "0o1__23"
  end

  def test_yylex_integer_oct_o_not_bad_none
    assert_lex3 "0o ", nil, :tINTEGER, 0, EXPR_NUM
  end

  def test_yylex_integer_trailing
    assert_lex3("1.to_s",
                nil,
                :tINTEGER,    1,      EXPR_NUM,
                :tDOT,        ".",    EXPR_DOT,
                :tIDENTIFIER, "to_s", EXPR_ARG)
  end

  def test_yylex_integer_underscore
    assert_lex3("4_2", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_integer_underscore_bad
    refute_lex "4__2"
  end

  def test_yylex_integer_zero
    assert_lex3 "0", nil, :tINTEGER, 0, EXPR_NUM
  end

  def test_yylex_is_your_spacebar_broken?
    assert_lex3(":a!=:b",
                nil,
                :tSYMBOL, "a",  EXPR_LIT,
                :tNEQ,    "!=", EXPR_BEG,
                :tSYMBOL, "b",  EXPR_LIT)
  end

  def test_yylex_iter_array_curly
    # this will lex, but doesn't parse... don't freak out.
    assert_lex("f :a, [:b] { |c, d| }", # yes, this is bad code
                nil,

               :tIDENTIFIER, "f", EXPR_CMDARG, 0, 0,
               :tSYMBOL,     "a", EXPR_LIT,    0, 0,
               :tCOMMA,      ",", EXPR_PAR,    0, 0,
               :tLBRACK,     "[", EXPR_PAR,    1, 0,
               :tSYMBOL,     "b", EXPR_LIT,    1, 0,
               :tRBRACK,     "]", EXPR_END,    0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tPIPE,       "|", EXPR_PAR,    0, 1,
               :tIDENTIFIER, "c", EXPR_ARG,    0, 1,
               :tCOMMA,      ",", EXPR_PAR,    0, 1,
               :tIDENTIFIER, "d", EXPR_ARG,    0, 1,
               :tPIPE,       "|", EXPR_PAR,    0, 1,
               :tRCURLY,     "}", EXPR_END,    0, 0)
  end

  def test_yylex_iter_array_curly__24
    setup_lexer_class RubyParser::V24

    assert_lex("f :a, [:b] { |c, d| }", # yes, this is bad code
               s(:iter,
                 s(:call, nil, :f,
                   s(:lit, :a).line(1),
                   s(:array, s(:lit, :b).line(1)).line(1)).line(1),
                 s(:args, :c, :d).line(1)).line(1),

               :tIDENTIFIER, "f", EXPR_CMDARG,  0, 0,
               :tSYMBOL,     "a", EXPR_LIT,     0, 0,
               :tCOMMA,      ",", EXPR_PAR,     0, 0,
               :tLBRACK,     "[", EXPR_PAR,     1, 0,
               :tSYMBOL,     "b", EXPR_LIT,     1, 0,
               :tRBRACK,     "]", EXPR_ENDARG,  0, 0,
               :tLBRACE_ARG, "{", EXPR_BEG,     0, 1,
               :tPIPE,       "|", EXPR_PAR,     0, 1,
               :tIDENTIFIER, "c", EXPR_ARG,     0, 1,
               :tCOMMA,      ",", EXPR_PAR,     0, 1,
               :tIDENTIFIER, "d", EXPR_ARG,     0, 1,
               :tPIPE,       "|", EXPR_PAR,     0, 1,
               :tRCURLY,     "}", EXPR_ENDARG,  0, 0)
  end

  def test_yylex_ivar
    assert_lex3("@blah", nil, :tIVAR, "@blah", EXPR_END)
  end

  def test_yylex_ivar_bad
    refute_lex "@1"
  end

  def test_yylex_ivar_bad_0_length
    refute_lex "1+@\n", :tINTEGER, 1, :tPLUS, "+", EXPR_NUM
  end

  def test_yylex_keyword_expr
    self.lex_state = EXPR_ENDARG

    assert_lex3("if", nil, :kIF_MOD, "if", EXPR_PAR)
  end

  def test_yylex_label
    assert_lex3("{a:",
                nil,
                :tLBRACE, "{",  EXPR_PAR,
                :tLABEL,  "a",  EXPR_LAB)
  end

  def test_yylex_label_in_params
    assert_lex3("foo(a:",
                nil,
                :tIDENTIFIER, "foo", EXPR_CMDARG,
                :tLPAREN2,    "(",    EXPR_PAR,
                :tLABEL,      "a",    EXPR_LAB)
  end

  def test_yylex_lambda_args
    assert_lex("-> (a) { }",
               s(:iter, s(:lambda),
                 s(:args, :a)),

               :tLAMBDA,    "->", EXPR_ENDFN, 0, 0,
               :tLPAREN2,    "(", EXPR_PAR,   1, 0,
               :tIDENTIFIER, "a", EXPR_ARG,   1, 0,
               :tRPAREN,     ")", EXPR_ENDFN, 0, 0,
               :tLCURLY,     "{", EXPR_PAR,   0, 1,
               :tRCURLY,     "}", EXPR_END,   0, 0)
  end

  def test_yylex_lambda_args__24
    setup_lexer_class RubyParser::V24

    assert_lex("-> (a) { }",
               s(:iter, s(:lambda),
                 s(:args, :a)),

               :tLAMBDA,    "->", EXPR_ENDFN,  0, 0,
               :tLPAREN2,    "(", EXPR_PAR,    1, 0,
               :tIDENTIFIER, "a", EXPR_ARG,    1, 0,
               :tRPAREN,     ")", EXPR_ENDFN,  0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tRCURLY,     "}", EXPR_ENDARG, 0, 0)
  end

  def test_yylex_lambda_args_opt
    assert_lex("-> (a=nil) { }",
               s(:iter, s(:lambda),
                 s(:args, s(:lasgn, :a, s(:nil)))),

               :tLAMBDA,    "->",   EXPR_ENDFN,  0, 0,
               :tLPAREN2,    "(",   EXPR_PAR,    1, 0,
               :tIDENTIFIER, "a",   EXPR_ARG,    1, 0,
               :tEQL,        "=",   EXPR_BEG,    1, 0,
               :kNIL,        "nil", EXPR_END,    1, 0,
               :tRPAREN,     ")",   EXPR_ENDFN,  0, 0,
               :tLCURLY,     "{",   EXPR_PAR,    0, 1,
               :tRCURLY,     "}",   EXPR_END,    0, 0)
  end

  def test_yylex_lambda_args_opt__24
    setup_lexer_class RubyParser::V24

    assert_lex("-> (a=nil) { }",
               s(:iter, s(:lambda),
                 s(:args, s(:lasgn, :a, s(:nil)))),

               :tLAMBDA,    "->",   EXPR_ENDFN,  0, 0,
               :tLPAREN2,    "(",   EXPR_PAR,    1, 0,
               :tIDENTIFIER, "a",   EXPR_ARG,    1, 0,
               :tEQL,        "=",   EXPR_BEG,    1, 0,
               :kNIL,        "nil", EXPR_END,    1, 0,
               :tRPAREN,     ")",   EXPR_ENDFN,  0, 0,
               :tLCURLY,     "{",   EXPR_PAR,    0, 1,
               :tRCURLY,     "}",   EXPR_ENDARG, 0, 0)
  end

  def test_yylex_lambda_as_args_with_block
    assert_lex3("a -> do end do end",
                nil,
                :tIDENTIFIER, "a",   EXPR_CMDARG,
                :tLAMBDA,    "->",   EXPR_ENDFN,
                :kDO,         "do",  EXPR_BEG,
                :kEND,        "end", EXPR_END,
                :kDO,         "do",  EXPR_BEG,
                :kEND,        "end", EXPR_END)
  end

  def test_yylex_lambda_hash
    assert_lex("-> (a={}) { }",
               s(:iter, s(:lambda),
                 s(:args, s(:lasgn, :a, s(:hash)))),

               :tLAMBDA,    "->", EXPR_ENDFN, 0, 0,
               :tLPAREN2,    "(", EXPR_PAR,   1, 0,
               :tIDENTIFIER, "a", EXPR_ARG,   1, 0,
               :tEQL,        "=", EXPR_BEG,   1, 0,
               :tLBRACE,     "{", EXPR_PAR,   1, 1,
               :tRCURLY,     "}", EXPR_END,   1, 0,
               :tRPAREN,     ")", EXPR_ENDFN, 0, 0,
               :tLCURLY,     "{", EXPR_PAR,   0, 1,
               :tRCURLY,     "}", EXPR_END,   0, 0)
  end

  def test_yylex_lambda_hash__24
    setup_lexer_class RubyParser::V24

    assert_lex("-> (a={}) { }",
               s(:iter, s(:lambda),
                 s(:args, s(:lasgn, :a, s(:hash)))),

               :tLAMBDA,    "->", EXPR_ENDFN,  0, 0,
               :tLPAREN2,    "(", EXPR_PAR,    1, 0,
               :tIDENTIFIER, "a", EXPR_ARG,    1, 0,
               :tEQL,        "=", EXPR_BEG,    1, 0,
               :tLBRACE,     "{", EXPR_PAR,    1, 1,
               :tRCURLY,     "}", EXPR_ENDARG, 1, 0,
               :tRPAREN,     ")", EXPR_ENDFN,  0, 0,
               :tLCURLY,     "{", EXPR_PAR,    0, 1,
               :tRCURLY,     "}", EXPR_ENDARG, 0, 0)
  end

  def test_yylex_lasgn_call_same_name
    assert_lex("a = b.c :d => 1",
               s(:lasgn, :a,
                 s(:call, s(:call, nil, :b), :c,
                   s(:hash, s(:lit, :d), s(:lit, 1)))),

               :tIDENTIFIER, "a",  EXPR_CMDARG, 0, 0,
               :tEQL,        "=",  EXPR_BEG,    0, 0,
               :tIDENTIFIER, "b",  EXPR_ARG,    0, 0,
               :tDOT,        ".",  EXPR_DOT,    0, 0,
               :tIDENTIFIER, "c",  EXPR_ARG,    0, 0, # different
               :tSYMBOL,     "d",  EXPR_LIT,    0, 0,
               :tASSOC,      "=>", EXPR_BEG,    0, 0,
               :tINTEGER,    1,    EXPR_NUM,    0, 0)

    assert_lex("a = b.a :d => 1",
               s(:lasgn, :a,
                 s(:call, s(:call, nil, :b), :a,
                   s(:hash, s(:lit, :d), s(:lit, 1)))),

               :tIDENTIFIER, "a",  EXPR_CMDARG, 0, 0,
               :tEQL,        "=",  EXPR_BEG,    0, 0,
               :tIDENTIFIER, "b",  EXPR_ARG,    0, 0,
               :tDOT,        ".",  EXPR_DOT,    0, 0,
               :tIDENTIFIER, "a",  EXPR_ARG,    0, 0, # same as lvar
               :tSYMBOL,     "d",  EXPR_LIT,    0, 0,
               :tASSOC,      "=>", EXPR_BEG,    0, 0,
               :tINTEGER,    1,    EXPR_NUM,    0, 0)
  end

  def test_yylex_lt
    assert_lex3("<", nil, :tLT, "<", EXPR_BEG)
  end

  def test_yylex_lt2
    assert_lex3("a << b",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tLSHFT,      "<<", EXPR_BEG,
                :tIDENTIFIER, "b",  EXPR_ARG)
  end

  def test_yylex_lt2_equals
    assert_lex3("a <<= b",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tOP_ASGN,    "<<", EXPR_BEG,
                :tIDENTIFIER, "b",  EXPR_ARG)
  end

  def test_yylex_lt_equals
    assert_lex3("<=", nil, :tLEQ, "<=", EXPR_BEG)
  end

  def test_yylex_method_parens_chevron
    assert_lex("a()<<1",
               s(:call, s(:call, nil, :a), :<<, s(:lit, 1)),
               :tIDENTIFIER, "a",  EXPR_CMDARG, 0, 0,
               :tLPAREN2,    "(",  EXPR_PAR,    1, 0,
               :tRPAREN,     ")",  EXPR_ENDFN,  0, 0,
               :tLSHFT,      "<<", EXPR_BEG,    0, 0,
               :tINTEGER,    1,    EXPR_NUM,    0, 0)
  end

  def test_yylex_minus
    assert_lex3("1 - 2",
                nil,
                :tINTEGER, 1,   EXPR_NUM,
                :tMINUS,   "-", EXPR_BEG,
                :tINTEGER, 2,   EXPR_NUM)
  end

  def test_yylex_minus_equals
    assert_lex3("-=", nil, :tOP_ASGN, "-", EXPR_BEG)
  end

  def test_yylex_minus_method
    self.lex_state = EXPR_FNAME

    assert_lex3("-", nil, :tMINUS, "-", EXPR_ARG)
  end

  def test_yylex_minus_unary_method
    self.lex_state = EXPR_FNAME

    assert_lex3("-@", nil, :tUMINUS, "-@", EXPR_ARG)
  end

  def test_yylex_minus_unary_number
    assert_lex3("-42",
                nil,
                :tUMINUS_NUM, "-", EXPR_BEG,
                :tINTEGER,    42,  EXPR_NUM)
  end

  def test_yylex_not_at_defn
    assert_lex("def +@; end",
               s(:defn, :+@, s(:args), s(:nil)),

               :kDEF,   "def", EXPR_FNAME, 0, 0,
               :tUPLUS, "+@",  EXPR_ARG,   0, 0,
               :tSEMI,  ";",   EXPR_BEG,   0, 0,
               :kEND,   "end", EXPR_END,   0, 0)

    assert_lex("def !@; end",
               s(:defn, :"!@", s(:args), s(:nil)),

               :kDEF,   "def", EXPR_FNAME, 0, 0,
               :tBANG,  "!@",  EXPR_ARG,   0, 0,
               :tSEMI,  ";",   EXPR_BEG,   0, 0,
               :kEND,   "end", EXPR_END,   0, 0)
  end

  def test_yylex_not_at_ivar
    assert_lex("!@ivar",
               s(:call, s(:ivar, :@ivar).line(1), :"!").line(1),

               :tBANG, "!",     EXPR_BEG, 0, 0,
               :tIVAR, "@ivar", EXPR_END, 0, 0)
  end

  def test_yylex_not_unary_method
    self.lex_state = EXPR_FNAME

    assert_lex3("!@", nil, :tBANG, "!@", EXPR_ARG)
  end

  def test_yylex_nth_ref
    assert_lex3("[$1, $2, $3, $4, $5, $6, $7, $8, $9]",
               nil,
               :tLBRACK,  "[", EXPR_PAR,
               :tNTH_REF, 1,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 2,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 3,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 4,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 5,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 6,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 7,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 8,   EXPR_END, :tCOMMA,   ",", EXPR_PAR,
               :tNTH_REF, 9,   EXPR_END,
               :tRBRACK,  "]", EXPR_END)
  end

  def test_yylex_number_times_ident_times_return_number
    assert_lex("1 * b * 3",
               s(:call,
                 s(:call, s(:lit, 1), :*, s(:call, nil, :b)),
                 :*, s(:lit, 3)),

               :tINTEGER,    1,   EXPR_NUM, 0, 0,
               :tSTAR2,      "*", EXPR_BEG, 0, 0,
               :tIDENTIFIER, "b", EXPR_ARG, 0, 0,
               :tSTAR2,      "*", EXPR_BEG, 0, 0,
               :tINTEGER,    3,   EXPR_NUM, 0, 0)

    assert_lex("1 * b *\n 3",
               s(:call,
                 s(:call, s(:lit, 1), :*, s(:call, nil, :b)),
                 :*, s(:lit, 3)),

               :tINTEGER,    1,   EXPR_NUM, 0, 0,
               :tSTAR2,      "*", EXPR_BEG, 0, 0,
               :tIDENTIFIER, "b", EXPR_ARG, 0, 0,
               :tSTAR2,      "*", EXPR_BEG, 0, 0,
               :tINTEGER,    3,   EXPR_NUM, 0, 0)
  end

  def test_yylex_numbers
    assert_lex3 "0b10", nil, :tINTEGER, 2,  EXPR_NUM
    assert_lex3 "0B10", nil, :tINTEGER, 2,  EXPR_NUM

    assert_lex3 "0d10", nil, :tINTEGER, 10, EXPR_NUM
    assert_lex3 "0D10", nil, :tINTEGER, 10, EXPR_NUM

    assert_lex3 "0x10", nil, :tINTEGER, 16, EXPR_NUM
    assert_lex3 "0X10", nil, :tINTEGER, 16, EXPR_NUM

    assert_lex3 "0o10", nil, :tINTEGER, 8,  EXPR_NUM
    assert_lex3 "0O10", nil, :tINTEGER, 8,  EXPR_NUM

    assert_lex3 "0o",   nil, :tINTEGER, 0,  EXPR_NUM
    assert_lex3 "0O",   nil, :tINTEGER, 0,  EXPR_NUM

    assert_lex3 "0",    nil, :tINTEGER, 0,  EXPR_NUM

    refute_lex "0x"
    refute_lex "0X"
    refute_lex "0b"
    refute_lex "0B"
    refute_lex "0d"
    refute_lex "0D"

    refute_lex "08"
    refute_lex "09"
    refute_lex "0o8"
    refute_lex "0o9"
    refute_lex "0O8"
    refute_lex "0O9"

    refute_lex "1_e1"
    refute_lex "1_.1"
    refute_lex "1__1"
  end

  def test_yylex_open_bracket
    assert_lex3("(", nil, :tLPAREN, "(", EXPR_PAR)
  end

  def test_yylex_open_bracket_cmdarg
    self.lex_state = EXPR_CMDARG

    assert_lex3(" (", nil, :tLPAREN_ARG, "(", EXPR_PAR)
  end

  def test_yylex_open_bracket_exprarg__20
    setup_lexer_class RubyParser::V20
    self.lex_state = EXPR_ARG

    assert_lex3(" (", nil, :tLPAREN_ARG, "(", EXPR_PAR)
  end

  def test_yylex_open_curly_bracket
    assert_lex3("{", nil, :tLBRACE, "{", EXPR_PAR)
  end

  def test_yylex_open_curly_bracket_arg
    self.lex_state = EXPR_ARG

    assert_lex3("m { 3 }",
                nil,
                :tIDENTIFIER, "m", EXPR_CMDARG,
                :tLCURLY,     "{", EXPR_PAR,
                :tINTEGER,    3,   EXPR_NUM,
                :tRCURLY,     "}", EXPR_END)
  end

  def test_yylex_open_curly_bracket_block
    self.lex_state = EXPR_ENDARG # seen m(3)

    assert_lex3("{ 4 }",
                nil,
                :tLBRACE_ARG, "{", EXPR_BEG,
                :tINTEGER,    4,   EXPR_NUM,
                :tRCURLY,     "}", EXPR_END)
  end

  def test_yylex_open_square_bracket_arg
    self.lex_state = EXPR_ARG

    assert_lex3("m [ 3 ]",
                nil,
                :tIDENTIFIER, "m", EXPR_CMDARG,
                :tLBRACK,     "[", EXPR_PAR,
                :tINTEGER,    3,   EXPR_NUM,
                :tRBRACK,     "]", EXPR_END)
  end

  def test_yylex_open_square_bracket_ary
    assert_lex3("[1, 2, 3]",
                nil,
                :tLBRACK, "[",  EXPR_PAR,
                :tINTEGER, 1,   EXPR_NUM, :tCOMMA,  ",", EXPR_PAR,
                :tINTEGER, 2,   EXPR_NUM, :tCOMMA,  ",", EXPR_PAR,
                :tINTEGER, 3,   EXPR_NUM,
                :tRBRACK, "]", EXPR_END)
  end

  def test_yylex_open_square_bracket_meth
    assert_lex3("m[3]",
               nil,
               :tIDENTIFIER, "m", EXPR_CMDARG,
               :tLBRACK2,    "[", EXPR_PAR,
               :tINTEGER,    3,   EXPR_NUM,
               :tRBRACK,     "]", EXPR_END)
  end

  def test_yylex_or
    assert_lex3("|", nil, :tPIPE, "|", EXPR_PAR)
  end

  def test_yylex_or2
    assert_lex3("||", nil, :tOROP, "||", EXPR_BEG)
  end

  def test_yylex_or2_equals
    assert_lex3("||=", nil, :tOP_ASGN, "||", EXPR_BEG)
  end

  def test_yylex_or_equals
    assert_lex3("|=", nil, :tOP_ASGN, "|", EXPR_BEG)
  end

  def test_yylex_paren_string_interpolated_regexp
    setup_lexer('%( #{(/abcd/)} )',
                s(:dstr, " ", s(:evstr, s(:lit, /abcd/)), s(:str, " ")))

    assert_next_lexeme :tSTRING_BEG,       "%)",   EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_CONTENT,   " ",    EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_DBEG,      '#{',   EXPR_BEG, 0, 0

    emulate_string_interpolation do
      assert_next_lexeme :tLPAREN,         "(",    EXPR_PAR, 1, 0
      assert_next_lexeme :tREGEXP_BEG,     "/",    EXPR_PAR, 1, 0
      assert_next_lexeme :tSTRING_CONTENT, "abcd", EXPR_PAR, 1, 0
      assert_next_lexeme :tREGEXP_END,     "",     EXPR_LIT, 1, 0
      assert_next_lexeme :tRPAREN,         ")",    EXPR_ENDFN, 0, 0
    end

    assert_next_lexeme :tSTRING_CONTENT,   " ",    EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_END,       ")",    EXPR_LIT, 0, 0

    refute_lexeme
  end

  def test_yylex_paren_string_parens_interpolated
    setup_lexer('%((#{b}#{d}))',
                s(:dstr,
                  "(",
                  s(:evstr, s(:call, nil, :b)),
                  s(:evstr, s(:call, nil, :d)),
                  s(:str, ")")))

    assert_next_lexeme :tSTRING_BEG,     "%)", EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_CONTENT, "(",  EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_DBEG,    '#{', EXPR_BEG, 0, 0

    emulate_string_interpolation do
      assert_next_lexeme :tIDENTIFIER,   "b",  EXPR_CMDARG, 0, 0
    end

    assert_next_lexeme :tSTRING_DBEG,    '#{',  EXPR_BEG, 0, 0

    emulate_string_interpolation do
      assert_next_lexeme :tIDENTIFIER,   "d",  EXPR_CMDARG, 0, 0
    end

    assert_next_lexeme :tSTRING_CONTENT, ")",  EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_END,     ")",  EXPR_LIT, 0, 0

    refute_lexeme
  end

  def test_yylex_paren_string_parens_interpolated_regexp
    setup_lexer('%((#{(/abcd/)}))',
                s(:dstr, "(", s(:evstr, s(:lit, /abcd/)), s(:str, ")")))

    assert_next_lexeme :tSTRING_BEG,       "%)",   EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_CONTENT,   "(",    EXPR_BEG, 0, 0

    assert_next_lexeme :tSTRING_DBEG,       '#{',  EXPR_BEG, 0, 0

    emulate_string_interpolation do
      assert_next_lexeme :tLPAREN,         "(",    EXPR_PAR,   1, 0
      assert_next_lexeme :tREGEXP_BEG,     "/",    EXPR_PAR,   1, 0
      assert_next_lexeme :tSTRING_CONTENT, "abcd", EXPR_PAR,   1, 0
      assert_next_lexeme :tREGEXP_END,     "",     EXPR_LIT,   1, 0
      assert_next_lexeme :tRPAREN,         ")",    EXPR_ENDFN, 0, 0
    end

    assert_next_lexeme :tSTRING_CONTENT,   ")",    EXPR_BEG, 0, 0
    assert_next_lexeme :tSTRING_END,       ")",    EXPR_LIT, 0, 0

    refute_lexeme
  end

  def test_yylex_percent
    assert_lex3("a % 2",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tPERCENT,    "%", EXPR_BEG,
                :tINTEGER,    2,   EXPR_NUM)
  end

  def test_yylex_percent_equals
    assert_lex3("a %= 2",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tOP_ASGN,    "%", EXPR_BEG,
                :tINTEGER,    2,   EXPR_NUM)
  end

  def test_yylex_plus
    assert_lex3("1 + 1", # TODO lex_state?
                nil,
                :tINTEGER, 1,   EXPR_NUM,
                :tPLUS,    "+", EXPR_BEG,
                :tINTEGER, 1,   EXPR_NUM)
  end

  def test_yylex_plus_equals
    assert_lex3("+=", nil, :tOP_ASGN, "+", EXPR_BEG)
  end

  def test_yylex_plus_method
    self.lex_state = EXPR_FNAME

    assert_lex3("+", nil, :tPLUS, "+", EXPR_ARG)
  end

  def test_yylex_plus_unary_method
    self.lex_state = EXPR_FNAME

    assert_lex3("+@", nil, :tUPLUS, "+@", EXPR_ARG)
  end

  def test_yylex_plus_unary_number
    assert_lex3("+42", nil, :tINTEGER, 42, EXPR_NUM)
  end

  def test_yylex_question_bad_eos
    refute_lex "?"
  end

  def test_yylex_question_eh_a__20
    setup_lexer_class RubyParser::V20

    assert_lex3("?a", nil, :tSTRING, "a", EXPR_END)
  end

  def test_yylex_question_eh_escape_M_escape_C__20
    setup_lexer_class RubyParser::V20

    assert_lex3("?\\M-\\C-a", nil, :tSTRING, "\M-\C-a", EXPR_END)
  end

  def test_yylex_question_control_escape
    assert_lex3('?\C-\]', nil, :tSTRING, ?\C-\], EXPR_END)
  end

  def test_yylex_question_ws
    assert_lex3("? ",  nil, :tEH, "?", EXPR_BEG)
    assert_lex3("?\n", nil, :tEH, "?", EXPR_BEG)
    assert_lex3("?\t", nil, :tEH, "?", EXPR_BEG)
    assert_lex3("?\v", nil, :tEH, "?", EXPR_BEG)
    assert_lex3("?\r", nil, :tEH, "?", EXPR_BEG)
    assert_lex3("?\f", nil, :tEH, "?", EXPR_BEG)
  end

  def test_yylex_question_ws_backslashed__20
    setup_lexer_class RubyParser::V20

    assert_lex3("?\\ ", nil, :tSTRING, " ",  EXPR_END)
    assert_lex3("?\\n", nil, :tSTRING, "\n", EXPR_END)
    assert_lex3("?\\t", nil, :tSTRING, "\t", EXPR_END)
    assert_lex3("?\\v", nil, :tSTRING, "\v", EXPR_END)
    assert_lex3("?\\r", nil, :tSTRING, "\r", EXPR_END)
    assert_lex3("?\\f", nil, :tSTRING, "\f", EXPR_END)
  end

  def test_yylex_rbracket
    assert_lex3("]", nil, :tRBRACK, "]", EXPR_END)
  end

  def test_yylex_rcurly
    assert_lex("}", nil, :tRCURLY, "}", EXPR_END, 0, 1) do
      lexer.brace_nest += 2
    end
  end

  def test_yylex_regexp
    assert_lex3("/regexp/",
                nil,
                :tREGEXP_BEG,     "/",      EXPR_BEG,
                :tSTRING_CONTENT, "regexp", EXPR_BEG,
                :tREGEXP_END,     "",       EXPR_LIT)
  end

  def test_yylex_regexp_ambiguous
    assert_lex3("method /regexp/",
                nil,
                :tIDENTIFIER,     "method", EXPR_CMDARG,
                :tREGEXP_BEG,     "/",      EXPR_CMDARG,
                :tSTRING_CONTENT, "regexp", EXPR_CMDARG,
                :tREGEXP_END,     "",       EXPR_LIT)
  end

  def test_yylex_regexp_bad
    refute_lex("/.*/xyz",
               :tREGEXP_BEG,     "/",
               :tSTRING_CONTENT, ".*")
  end

  def test_yylex_regexp_escape_C
    assert_lex3("/regex\\C-x/",
                nil,
                :tREGEXP_BEG,     "/",          EXPR_BEG,
                :tSTRING_CONTENT, "regex\\C-x", EXPR_BEG,
                :tREGEXP_END,     "",           EXPR_LIT)
  end

  def test_yylex_regexp_escape_C_M
    assert_lex3("/regex\\C-\\M-x/",
                nil,
                :tREGEXP_BEG,     "/",              EXPR_BEG,
                :tSTRING_CONTENT, "regex\\C-\\M-x", EXPR_BEG,
                :tREGEXP_END,     "",               EXPR_LIT)
  end

  def test_yylex_regexp_escape_C_M_craaaazy
    rb = "/regex\\C-\\\n\\M-x/"
    assert_lex3(rb,
                nil,
                :tREGEXP_BEG,     "/",              EXPR_BEG,
                :tSTRING_CONTENT, "regex\\C-\\M-x", EXPR_BEG,
                :tREGEXP_END,     "",               EXPR_LIT)
  end

  def test_yylex_regexp_escape_C_bad_dash
    refute_lex '/regex\\Cx/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_C_bad_dash_eos
    refute_lex '/regex\\C-/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_C_bad_dash_eos2
    refute_lex '/regex\\C-', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_C_bad_eos
    refute_lex '/regex\\C/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_C_bad_eos2
    refute_lex '/regex\\c', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_M
    assert_lex3("/regex\\M-x/",
                nil,
                :tREGEXP_BEG,     "/",          EXPR_BEG,
                :tSTRING_CONTENT, "regex\\M-x", EXPR_BEG,
                :tREGEXP_END,     "",           EXPR_LIT)
  end

  def test_yylex_regexp_escape_M_C
    assert_lex3("/regex\\M-\\C-x/",
                nil,
                :tREGEXP_BEG,     "/",              EXPR_BEG,
                :tSTRING_CONTENT, "regex\\M-\\C-x", EXPR_BEG,
                :tREGEXP_END,     "",               EXPR_LIT)
  end

  def test_yylex_regexp_escape_M_bad_dash
    refute_lex '/regex\\Mx/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_M_bad_dash_eos
    refute_lex '/regex\\M-/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_M_bad_dash_eos2
    refute_lex '/regex\\M-', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_M_bad_eos
    refute_lex '/regex\\M/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_backslash_slash
    assert_lex3("/\\//",
                nil,
                :tREGEXP_BEG,     "/", EXPR_BEG,
                :tSTRING_CONTENT, "/", EXPR_BEG,
                :tREGEXP_END,     "",  EXPR_LIT)
  end

  def test_yylex_regexp_escape_backslash_terminator
    rb = "%r%blah\\%blah%"
    assert_lex3(rb,
                s(:lit, /blah%blah/).line(1),
                :tREGEXP_BEG,     "%r\0",      EXPR_BEG,
                :tSTRING_CONTENT, "blah%blah", EXPR_BEG,
                :tREGEXP_END,     "",          EXPR_LIT)
  end

  def test_yylex_regexp_escape_backslash_terminator_meta1
    assert_lex3("%r{blah\\}blah}",
                s(:lit, /blah\}blah/).line(1),
                :tREGEXP_BEG,     "%r{",         EXPR_BEG,
                :tSTRING_CONTENT, "blah\\}blah", EXPR_BEG,
                :tREGEXP_END,     "",            EXPR_LIT)
  end

  def test_yylex_regexp_escape_backslash_terminator_meta2
    rb = "%r/blah\\/blah/"
    pt = s(:lit, /blah\/blah/).line 1

    assert_lex3(rb,
                pt,
                :tREGEXP_BEG,     "%r\0",      EXPR_BEG,
                :tSTRING_CONTENT, "blah/blah", EXPR_BEG,
                :tREGEXP_END,     "",          EXPR_LIT)
  end

  def test_yylex_regexp_escape_backslash_terminator_meta3
    assert_lex3("%r/blah\\%blah/",
                nil,
                :tREGEXP_BEG,     "%r\0",        EXPR_BEG,
                :tSTRING_CONTENT, "blah\\%blah", EXPR_BEG,
                :tREGEXP_END,     "",            EXPR_LIT)
  end

  def test_yylex_regexp_escape_bad_eos
    refute_lex '/regex\\', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_bs
    rp = "/regex\\\\regex/"
    assert_lex3(rp,
                s(:lit, /regex\\regex/),
                :tREGEXP_BEG,     "/",              EXPR_BEG,
                :tSTRING_CONTENT, "regex\\\\regex", EXPR_BEG,
                :tREGEXP_END,     "",               EXPR_LIT)
  end

  def test_yylex_regexp_escape_c
    assert_lex3("/regex\\cxxx/",
                nil,
                :tREGEXP_BEG,     "/",           EXPR_BEG,
                :tSTRING_CONTENT, "regex\\cxxx", EXPR_BEG,
                :tREGEXP_END,     "",            EXPR_LIT)
  end

  def test_yylex_regexp_escape_c_backslash
    assert_lex3("/regex\\c\\n/",
                nil,
                :tREGEXP_BEG,     "/",           EXPR_BEG,
                :tSTRING_CONTENT, "regex\\c\\n", EXPR_BEG,
                :tREGEXP_END,     "",            EXPR_LIT)
  end

  def test_yylex_regexp_escape_chars
    assert_lex3("/re\\tge\\nxp/",
                nil,
                :tREGEXP_BEG,     "/",            EXPR_BEG,
                :tSTRING_CONTENT, "re\\tge\\nxp", EXPR_BEG,
                :tREGEXP_END,     "",             EXPR_LIT)
  end

  def test_yylex_regexp_escape_double_backslash
    rb = '/[\\/\\\\]$/'
    pt = s(:lit, /[\/\\]$/)

    assert_lex3(rb,
                pt,
                :tREGEXP_BEG,     "/",        EXPR_BEG,
                :tSTRING_CONTENT, "[/\\\\]$", EXPR_BEG,
                :tREGEXP_END,     "",         EXPR_LIT)
  end

  def test_yylex_regexp_escape_hex
    assert_lex3("/regex\\x61xp/",
                nil,
                :tREGEXP_BEG,     "/",            EXPR_BEG,
                :tSTRING_CONTENT, "regex\\x61xp", EXPR_BEG,
                :tREGEXP_END,     "",             EXPR_LIT)
  end

  def test_yylex_regexp_escape_hex_bad
    refute_lex '/regex\\xzxp/', :tREGEXP_BEG, "/"
  end

  def test_yylex_regexp_escape_hex_one
    assert_lex3("/^[\\xd\\xa]{2}/on",
                nil,
                :tREGEXP_BEG,     "/",              EXPR_BEG,
                :tSTRING_CONTENT, "^[\\xd\\xa]{2}", EXPR_BEG,
                :tREGEXP_END,     "on",             EXPR_LIT)
  end

  def test_yylex_regexp_escape_oct1
    assert_lex3("/regex\\0xp/",
                nil,
                :tREGEXP_BEG,     "/",          EXPR_BEG,
                :tSTRING_CONTENT, "regex\\0xp", EXPR_BEG,
                :tREGEXP_END,     "",           EXPR_LIT)
  end

  def test_yylex_regexp_escape_oct2
    assert_lex3("/regex\\07xp/",
                nil,
                :tREGEXP_BEG,     "/",           EXPR_BEG,
                :tSTRING_CONTENT, "regex\\07xp", EXPR_BEG,
                :tREGEXP_END,     "",            EXPR_LIT)
  end

  def test_yylex_regexp_escape_oct3
    assert_lex3("/regex\\10142/",
                nil,
                :tREGEXP_BEG,     "/",            EXPR_BEG,
                :tSTRING_CONTENT, "regex\\10142", EXPR_BEG,
                :tREGEXP_END,     "",             EXPR_LIT)
  end

  def test_yylex_regexp_escape_return
    assert_lex3("/regex\\\nregex/",
                nil,
                :tREGEXP_BEG,     "/",          EXPR_BEG,
                :tSTRING_CONTENT, "regexregex", EXPR_BEG,
                :tREGEXP_END,     "",           EXPR_LIT)
  end

  def test_yylex_regexp_escaped_delim
    assert_lex3("%r!blah(?\\!blah)!",
                nil,
                :tREGEXP_BEG,     "%r\0",         EXPR_BEG,
                :tSTRING_CONTENT, "blah(?!blah)", EXPR_BEG,
                :tREGEXP_END,     "",             EXPR_LIT)
  end

  def test_yylex_regexp_nm
    assert_lex3("/.*/nm",
                nil,
                :tREGEXP_BEG,     "/",  EXPR_BEG,
                :tSTRING_CONTENT, ".*", EXPR_BEG,
                :tREGEXP_END,     "nm", EXPR_LIT)
  end

  def test_yylex_required_kwarg_no_value_22
    setup_lexer_class RubyParser::V22

    assert_lex3("def foo a:, b:\nend",
                nil,
                :kDEF,        "def", EXPR_FNAME,
                :tIDENTIFIER, "foo", EXPR_ENDFN,
                :tLABEL,      "a",   EXPR_LAB,
                :tCOMMA,      ",",   EXPR_PAR,
                :tLABEL,      "b",   EXPR_LAB,
                :kEND,        "end", EXPR_END)
  end

  def test_yylex_rparen
    assert_lex3(")", nil, :tRPAREN, ")", EXPR_ENDFN)
  end

  def test_yylex_rshft
    assert_lex3("a >> 2",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tRSHFT,      ">>", EXPR_BEG,
                :tINTEGER,    2,    EXPR_NUM)
  end

  def test_yylex_rshft_equals
    assert_lex3("a >>= 2",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tOP_ASGN,    ">>", EXPR_BEG,
                :tINTEGER,    2,    EXPR_NUM)
  end

  def test_yylex_star
    assert_lex3("a * ",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tSTAR2,      "*", EXPR_BEG)
  end

  def test_yylex_star2
    assert_lex3("a ** ",
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tPOW,        "**", EXPR_BEG)
  end

  def test_yylex_star2_equals
    assert_lex3("a **= ",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tOP_ASGN,    "**", EXPR_BEG)
  end

  def test_yylex_star_arg
    self.lex_state = EXPR_ARG

    assert_lex3(" *a",
                nil,
                :tSTAR,       "*", EXPR_BEG,
                :tIDENTIFIER, "a", EXPR_ARG)
  end

  def test_yylex_star_arg_beg
    self.lex_state = EXPR_BEG

    assert_lex3("*a",
                nil,
                :tSTAR,       "*", EXPR_BEG,
                :tIDENTIFIER, "a", EXPR_ARG)
  end

  def test_yylex_star_arg_beg_fname
    self.lex_state = EXPR_FNAME

    assert_lex3("*a",
                nil,
                :tSTAR2,      "*", EXPR_ARG,
                :tIDENTIFIER, "a", EXPR_ARG)
  end

  def test_yylex_star_arg_beg_fname2
    self.lex_state = EXPR_FNAME

    assert_lex3("*a",
                nil,
                :tSTAR2,      "*", EXPR_ARG,
                :tIDENTIFIER, "a", EXPR_ARG)
  end

  def test_yylex_star_equals
    assert_lex3("a *= ",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tOP_ASGN, "*", EXPR_BEG)
  end

  def test_yylex_string_bad_eos
    refute_lex("%", :tSTRING_BEG, "%")
  end

  def test_yylex_string_bad_eos_quote
    refute_lex("%{nest",
               :tSTRING_BEG, "%}",
               :tSTRING_CONTENT, "nest")
  end

  def test_yylex_string_double
    assert_lex3("\"string\"", nil, :tSTRING, "string", EXPR_END)
  end

  def test_yylex_string_double_escape_C
    assert_lex3("\"\\C-a\"", nil, :tSTRING, "\001", EXPR_END)
  end

  def test_yylex_string_double_escape_C_backslash
    assert_lex3(%W[ " \\ C - \\ \\ " ].join, # I hate escaping \ in ' and "
                nil,
                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "\034", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_double_escape_C_escape
    assert_lex3("\"\\C-\\M-a\"",
                nil,
                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "\201", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_double_escape_C_question
    assert_lex3("\"\\C-?\"", nil, :tSTRING, "\177", EXPR_END)
  end

  def test_yylex_string_double_escape_M
    chr = "\341"

    assert_lex3("\"\\M-a\"", nil, :tSTRING, chr, EXPR_END)
  end

  def test_yylex_string_double_escape_M_backslash
    assert_lex3("\"\\M-\\\\\"",
                nil,
                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "\334", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_double_escape_M_escape
    assert_lex3("\"\\M-\\C-a\"",
                nil,
                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "\201", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_double_escape_bs1
    assert_lex3("\"a\\a\\a\"", nil, :tSTRING, "a\a\a", EXPR_END)
  end

  def test_yylex_string_double_escape_bs2
    assert_lex3("\"a\\\\a\"", nil, :tSTRING, "a\\a", EXPR_END)
  end

  def test_yylex_string_double_escape_c
    assert_lex3("\"\\ca\"", nil, :tSTRING, "\001", EXPR_END)
  end

  def test_yylex_string_double_escape_c_backslash
    refute_lex('"\\c\\"',
               :tSTRING_BEG, '"',
               :tSTRING_CONTENT, "\002")
  end

  def test_yylex_string_double_escape_c_escape
    assert_lex3("\"\\c\\M-a\"",
                nil,
                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "\201", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_double_escape_c_question
    assert_lex3("\"\\c?\"", nil, :tSTRING, "\177", EXPR_END)
  end

  def test_yylex_string_double_escape_chars
    assert_lex3("\"s\\tri\\ng\"", nil, :tSTRING, "s\tri\ng", EXPR_END)
  end

  def test_yylex_string_double_escape_hex
    assert_lex3("\"n = \\x61\\x62\\x63\"", nil, :tSTRING, "n = abc", EXPR_END)
  end

  def test_yylex_string_double_escape_octal
    assert_lex3("\"n = \\101\\102\\103\"", nil, :tSTRING, "n = ABC", EXPR_END)
  end

  def test_yylex_string_double_escape_octal_fucked
    assert_lex3("\"n = \\444\"", nil, :tSTRING, "n = $", EXPR_END)
  end

  def test_yylex_string_double_interp
    assert_lex3("\"blah #x a \#@a b \#$b c \#{3} # \"",
                nil,
                :tSTRING_BEG,     "\"",         EXPR_BEG,
                :tSTRING_CONTENT, "blah #x a ", EXPR_BEG,
                :tSTRING_DVAR,    "#",          EXPR_BEG,
                :tSTRING_CONTENT, "@a b ",      EXPR_BEG,
                :tSTRING_DVAR,    "#",          EXPR_BEG,
                :tSTRING_CONTENT, "$b c ",      EXPR_BEG,
                :tSTRING_DBEG,    "#\{",        EXPR_BEG,
                :tSTRING_CONTENT, "3} # ",      EXPR_BEG, # FIX: wrong!?!?
                :tSTRING_END,     "\"",         EXPR_LIT)
  end

  def test_yylex_string_double_nested_curlies
    assert_lex3("%{nest{one{two}one}nest}",
                nil,
                :tSTRING_BEG,     "%}",                    EXPR_BEG,
                :tSTRING_CONTENT, "nest{one{two}one}nest", EXPR_BEG,
                :tSTRING_END,     "}",                     EXPR_LIT)
  end

  def test_yylex_string_double_no_interp
    assert_lex3("\"# blah\"",      nil, :tSTRING, "# blah",      EXPR_END)
    assert_lex3("\"blah # blah\"", nil, :tSTRING, "blah # blah", EXPR_END)
  end

  def test_yylex_string_double_pound_dollar_bad
    assert_lex3('"#$%"', nil,

                :tSTRING_BEG,     "\"",   EXPR_BEG,
                :tSTRING_CONTENT, "#\$%", EXPR_BEG,
                :tSTRING_END,     "\"",   EXPR_LIT)
  end

  def test_yylex_string_escape_x_single
    assert_lex3("\"\\x0\"", nil, :tSTRING, "\000", EXPR_END)
  end

  def test_yylex_string_pct_I
    assert_lex3("%I[s1 s2\ns3]",
                nil,
                :tSYMBOLS_BEG,    "%I[", EXPR_BEG,
                :tSTRING_CONTENT, "s1",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s2",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s3",  EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_pct_I_extra_space
    assert_lex3("%I[ s1 s2\ns3 ]",
                nil,
                :tSYMBOLS_BEG,    "%I[", EXPR_BEG,
                :tSTRING_CONTENT, "s1",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s2",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s3",  EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_pct_Q
    assert_lex3("%Q[s1 s2]",
                nil,
                :tSTRING_BEG,     "%Q[",   EXPR_BEG,
                :tSTRING_CONTENT, "s1 s2", EXPR_BEG,
                :tSTRING_END,     "]",     EXPR_LIT)
  end

  def test_yylex_string_pct_Q_null_wtf?
    assert_lex3("%Q\0s1 s2\0",
                nil,
                :tSTRING_BEG,     "%Q\0",  EXPR_BEG,
                :tSTRING_CONTENT, "s1 s2", EXPR_BEG,
                :tSTRING_END,     "\0",    EXPR_LIT)
  end

  def test_yylex_string_pct_Q_bang
    assert_lex3("%Q!s1 s2!",
                nil,
                :tSTRING_BEG,     "%Q\0",  EXPR_BEG,
                :tSTRING_CONTENT, "s1 s2", EXPR_BEG,
                :tSTRING_END,     "!",     EXPR_LIT)
  end

  def test_yylex_string_pct_W
    assert_lex3("%W[s1 s2\ns3]", # TODO: add interpolation to these
                nil,
                :tWORDS_BEG,      "%W[", EXPR_BEG,
                :tSTRING_CONTENT, "s1",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s2",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s3",  EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_pct_W_bs_nl
    rb = "%W[s1 \\\ns2]" # TODO: add interpolation to these
    pt = s(:array,
           s(:str, "s1").line(1),
           s(:str, "\ns2").line(1)).line(1)

    assert_lex3(rb,
                pt,
                :tWORDS_BEG,      "%W[",  EXPR_BEG,
                :tSTRING_CONTENT, "s1",   EXPR_BEG,
                :tSPACE,          " ",    EXPR_BEG,
                :tSTRING_CONTENT, "\ns2", EXPR_BEG,
                :tSPACE,          "]",    EXPR_BEG,
                :tSTRING_END,     "]",    EXPR_LIT)
  end

  def test_yylex_string_pct_angle
    assert_lex3("%<blah>",
                nil,
                :tSTRING_BEG,     "%>",   EXPR_BEG,
                :tSTRING_CONTENT, "blah", EXPR_BEG,
                :tSTRING_END,     ">",    EXPR_LIT)
  end

  def test_yylex_string_pct_i
    assert_lex3("%i[s1 s2\ns3]",
                nil,
                :tQSYMBOLS_BEG,   "%i[", EXPR_BEG,
                :tSTRING_CONTENT, "s1",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s2",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s3",  EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_pct_i_extra_space
    assert_lex3("%i[ s1 s2\ns3 ]",
                nil,
                :tQSYMBOLS_BEG,   "%i[", EXPR_BEG,
                :tSTRING_CONTENT, "s1",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s2",  EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s3",  EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_pct_other
    assert_lex3("%%blah%",
                nil,
                :tSTRING_BEG,     "%%",   EXPR_BEG,
                :tSTRING_CONTENT, "blah", EXPR_BEG,
                :tSTRING_END,     "%",    EXPR_LIT)
  end

  def test_yylex_string_pct_q
    assert_lex3("%q[s1 s2]",
                nil,
                :tSTRING_BEG,     "%q[",   EXPR_BEG,
                :tSTRING_CONTENT, "s1 s2", EXPR_BEG,
                :tSTRING_END,     "]",     EXPR_LIT)
  end

  def test_yylex_string_pct_s
    assert_lex3("%s[s1 s2]",
                nil,
                :tSYMBEG,         "%s[",   EXPR_FNAME, # TODO: :tSYM_BEG ?
                :tSTRING_CONTENT, "s1 s2", EXPR_FNAME, # man... I don't like this
                :tSTRING_END,     "]",     EXPR_LIT)
  end

  def test_yylex_string_pct_w
    refute_lex("%w[s1 s2 ",
               :tQWORDS_BEG,     "%w[",
               :tSTRING_CONTENT, "s1",
               :tSPACE,          " ",
               :tSTRING_CONTENT, "s2",
               :tSPACE,          " ")
  end

  def test_yylex_string_pct_w_bs_nl
    assert_lex3("%w[s1 \\\ns2]",
                nil,
                :tQWORDS_BEG,     "%w[",  EXPR_BEG,
                :tSTRING_CONTENT, "s1",   EXPR_BEG,
                :tSPACE,          " ",    EXPR_BEG,
                :tSTRING_CONTENT, "\ns2", EXPR_BEG,
                :tSPACE,          "]",    EXPR_BEG,
                :tSTRING_END,     "]",    EXPR_LIT)
  end

  def test_yylex_string_pct_w_bs_sp
    assert_lex3("%w[s\\ 1 s\\ 2]",
                s(:array, s(:str, "s 1"), s(:str, "s 2")),
                :tQWORDS_BEG,     "%w[", EXPR_BEG,
                :tSTRING_CONTENT, "s 1", EXPR_BEG,
                :tSPACE,          " ",   EXPR_BEG,
                :tSTRING_CONTENT, "s 2", EXPR_BEG,
                :tSPACE,          "]",   EXPR_BEG,
                :tSTRING_END,     "]",   EXPR_LIT)
  end

  def test_yylex_string_single
    assert_lex3("'string'", nil, :tSTRING, "string", EXPR_END)
  end

  def test_yylex_string_single_escape_chars
    assert_lex3("'s\\tri\\ng'", nil, :tSTRING, "s\\tri\\ng", EXPR_END)
  end

  def test_yylex_string_single_escape_quote_and_backslash
    assert_lex3(":'foo\\'bar\\\\baz'", nil, :tSYMBOL, "foo'bar\\baz",
                EXPR_LIT)
  end

  def test_yylex_string_single_escaped_quote
    assert_lex3("'foo\\'bar'", nil, :tSTRING, "foo'bar", EXPR_END)
  end

  def test_yylex_string_single_nl
    assert_lex3("'blah\\\nblah'", nil, :tSTRING, "blah\\\nblah", EXPR_END)
  end

  def test_yylex_string_utf8_complex
    chr = [0x3024].pack("U")

    assert_lex3('"#@a\u{3024}"',
                s(:dstr, "", s(:evstr, s(:ivar, :@a)), s(:str, chr)),
                :tSTRING_BEG,     '"',      EXPR_BEG,
                :tSTRING_DVAR,    "#",      EXPR_BEG,
                :tSTRING_CONTENT, "@a"+chr, EXPR_BEG,
                :tSTRING_END,     '"',      EXPR_LIT)
  end

  def test_yylex_string_utf8_complex_missing_hex
    chr = [0x302].pack("U")
    str = "#{chr}zzz"

    refute_lex('"#@a\u302zzz"',
                :tSTRING_BEG,     '"',
                :tSTRING_DVAR,    "#",
                :tSTRING_CONTENT, "@a"+str,
                :tSTRING_END,     '"')

    chr = [0x30].pack("U")
    str = "#{chr}zzz"

    refute_lex('"#@a\u30zzz"',
                :tSTRING_BEG,     '"',
                :tSTRING_DVAR,    "#",
                :tSTRING_CONTENT, "@a"+str,
                :tSTRING_END,     '"')

    chr = [0x3].pack("U")
    str = "#{chr}zzz"

    refute_lex('"#@a\u3zzz"',
                :tSTRING_BEG,     '"',
                :tSTRING_DVAR,    "#",
                :tSTRING_CONTENT, "@a"+str,
                :tSTRING_END,     '"')
  end

  def test_yylex_string_utf8_bad_encoding_with_escapes
    str = "\"\\xBADπ\""
    exp = "\xBADπ".b

    assert_lex(str,
               s(:str, exp),
               :tSTRING, exp, EXPR_END)
  end

  def test_yylex_string_utf8_complex_trailing_hex
    chr = [0x3024].pack("U")
    str = "#{chr}abz"

    assert_lex3('"#@a\u3024abz"',
                s(:dstr, "", s(:evstr, s(:ivar, :@a)), s(:str, str)),
                :tSTRING_BEG,     '"',      EXPR_BEG,
                :tSTRING_DVAR,    "#",      EXPR_BEG,
                :tSTRING_CONTENT, "@a"+str, EXPR_BEG,
                :tSTRING_END,     '"',      EXPR_LIT)
  end

  def test_yylex_string_utf8_missing_hex
    refute_lex('"\u3zzz"')
    refute_lex('"\u30zzz"')
    refute_lex('"\u302zzz"')
  end

  def test_yylex_string_utf8_simple
    chr = [0x3024].pack("U")

    assert_lex3('"\u{3024}"',
                s(:str, chr),
                :tSTRING, chr, EXPR_END)
  end

  def test_yylex_string_utf8_trailing_hex
    chr = [0x3024].pack("U")
    str = "#{chr}abz"

    assert_lex3('"\u3024abz"',
                s(:str, str),
                :tSTRING, str, EXPR_END)
  end

  def test_yylex_sym_quoted
    assert_lex(":'a'",
               s(:lit, :a),

               :tSYMBOL, "a", EXPR_LIT, 0, 0)
  end

  def test_yylex_symbol
    assert_lex3(":symbol", nil, :tSYMBOL, "symbol", EXPR_LIT)
  end

  def test_yylex_symbol_double
    assert_lex3(":\"symbol\"",
                nil,
                :tSYMBOL, "symbol", EXPR_LIT)
  end

  def test_yylex_symbol_double_interp
    assert_lex3(':"symbol#{1+1}"',
                nil,
                :tSYMBEG,         ":",      EXPR_FNAME,
                :tSTRING_CONTENT, "symbol", EXPR_FNAME,
                :tSTRING_DBEG,    '#{',     EXPR_FNAME,
                :tSTRING_CONTENT, "1+1}",   EXPR_FNAME, # HUH? this is BS
                :tSTRING_END,     "\"",     EXPR_LIT)
  end

  def test_yylex_symbol_double_escape_octal
    setup_lexer ":\"Variet\\303\\240\""

    adv = @lex.next_token
    act_token, act_value = adv
    act_value = act_value.first

    assert_equal :tSYMBOL, act_token
    assert_match EXPR_LIT, @lex.lex_state
    # Force comparison of encodings
    assert_equal "Varietà", act_value
  end

  def test_yylex_symbol_single
    assert_lex3(":'symbol'",
                nil,
                :tSYMBOL, "symbol", EXPR_LIT)
  end

  def test_yylex_symbol_single_escape_chars
    assert_lex3(":'s\\tri\\ng'",
                nil,
                :tSYMBOL, "s\\tri\\ng", EXPR_LIT)
  end

  def test_yylex_symbol_single_noninterp
    assert_lex3(':\'symbol#{1+1}\'',
                nil,
                :tSYMBOL, 'symbol#{1+1}', EXPR_LIT)
  end

  def test_yylex_symbol_zero_byte
    assert_lex(":\"symbol\0\"", nil,
                :tSYMBOL, "symbol\0", EXPR_LIT)
  end

  def test_yylex_ternary1
    assert_lex3("a ? b : c",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tEH,         "?", EXPR_BEG,
                :tIDENTIFIER, "b", EXPR_ARG,
                :tCOLON,      ":", EXPR_BEG,
                :tIDENTIFIER, "c", EXPR_ARG)

    assert_lex3("a ?bb : c", # GAH! MATZ!!!
                nil,
                :tIDENTIFIER, "a",  EXPR_CMDARG,
                :tEH,         "?",  EXPR_BEG,
                :tIDENTIFIER, "bb", EXPR_ARG,
                :tCOLON,      ":",  EXPR_BEG,
                :tIDENTIFIER, "c",  EXPR_ARG)

    assert_lex3("42 ?",
                nil,
                :tINTEGER, 42,  EXPR_NUM,
                :tEH,      "?", EXPR_BEG)
  end

  def test_yylex_tilde
    assert_lex3("~", nil, :tTILDE, "~", EXPR_BEG)
  end

  def test_yylex_tilde_unary
    self.lex_state = EXPR_FNAME

    assert_lex3("~@", nil, :tTILDE, "~", EXPR_ARG)
  end

  def test_yylex_uminus
    assert_lex3("-blah",
                nil,
                :tUMINUS,     "-",    EXPR_BEG,
                :tIDENTIFIER, "blah", EXPR_ARG)
  end

  def test_yylex_underscore
    assert_lex3("_var", nil, :tIDENTIFIER, "_var", EXPR_CMDARG)
  end

  def test_yylex_underscore_end
    assert_lex3("__END__\n",
                nil,
                RubyLexer::EOF, RubyLexer::EOF, nil)
  end

  def test_yylex_uplus
    assert_lex3("+blah",
                nil,
                :tUPLUS,      "+",    EXPR_BEG,
                :tIDENTIFIER, "blah", EXPR_ARG)
  end

  def test_zbug_float_in_decl
    assert_lex3("def initialize(u = 0.0, s = 0.0",
                nil,
                :kDEF,        "def",        EXPR_FNAME,
                :tIDENTIFIER, "initialize", EXPR_ENDFN,
                :tLPAREN2,    "(",          EXPR_PAR,
                :tIDENTIFIER, "u",          EXPR_ARG,
                :tEQL,        "=",          EXPR_BEG,
                :tFLOAT,      0.0,          EXPR_NUM,
                :tCOMMA,      ",",          EXPR_PAR,
                :tIDENTIFIER, "s",          EXPR_ARG,
                :tEQL,        "=",          EXPR_BEG,
                :tFLOAT,      0.0,          EXPR_NUM)
  end

  def test_zbug_id_equals
    assert_lex3("a = 0.0",
                nil,
                :tIDENTIFIER, "a", EXPR_CMDARG,
                :tEQL,        "=", EXPR_BEG,
                :tFLOAT,      0.0, EXPR_NUM)
  end

  def test_zbug_no_spaces_in_decl
    assert_lex3("def initialize(u=0.0,s=0.0",
                nil,
                :kDEF,        "def",        EXPR_FNAME,
                :tIDENTIFIER, "initialize", EXPR_ENDFN,
                :tLPAREN2,    "(",          EXPR_PAR,
                :tIDENTIFIER, "u",          EXPR_ARG,
                :tEQL,        "=",          EXPR_BEG,
                :tFLOAT,      0.0,          EXPR_NUM,
                :tCOMMA,      ",",          EXPR_PAR,
                :tIDENTIFIER, "s",          EXPR_ARG,
                :tEQL,        "=",          EXPR_BEG,
                :tFLOAT,      0.0,          EXPR_NUM)
  end
end
