#!/usr/local/bin/ruby -w

$TESTING = true

$: << "lib"

require "minitest/autorun"
require "ruby2ruby"
require "pt_testcase"
require "fileutils"
require "tmpdir"
require "ruby_parser" if ENV["CHECK_SEXPS"]

class R2RTestCase < ParseTreeTestCase
  def self.previous key
    "ParseTree"
  end

  def self.generate_test klass, node, data, input_name, _output_name
    output_name = data.key?("Ruby2Ruby") ? "Ruby2Ruby" : "Ruby"

    klass.class_eval <<-EOM
      def test_#{node}
        pt = #{data[input_name].inspect}
        rb = #{data[output_name].inspect}

        refute_nil pt, \"ParseTree for #{node} undefined\"
        refute_nil rb, \"Ruby for #{node} undefined\"

        assert_equal rb, @processor.process(pt)
      end
    EOM
  end
end

start = __LINE__

class TestRuby2Ruby < R2RTestCase
  def setup
    super
    @check_sexp = ENV["CHECK_SEXPS"]
    @processor = Ruby2Ruby.new
  end

  def do_not_check_sexp!
    @check_sexp = false
  end

  def test_util_dthing_dregx
    inn = util_thingy(:dregx)
    out = '/a"b#{(1 + 1)}c"d\/e/'
    exp = /a"b2c"d\/e/

    assert_equal exp, eval(out)

    assert_equal out[1..-2], @processor.util_dthing(:dregx, inn)
  end

  def test_util_dthing_dstr
    inn = util_thingy(:dstr)
    out = '"a\"b#{(1 + 1)}c\"d/e"'
    exp = 'a"b2c"d/e'

    assert_equal exp, eval(out)

    assert_equal out[1..-2], @processor.util_dthing(:dstr, inn)
  end

  def test_util_dthing_dregx_bug?
    inn = s(:dregx, '[\/\"]', s(:evstr, s(:lit, 42)))
    out = '/[\/\"]#{42}/'
    exp =  /[\/\"]42/

    assert_equal out[1..-2], @processor.util_dthing(:dregx, inn)
    assert_equal exp, eval(out)
  end

  def test_hash_parens_str
    inn = s(:hash, s(:lit, :k), s(:str, "banana"))
    out = '{ :k => "banana" }'
    assert_parse inn, out
  end

  def test_hash_parens_lit
    inn = s(:hash, s(:lit, :k), s(:lit, 0.07))
    out = "{ :k => 0.07 }"
    assert_parse inn, out
  end

  def test_hash_parens_bool
    inn = s(:hash, s(:lit, :k), s(:true))
    out = "{ :k => true }"
    assert_parse inn, out
  end

  def test_hash_parens_nil
    inn = s(:hash, s(:lit, :k), s(:nil))
    out = "{ :k => nil }"
    assert_parse inn, out
  end

  def test_hash_parens_lvar
    inn = s(:hash, s(:lit, :k), s(:lvar, :a))
    out = "{ :k => a }"
    assert_parse inn, out
  end

  def test_hash_parens_call
    inn = s(:hash, s(:lit, :k), s(:call, nil, :foo, s(:lit, :bar)))
    out = "{ :k => foo(:bar) }"
    assert_parse inn, out
  end

  def test_hash_parens_iter
    iter = s(:iter, s(:call, nil, :foo), 0, s(:str, "bar"))
    inn = s(:hash, s(:lit, :k), iter)
    out = '{ :k => (foo { "bar" }) }'
    assert_parse inn, out
  end

  def test_hash_shorthand
    inn = s(:hash, s(:lit, :k), nil)
    out = '{ k: }'

    assert_parse inn, out
  end

  def test_hash_shorthand_invalid_key_type
    do_not_check_sexp!

    inn = s(:hash, s(:str, 'k'), nil)
    out = '{ k: }'
    assert_raises do
      assert_parse inn, out
    end
  end

  def test_and_alias
    inn = s(:and, s(:true), s(:alias, s(:lit, :a), s(:lit, :b)))
    out = "true and (alias :a :b)"
    assert_parse inn, out
  end

  def test_attr_reader_diff
    inn = s(:defn, :same, s(:args), s(:ivar, :@diff))
    out = "def same\n  @diff\nend"
    assert_parse inn, out
  end

  def test_attr_reader_same
    do_not_check_sexp!

    inn = s(:defn, :same, s(:args), s(:ivar, :@same))
    out = "attr_reader :same"
    assert_parse inn, out
  end

  def test_attr_reader_double
    inn = s(:defn, :same, s(:args), s(:ivar, :@same), s(:ivar, :@diff))
    out = "def same\n  @same\n  @diff\nend"
    assert_parse inn, out
  end

  def test_attr_reader_same_name_diff_body
    do_not_check_sexp!

    inn = s(:defn, :same, s(:args), s(:not, s(:ivar, :@same)))
    out = "def same\n  (not @same)\nend"
    assert_parse inn, out
  end

  def test_attr_writer_diff
    inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@diff, s(:lvar, :o)))
    out = "def same=(o)\n  @diff = o\nend"
    assert_parse inn, out
  end

  def assert_str exp, src
    assert_equal s(:str, exp), RubyParser.new.process(src)
  end

  def assert_dstr exp, int, src
    assert_equal s(:dstr, exp, s(:evstr, int).compact), RubyParser.new.process(src)
  end

  def assert_r2r exp, sexp
    assert_equal exp, Ruby2Ruby.new.process(sexp)
  end

  def assert_rt src, exp = src.dup
    assert_equal exp, Ruby2Ruby.new.process(RubyParser.new.parse(src))
  end

  def test_bug_033
    # gentle reminder to keep some sanity
    #
    # Use %q("...") for raw input strings
    # Use %q(...) for raw output to avoid double-\'s
    # Use %(...) for output strings
    #
    # don't use '...' at all
    # only use  "..." within sexps

    # "\t"
    assert_str %(\t),     %q("\t")
    assert_r2r %q("\\t"), s(:str, "\t")
    assert_rt  %q("\t")

    # "\\t"
    assert_str %(\t),     %q("\\t")
    assert_r2r %q("\\t"), s(:str, "\t")
    assert_rt  %q("\\t")

    # "\\\\t"
    assert_str %(\\t),      %q("\\\\t")
    assert_r2r %q("\\\\t"), s(:str, "\\t")
    assert_rt  %q("\\\\t")

    # "\t#{}"
    assert_dstr %(\t), nil,  %q("\t#{}")
    assert_r2r  %q("\t#{}"), s(:dstr, "\t", s(:evstr))
    assert_rt   %q("\t#{}")

    # "\\t#{}"
    assert_dstr %(\t), nil,   %q("\\t#{}")
    assert_r2r  %q("\\t#{}"), s(:dstr, "\t", s(:evstr))
    assert_rt   %q("\\t#{}")

    # "\\\\t#{}"
    assert_dstr %(\\t), nil,    %q("\\\\t#{}")
    assert_r2r  %q("\\\\t#{}"), s(:dstr, "\\t", s(:evstr))
    assert_rt   %q("\\\\t#{}")
  end

  def test_bug_043
    inn = s(:defn, :check, s(:args),
            s(:rescue,
              s(:call, nil, :foo),
              s(:resbody, s(:array), s(:call, nil, :bar), s(:call, nil, :bar))),
            s(:call, nil, :bar),
            s(:if,
              s(:call, nil, :foo),
              s(:return, s(:call, nil, :bar)),
              s(:call, nil, :bar)))

    out = "def check\n  begin\n    foo\n  rescue\n    bar\n    bar\n  end\n  bar\n  if foo then\n    return bar\n  else\n    bar\n  end\nend"

    assert_parse inn, out
  end

  def test_bug_044
    inn = s(:if,
            s(:call,
              s(:match3, s(:lit, /a/), s(:call, nil, :foo)),
              :or,
              s(:call, nil, :bar)),
            s(:call, nil, :puts, s(:call, nil, :bar)),
            nil)
    out = "puts(bar) if (foo =~ /a/).or(bar)"

    assert_parse inn, out
  end

  def test_bug_045
    # return foo.baaaaaaar ? ::B.newsss(true) : ::B.newadsfasdfasdfasdfasdsssss(false)

    inn = s(:return,
            s(:if,
              s(:call, s(:call, nil, :foo), :baaaaaaar),
              s(:call, s(:colon3, :B), :newsss, s(:true)),
              s(:call, s(:colon3, :B), :newadsfasdfasdfasdfasdsssss, s(:false))))

    out = "return (if foo.baaaaaaar then\n  ::B.newsss(true)\nelse\n  ::B.newadsfasdfasdfasdfasdsssss(false)\nend)"

    assert_parse inn, out
  end

  def assert_masgn exp, *args
    inn = s(:iter, s(:call, nil, :a), s(:args, *args))
    out = "a { |#{exp}| }"
    assert_parse inn, out
  end

  def test_iter_masgn_double_bug
    assert_masgn("b",
                 :b)
    assert_masgn("b, c",
                 :b, :c)
    assert_masgn("(b, c)",
                 s(:masgn, :b, :c))
    assert_masgn("(b, c), d",
                 s(:masgn, :b, :c), :d)
    assert_masgn("b, (c, d), e",
                 :b, s(:masgn, :c, :d), :e)
    assert_masgn("(b, (c, d), e), f",
                 s(:masgn, :b, s(:masgn, :c, :d), :e), :f)
    assert_masgn("(((b, c), d, e), f), g",
                 s(:masgn, s(:masgn, s(:masgn, :b, :c), :d, :e), :f), :g)
  end

  def test_attr_writer_double
    inn = s(:defn, :same=, s(:args, :o),
            s(:iasgn, :@same, s(:lvar, :o)), s(:iasgn, :@diff, s(:lvar, :o)))
    out = "def same=(o)\n  @same = o\n  @diff = o\nend"
    assert_parse inn, out
  end

  def test_attr_writer_same_name_diff_body
    inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@same, s(:lit, 42)))
    out = "def same=(o)\n  @same = 42\nend"
    assert_parse inn, out
  end

  def test_attr_writer_same
    do_not_check_sexp!

    inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@same, s(:lvar, :o)))
    out = "attr_writer :same"
    assert_parse inn, out
  end

  def test_dregx_slash
    do_not_check_sexp!

    inn = util_thingy(:dregx)
    out = '/a"b#{(1 + 1)}c"d\/e/'
    assert_parse inn, out, /a"b2c"d\/e/
  end

  def test_dstr_quote
    inn = util_thingy(:dstr)
    out = '"a\"b#{(1 + 1)}c\"d/e"'
    assert_parse inn, out, 'a"b2c"d/e'
  end

  def test_dsym_quote
    inn = util_thingy(:dsym)
    out = ':"a\"b#{(1 + 1)}c\"d/e"'
    assert_parse inn, out, :'a"b2c"d/e'
  end

  def test_lit_regexp_slash
    do_not_check_sexp! # dunno why on this one

    assert_parse s(:lit, /blah\/blah/), '/blah\/blah/', /blah\/blah/
  end

  def test_call_kwsplat
    inn = s(:call, nil, :test_splat, s(:hash, s(:kwsplat, s(:call, nil, :testing))))
    out = "test_splat(**testing)"

    assert_parse inn, out
  end

  def test_call_arg_assoc_kwsplat
    inn = s(:call, nil, :f,
           s(:lit, 1),
           s(:hash, s(:lit, :kw), s(:lit, 2), s(:kwsplat, s(:lit, 3))))
    out = "f(1, :kw => 2, **3)"

    assert_parse inn, out
  end

  def test_call_kwsplat_x
    inn = s(:call, nil, :a, s(:hash, s(:kwsplat, s(:lit, 1))))
    out = "a(**1)"

    assert_parse inn, out
  end

  def test_defn_kwargs2
    inn = s(:defn, :initialize,
            s(:args, :arg,
              s(:kwarg, :kw1, s(:nil)),
              s(:kwarg, :kw2, s(:nil)),
              :"**args"),
            s(:nil))
    out = "def initialize(arg, kw1: nil, kw2: nil, **args)\n  # do nothing\nend"

    assert_parse inn, out
  end

  def test_call_self_index
    assert_parse s(:call, s(:self), :[], s(:lit, 42)), "self[42]"
  end

  def test_call_self_index_equals
    assert_parse(s(:attrasgn, s(:self), :[]=, s(:lit, 42), s(:lit, 24)),
                 "self[42] = 24")
    assert_parse(s(:attrasgn, s(:self), :[]=, s(:lit, 1), s(:lit, 2), s(:lit, 3)),
                 "self[1, 2] = 3")
  end

  def test_call_arglist_hash_first_last
    inn = s(:call, nil, :method,
            s(:hash, s(:lit, :a), s(:lit, 1)),
            s(:lvar, :b),
            s(:hash, s(:lit, :c), s(:lit, 1)))
    out = "method({ :a => 1 }, b, :c => 1)"

    assert_parse inn, out
  end

  def test_call_arglist_if
    inn = s(:call,
            s(:lvar, :a),
            :+,
            s(:if,
              s(:lvar, :b),
              s(:lvar, :c),
              s(:lvar, :d)))

    out = "(a + (b ? (c) : (d)))"
    assert_parse inn, out
  end

  def test_defn_kwsplat
    inn = s(:defn, :test, s(:args, :"**testing"), s(:nil))
    out = "def test(**testing)\n  # do nothing\nend"
    assert_parse inn, out
  end

  def test_defn_rescue_return
    inn = s(:defn, :blah, s(:args),
           s(:rescue,
             s(:lasgn, :a, s(:lit, 1)),
             s(:resbody, s(:array), s(:return, s(:str, "a")))))
    out = "def blah\n  a = 1\nrescue\n  return \"a\"\nend"

    assert_parse inn, out
  end

  def test_forward_args__defn
    inn = s(:defn, :x, s(:args, :a, s(:forward_args)), s(:nil))
    out = "def x(a, ...)\n  # do nothing\nend"

    assert_parse inn, out
  end

  def test_forward_args__call
    inn = s(:call, nil, :y, s(:forward_args))
    out = "y(...)"

    assert_parse inn, out
  end

  def test_shadow_block_args
    inn = s(:iter,
            s(:call, nil, :a),
            s(:args,
              s(:shadow, :b, :c)))
    out = 'a { |; b, c| }'

    assert_parse inn, out
  end

  def test_masgn_block_arg
    inn = s(:iter,
            s(:call,
              s(:nil),
              :x),
            s(:args, s(:masgn, :a, :b)),
            s(:dstr, "",
              s(:evstr, s(:lvar, :a)),
              s(:str, "="),
              s(:evstr, s(:lvar, :b))))
    out = 'nil.x { |(a, b)| "#{a}=#{b}" }'

    assert_parse inn, out
  end

  def test_single_nested_masgn_block_arg
    inn = s(:iter,
            s(:call, nil, :a),
            s(:args,
              s(:masgn,
                s(:masgn,
                  s(:masgn, :b)))))
    out = "a { |(((b)))| }"

    assert_parse inn, out
  end

  def test_multiple_nested_masgn_array
    inn = s(:masgn,
            s(:array,
              s(:masgn, s(:array, s(:lasgn, :a), s(:lasgn, :b))),
              s(:lasgn, :c)),
            s(:to_ary, s(:call, nil, :fn)))
    out = "(a, b), c = fn"

    assert_parse inn, out
  end

  def test_masgn_wtf
    inn = s(:block,
            s(:masgn,
              s(:array, s(:lasgn, :k), s(:lasgn, :v)),
              s(:splat,
                s(:call,
                  s(:call, nil, :line),
                  :split,
                  s(:lit, /\=/), s(:lit, 2)))),
            s(:attrasgn,
              s(:self),
              :[]=,
              s(:lvar, :k),
              s(:call, s(:lvar, :v), :strip)))

    out = "k, v = *line.split(/\\=/, 2)\nself[k] = v.strip\n"

    assert_parse inn, out
  end

  def test_masgn_splat_wtf
    inn = s(:masgn,
            s(:array, s(:lasgn, :k), s(:lasgn, :v)),
            s(:splat,
              s(:call,
                s(:call, nil, :line),
                :split,
                s(:lit, /\=/), s(:lit, 2))))
    out = 'k, v = *line.split(/\\=/, 2)'
    assert_parse inn, out
  end

  def test_match3_asgn
    inn = s(:match3, s(:lit, //), s(:lasgn, :y, s(:call, nil, :x)))
    out = "(y = x) =~ //"
    # "y = x =~ //", which matches on x and assigns to y (not what sexp says).
    assert_parse inn, out
  end

  def test_preexe
    inn = s(:iter, s(:preexe), 0, s(:block, s(:lit, 1), s(:lit, 2), s(:lit, 3)))
    out = "BEGIN {\n  1\n  2\n  3\n}"

    assert_parse inn, out
  end

  def test_safe_attrasgn
    inn = s(:safe_attrasgn,
            s(:call, nil, :x),
            :y=,
            s(:lit, 1))

    out = "x&.y = 1"

    assert_parse inn, out
  end

  def test_safe_call
    inn = s(:safe_call,
            s(:safe_call,
              s(:call, nil, :x),
              :y),
              :z,
              s(:lit, 1))

    out = "x&.y&.z(1)"
    assert_parse inn, out
  end

  def test_safe_call_binary
    inn = s(:safe_call,
            s(:call, nil, :x),
            :>,
            s(:lit, 1))

    out = "x&.>(1)"
    assert_parse inn, out
  end

  def test_safe_op_asgn
    do_not_check_sexp! # TODO: fix!

    inn = s(:safe_op_asgn,
            s(:call, nil, :x),
            s(:call, nil, :z, s(:lit, 1)),
            :y,
            :+)

    out = "x&.y += z(1)"
    assert_parse inn, out
  end

  def test_safe_op_asgn2
    inn = s(:safe_op_asgn2,
            s(:call, nil, :x),
            :y=,
            :"||",
            s(:lit, 1))

    out = "x&.y ||= 1"
    assert_parse inn, out
  end

  def test_splat_call
    inn = s(:call, nil, :x,
            s(:splat,
              s(:call,
                s(:call, nil, :line),
                :split,
                s(:lit, /\=/), s(:lit, 2))))

    out = 'x(*line.split(/\=/, 2))'
    assert_parse inn, out
  end

  def test_resbody_short_with_defn_multiple
    inn = s(:defn,
            :foo,
            s(:args),
            s(:rescue,
              s(:lasgn, :a, s(:lit, 1)),
              s(:resbody,
                s(:array),
                s(:call, nil, :log),
                s(:call, nil, :raise))))
    out = "def foo\n  a = 1\nrescue\n  log\n  raise\nend"
    assert_parse inn, out
  end

  def test_regexp_options
    inn = s(:match3,
            s(:dregx,
              "abc",
              s(:evstr, s(:call, nil, :x)),
              s(:str, "def"),
              4),
            s(:str, "a"))
    out = '"a" =~ /abc#{x}def/m'
    assert_parse inn, out
  end

  def test_resbody_short_with_rescue_args
    inn = s(:rescue,
            s(:call, nil, :blah),
            s(:resbody, s(:array, s(:const, :A), s(:const, :B)), s(:array)))
    out = "begin\n  blah\nrescue A, B\n  []\nend"
    assert_parse inn, out
  end

  def test_call_binary_call_with_hash_arg
    # args << {:key => 24} if 42

    inn = s(:if, s(:lit, 42),
            s(:call, s(:call, nil, :args),
              :<<,
              s(:hash, s(:lit, :key), s(:lit, 24))),
            nil)

    out = "(args << { :key => 24 }) if 42"

    assert_parse inn, out
  end

  def test_binary_operators
    # (1 > 2)
    Ruby2Ruby::BINARY.each do |op|
      inn = s(:call, s(:lit, 1), op, s(:lit, 2))
      out = "(1 #{op} 2)"
      assert_parse inn, out
    end
  end

  def test_binary_operators_with_multiple_arguments
    Ruby2Ruby::BINARY.each do |op|
      inn = s(:call, s(:lvar, :a), op, s(:lit, 2), s(:lit, 3))
      out = "a.#{op}(2, 3)"
      assert_parse inn, out
    end
  end

  def test_call_empty_hash
    inn = s(:call, nil, :foo, s(:hash))
    out = "foo({})"
    assert_parse inn, out
  end

  def test_if_empty
    inn = s(:if, s(:call, nil, :x), nil, nil)
    out = "if x then\n  # do nothing\nend"
    assert_parse inn, out
  end

  def test_case_in_normal_01
    assert_case_in "var", s(:lasgn, :var)
  end

  def test_case_in_normal_02
    assert_case_in "^var", s(:lvar, :var)
  end

  def test_case_in_normal_04
    assert_case_in "A if true", s(:if, s(:true), s(:const, :A), nil)
  end

  def test_case_in_normal_05
    assert_case_in "A unless true", s(:if, s(:true), nil, s(:const, :A))
  end

  def test_case_in_normal_06
    assert_case_in "A::B",   s(:const, s(:colon2, s(:const, :A), :B))
  end

  def test_case_in_normal_07
    assert_case_in "A | B", s(:or, s(:const, :A), s(:const, :B)), "(A | B)"

    # TODO: assert_case_in "(A or B)", s(:const, s(:colon2, s(:colon3, :A), :B))
  end

  def test_case_in_normal_08
    assert_case_in "::A::B", s(:const, s(:colon2, s(:colon3, :A), :B))
  end

  def test_case_in_normal_09
    assert_case_in "A", s(:const, :A)
  end

  def test_case_in__array_pat_00
    assert_case_in "Object[]", s(:array_pat, s(:const, :Object))
  end

  def test_case_in__array_pat_01
    assert_case_in "[]", s(:array_pat)
  end

  def test_case_in__array_pat_02
    assert_case_in "[*, ::NilClass]", s(:array_pat, nil, :*, s(:colon3, :NilClass))
  end

  def test_case_in__array_pat_03
    assert_case_in "[*, :b, :c]", s(:array_pat, nil, :*, s(:lit, :b), s(:lit, :c))
  end

  def test_case_in__array_pat_04
    assert_case_in "[[:b, ^c], [:d, ^e]]", s(:array_pat, nil, s(:array_pat, nil, s(:lit, :b), s(:lvar, :c)), s(:array_pat, nil, s(:lit, :d), s(:lvar, :e)))
  end

  def test_case_in__array_pat_06
    assert_case_in "[A, *, B]", s(:array_pat, nil, s(:const, :A), :*, s(:const, :B))
  end

  def test_case_in__array_pat_07
    assert_case_in "[-> (b) { true }, ^c]", s(:array_pat, nil, s(:iter, s(:lambda), s(:args, :b), s(:true)), s(:lvar, :c))
  end

  def test_case_in__array_pat_09
    assert_case_in "[:a, ^b, ^c, [:d, *e, nil]]", s(:array_pat, nil, s(:lit, :a), s(:lvar, :b), s(:lvar, :c), s(:array_pat, nil, s(:lit, :d), :"*e", s(:nil)))
  end

  def test_case_in__array_pat_14
    assert_case_in "A[*list]", s(:array_pat, s(:const, :A), :"*list")
  end

  def test_case_in__array_pat_15
    assert_case_in "B[C => d]", s(:array_pat, s(:const, :B), s(:lasgn, :d, s(:const, :C)))
  end

  def test_case_in__array_pat_16
    assert_case_in "B[^c]", s(:array_pat, s(:const, :B), s(:lvar, :c))
  end

  def test_case_in__array_pat_19
    assert_case_in "[^@a, ^$b, ^@@c]", s(:array_pat, nil, s(:ivar, :@a), s(:gvar, :$b), s(:cvar, :@@c)) # HACK: really not sure about this one
  end

  def test_case_in__find_pat_1
    assert_case_in "[*a, :+, *b]", s(:find_pat, nil, :"*a",
                                     s(:lit, :+),
                                     :"*b")
  end

  def test_case_in__find_pat_2
    assert_case_in "[*, :b, ^c, *]", s(:find_pat, nil,
                                       :*,
                                       s(:lit, :b), s(:lvar, :c),
                                       :*)
  end

  def test_case_in__find_pat_3
    assert_case_in("Array(*b, n, { a: }, m, *a)",
                   s(:find_pat,
                     s(:const, :Array),
                     :"*b",
                     s(:lasgn, :n),
                     s(:hash_pat, nil, s(:lit, :a), nil),
                     s(:lasgn, :m),
                     :"*a"),
                   "Array[*b, n, { a: }, m, *a]")
  end

  def test_case_in__find_pat_4
    assert_case_in("*b, n, { a: }, m, *a", s(:find_pat,
                                             nil,
                                             :"*b",
                                             s(:lasgn, :n),
                                             s(:hash_pat, nil, s(:lit, :a), nil),
                                             s(:lasgn, :m),
                                             :"*a"),
                   "[*b, n, { a: }, m, *a]")
  end

  def test_case_in__find_pat_5
    assert_case_in("Array(*lhs, ^b, *rhs)", s(:find_pat,
                                              s(:const, :Array),
                                              :"*lhs",
                                              s(:lvar, :b),
                                              :"*rhs"),
                   "Array[*lhs, ^b, *rhs]")
  end

  def test_case_in__find_pat_6
    assert_case_in("Array[*lhs, b, *rhs]", s(:find_pat,
                                             s(:const, :Array),
                                             :"*lhs",
                                             s(:lasgn, :b),
                                             :"*rhs"))
  end

  def test_case_in__find_pat_7
    assert_case_in("Array[*lhs, :b, *rhs]", s(:find_pat,
                                              s(:const, :Array),
                                              :"*lhs",
                                              s(:lit, :b),
                                              :"*rhs"))
  end

  def test_case_in_10
    assert_case_in("[nil, nil, nil]",
                   s(:array_pat,
                     nil,
                     s(:nil),
                     s(:nil),
                     s(:nil)))
  end

  def test_case_in_32_2
    assert_case_in "1..3", s(:dot2, s(:lit, 1), s(:lit, 3)), "(1..3)"
  end

  def test_case_in_32_3
    assert_case_in "1...3", s(:dot3, s(:lit, 1), s(:lit, 3)), "(1...3)"
  end

  def test_case_in_36
    pt = s(:array_pat, nil,
           s(:lit, :a), s(:lasgn, :b), s(:lvar, :d), :"*e", s(:nil))

    assert_case_in "[:a, b, ^d, *e, nil]", pt
  end

  def test_case_in_42
    rb = "case :a\nin [:b, *_] then\n  nil\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               nil,
               s(:lit, :b),
               :"*_",
              ),
             s(:nil)),
           nil)

    assert_parse pt, rb
    assert_variant pt, "case :a\nin :b, *_ then\n  nil\nend"
  end

  def test_case_in_42_2
    rb = "case :a\nin A[*list] then\n  nil\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               s(:const, :A),
               :"*list"),
             s(:nil)),
           nil)

    assert_parse pt, rb
    assert_variant pt, "case :a\nin A(*list) then\n  nil\nend"
  end

  def test_case_in_67
    rb = "case :a\nin 1.. then nil\nend"
    rb = "case :a\nin (1..) then\n  nil\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in, s(:dot2, s(:lit, 1), nil),
             s(:nil)),
           nil)

    assert_parse pt, rb
  end

  def test_case_in_76
    assert_case_in "`echo hi`", s(:xstr, "echo hi")
  end

  def test_case_in_77
    assert_case_in "/regexp/", s(:lit, /regexp/)
  end

  def test_case_in_79
    assert_case_in "%w[a b]", s(:array_pat, nil, s(:str, "a"), s(:str, "b")), "[\"a\", \"b\"]"
  end

  def test_case_in_80
    assert_case_in "%I[a b]", s(:array_pat, nil, s(:lit, :a), s(:lit, :b)), "[:a, :b]"
  end

  def test_case_in_83
    pt = s(:array_pat, nil,
           s(:iter, s(:lambda), s(:args, :b),
             s(:true)),
           s(:lasgn, :c))

    assert_case_in "[-> (b) { true }, c]", pt
  end

  def test_case_in_85
    pt = s(:array_pat, nil,
           s(:array_pat, nil,
             s(:lit, :b),
             s(:lasgn, :c)),
           s(:array_pat,
             nil,
             s(:lit, :d),
             s(:lvar, :e)),
          )

    assert_case_in "[[:b, c], [:d, ^e]]", pt
  end

  def test_case_in__hash_pat_00
    assert_case_in "{}", s(:hash_pat, nil)
  end

  def test_case_in__hash_pat_01
    assert_case_in "**nil",   s(:hash_pat, nil, s(:kwrest, :"**nil")), "{ **nil }"
  end

  def test_case_in__hash_pat_03
    assert_case_in "a:", s(:hash_pat, nil, s(:lit, :a), nil), "{ a: }"
  end

  def test_case_in__hash_pat_06
    assert_case_in "a:1, **r",s(:hash_pat, nil, s(:lit, :a), s(:lit, 1), s(:kwrest, :"**r")), "{ a: 1, **r }"
  end

  def test_case_in__hash_pat_08
    assert_case_in "{ b: [Hash, *] }", s(:hash_pat, nil, s(:lit, :b), s(:array_pat, nil, s(:const, :Hash), :*))
  end

  def test_case_in__hash_pat_09
    assert_case_in("{ b: Integer => x, d: \"e\", f: }",
                   s(:hash_pat, nil,
                     s(:lit, :b), s(:lasgn, :x, s(:const, :Integer)),
                     s(:lit, :d), s(:str, "e"), s(:lit, :f), nil))
  end

  def test_case_in__hash_pat_10
    assert_case_in "{ b: ^c, **r }", s(:hash_pat, nil, s(:lit, :b), s(:lvar, :c), s(:kwrest, :"**r"))
  end

  def test_case_in__hash_pat_11
    assert_case_in "{ b: \"c\", d: \"e\" }", s(:hash_pat, nil, s(:lit, :b), s(:str, "c"), s(:lit, :d), s(:str, "e"))
  end

  def test_case_in__hash_pat_12
    assert_case_in "{ b: true }", s(:hash_pat, nil, s(:lit, :b), s(:true))
  end

  def test_case_in__hash_pat_14
    assert_case_in "Object[b: 1]", s(:hash_pat, s(:const, :Object), s(:lit, :b), s(:lit, 1))
  end

  def test_interpolation_and_escapes
    # log_entry = "  \e[#{message_color}m#{message}\e[0m   "
    inn = s(:lasgn, :log_entry,
            s(:dstr, "  \e[",
              s(:evstr, s(:call, nil, :message_color)),
              s(:str, "m"),
              s(:evstr, s(:call, nil, :message)),
              s(:str, "\e[0m   ")))
    out = "log_entry = \"  \\e[#\{message_color}m#\{message}\\e[0m   \""

    assert_parse inn, out
  end

  def test_class_comments
    inn = s(:class, :Z, nil)
    inn.comments = "# x\n# y\n"
    out = "# x\n# y\nclass Z\nend"
    assert_parse inn, out
  end

  def test_module_comments
    inn = s(:module, :Z)
    inn.comments = "# x\n# y\n"
    out = "# x\n# y\nmodule Z\nend"
    assert_parse inn, out
  end

  def test_method_comments
    inn = s(:defn, :z, s(:args), s(:nil))
    inn.comments = "# x\n# y\n"
    out = "# x\n# y\ndef z\n  # do nothing\nend"
    assert_parse inn, out
  end

  def test_nested_ensure
    inn = s(:ensure, s(:lit, 1), s(:ensure, s(:lit, 2), s(:lit, 3)))
    out = "begin\n  1\nensure\n  begin\n    2\n  ensure\n    3\n  end\nend"
    assert_parse inn, out
  end

  def test_nested_rescue
    inn = s(:ensure, s(:lit, 1), s(:rescue, s(:lit, 2), s(:resbody, s(:array), s(:lit, 3))))
    out = "begin\n  1\nensure\n  2 rescue 3\nend"
    assert_parse inn, out
  end

  def test_nested_rescue_exception
    inn = s(:ensure,
            s(:lit, 1),
            s(:rescue, s(:lit, 2),
              s(:resbody, s(:array, s(:const, :Exception)),
                s(:lit, 3))))
    out = "begin\n  1\nensure\n  begin\n    2\n  rescue Exception\n    3\n  end\nend"
    assert_parse inn, out
  end

  def test_op_asgn
    do_not_check_sexp! # TODO: fix!

    inn = s(:op_asgn,
            s(:call, nil, :x),
            s(:call, nil, :z, s(:lit, 1)),
            :y,
            :+)

    out = "x.y += z(1)"
    assert_parse inn, out
  end

  def test_rescue_block
    inn = s(:rescue,
            s(:call, nil, :alpha),
            s(:resbody, s(:array),
              s(:call, nil, :beta),
              s(:call, nil, :gamma)))
    out = "begin\n  alpha\nrescue\n  beta\n  gamma\nend"
    assert_parse inn, out
  end

  def test_array_adds_parens_around_rescue
    inn = s(:array,
            s(:lvar, :a),
            s(:rescue, s(:lvar, :b), s(:resbody, s(:array), s(:lvar, :c))))
    out = "[a, (b rescue c)]"

    assert_parse inn, out
  end

  def test_call_arglist_rescue
    inn = s(:call, nil, :method,
            s(:rescue,
              s(:lvar, :a),
              s(:resbody, s(:array), s(:lvar, :b))))
    out = "method((a rescue b))"
    assert_parse inn, out
  end

  def test_unless_vs_if_not
    do_not_check_sexp! # TODO: remove? dunno if that's possible w/ this one

    rb1 = "a unless b"
    rb2 = "a if (not b)"
    rb3 = "a if ! b"

    assert_parse ruby_parser.parse(rb1), rb1

    assert_parse ruby_parser.parse(rb2), rb1

    assert_parse ruby_parser.parse(rb3), rb1
  end

  def ruby_parser
    parser = RubyParser.for_current_ruby

    %i[a b c d].each do |v|
      parser.env[v] = :lvar
    end

    parser
  end

  def assert_parse sexp, expected_ruby, expected_eval = nil
    assert_equal expected_ruby, @processor.process(sexp), "sexp -> ruby"
    assert_equal expected_eval, eval(expected_ruby) if expected_eval
    assert_variant sexp, expected_ruby if @check_sexp
  end

  def assert_variant sexp, expected_ruby
    assert_equal sexp, ruby_parser.process(expected_ruby), "ruby -> sexp"
  end

  def assert_case_in lit, exp_pt, normal_lit = nil
    rb = "case :a\nin #{normal_lit || lit} then\n  # do nothing\nend"

    exp_pt.deep_each { |s| s.line ||= 2 }
    exp_pt.line ||= 2

    # flunk "redundant: #{lit.inspect}" if normal_lit == lit
    # flunk "redundant: #{lit.inspect}" if normal_lit && normal_lit[1..-2] == lit
    normal_lit, lit = lit, lit[1..-2] if lit =~ /^\[.+\]$/ && !normal_lit

    if ENV["VERBOSE_TEST"] then
      puts
      puts rb
    end

    pt = s(:case, s(:lit, :a).line(1),
           s(:in, exp_pt, nil).line(2),
           nil).line(1)

    if normal_lit then
      assert_variant pt, "case :a\nin #{lit} then\n  # do nothing\nend"
    end

    assert_parse pt, rb
  end

  def util_thingy(type)
    s(type,
      'a"b',
      s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1))),
      s(:str, 'c"d/e'))
  end
end

####################
#         impl
#         old  new
#
# t  old    0    1
# e
# s
# t  new    2    3

tr2r = File.read(__FILE__).lines[start + 1..__LINE__ - 2].join
ir2r = File.read("lib/ruby2ruby.rb")

require "ruby_parser"

def morph_and_eval src, from, to, processor
  parser = RubyParser.for_current_ruby rescue RubyParser.new
  new_src = processor.new.process(parser.process(src.sub(from, to)))

  eval new_src

  new_src
end

unless ENV["SIMPLE"] then
  ____ = morph_and_eval tr2r, /TestRuby2Ruby/, "TestRuby2Ruby2", Ruby2Ruby
  ruby = morph_and_eval ir2r, /Ruby2Ruby/,     "Ruby2Ruby2",     Ruby2Ruby
  ____ = morph_and_eval ruby, /Ruby2Ruby2/,    "Ruby2Ruby3",     Ruby2Ruby2

  class TestRuby2Ruby1 < TestRuby2Ruby
    def setup
      super
      @processor = Ruby2Ruby2.new
    end
  end

  class TestRuby2Ruby3 < TestRuby2Ruby2
    def setup
      super
      @processor = Ruby2Ruby2.new
    end
  end

  class TestRuby2Ruby4 < TestRuby2Ruby2
    def setup
      super
      @processor = Ruby2Ruby3.new
    end
  end
end
