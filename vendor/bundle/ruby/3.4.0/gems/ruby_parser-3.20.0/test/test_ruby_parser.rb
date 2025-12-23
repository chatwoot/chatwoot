# encoding: utf-8

ENV["VERBOSE"] = "1"

require "minitest/autorun"
require "ruby_parser"

$: << File.expand_path("~/Work/p4/zss/src/sexp_processor/dev/lib")

require "pt_testcase"

class Sexp
  alias oldeq2 ==
  # TODO: push up to Sexp
  def == other # :nodoc:
    if other.class == self.class then
      super and
        (line.nil? or other.line.nil? or line == other.line)
    else
      false
    end
  end
end

module TestRubyParserShared
  def setup
    super
    # p :test => [self.class, __name__]
  end

  BLOCK_DUP_MSG = "Both block arg and actual block given."

  def test_bug120
    skip "not ready for this yet"

    rb = "def f; if /(?<foo>bar)/ =~ 'bar' && p(foo); foo; end; end; f"
    pt = s(:block,
           s(:defn, :f, s(:args),
             s(:if,
               s(:and,
                 s(:match2, s(:lit, /(?<foo>bar)/), s(:str, "bar")),
                 s(:call, nil, :p, s(:lvar, :foo))),
               s(:lvar, :foo),
               nil)),
           s(:call, nil, :f))

    assert_parse rb, pt
  end

  def after_process_hook klass, node, data, input_name, output_name
    assert_equal 1, @result.line, "should have proper line number" if
      node !~ /rescue|begin|ensure/ # remove_begin keeps inner line number
  end

  def test_BEGIN
    rb = "BEGIN { 42 }"
    pt = s(:iter, s(:preexe), 0, s(:lit, 42))

    assert_parse rb, pt
  end

  def test_BEGIN_not_toplevel
    rb = "class Foo\n  BEGIN {\n    42\n  }\nend"

    assert_syntax_error rb, "BEGIN is permitted only at toplevel"
  end

  def test___ENCODING__
    rb = "__ENCODING__"
    pt = s(:colon2, s(:const, :Encoding), :UTF_8)

    assert_parse rb, pt
  end

  def test_alias_gvar_backref
    rb = "alias $MATCH $&"
    pt = s(:valias, :$MATCH, :$&)

    assert_parse rb, pt
  end

  def test_alias_resword
    rb = "alias in out"
    pt = s(:alias, s(:lit, :in), s(:lit, :out))

    assert_parse rb, pt
  end

  def test_and_multi
    rb = "true and\nnot false and\ntrue"
    pt = s(:and,
           s(:true),
           s(:and,
             s(:call, s(:false).line(2), :!).line(2),
             s(:true).line(3)).line(2))

    assert_parse rb, pt
  end

  def test_aref_args_assocs
    rb = "[1 => 2]"
    pt = s(:array, s(:hash, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_array_line_breaks
    # It seems like arrays are roughly created when a certain element is created
    # In ruby > 1.9 it seems like that is after the last element, so the array
    # itself is assigned line 3 (since the last element is on line 3) and for
    # ruby <= 1.9 it seems to get created after the first element, so the array
    # itself is assigned line 2 (since the first element is on line 2).
    # This seems to happen since arrays like this are created with a line in
    # ruby_parser.yy like `result = s(:array, val[0])`. So, the array is not
    # created by itself. The creation of the array itself is deferred until there
    # is an element to create it with. That seems to mess up line numbers
    # for the array. Luckily, the arary elements all seemt to get the correct
    # line number.
    rb = "[\n'a',\n'b']\n1"
    pt = s(:block,
           s(:array,
             s(:str, "a").line(2),
             s(:str, "b").line(3)),
           s(:lit, 1).line(4)).line 1
    assert_parse rb, pt
  end

  def test_attr_asgn_colon_id
    rb = "A::b = 1"
    pt = s(:attrasgn, s(:const, :A), :b=, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_attrasgn_array_arg
    rb = "a[[1, 2]] = 3"
    pt = s(:attrasgn,
           s(:call, nil, :a),
           :[]=,
           s(:array,
             s(:lit, 1),
             s(:lit, 2)),
           s(:lit, 3))

    assert_parse rb, pt
  end

  def test_attrasgn_array_lhs
    rb = '[1, 2, 3, 4][from .. to] = ["a", "b", "c"]'
    pt = s(:attrasgn,
           s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3), s(:lit, 4)),
           :[]=,
           s(:dot2,
             s(:call, nil, :from),
             s(:call, nil, :to)),
           s(:array, s(:str, "a"), s(:str, "b"), s(:str, "c")))

    assert_parse rb, pt
  end

  def test_attrasgn_primary_dot_constant
    rb = "a.B = 1"
    pt = s(:attrasgn, s(:call, nil, :a), :"B=", s(:lit, 1))

    assert_parse rb, pt
  end

  def test_backticks_interpolation_line
    rb = 'x `#{y}`'
    pt = s(:call, nil, :x,
           s(:dxstr, "",
             s(:evstr,
               s(:call, nil, :y))))

    assert_parse rb, pt
  end

  def test_bang_eq
    rb = "1 != 2"
    pt = s(:not, s(:call, s(:lit, 1), :"==", s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_begin_else_return_value # overridden below, warns < 2.6
    rb = "begin; else 2; end"
    pt = s(:lit, 2)

    assert_output "", "else without rescue is useless\n" do
      assert_parse rb, pt
    end
  end

  def test_begin_ensure_no_bodies
    rb = "begin\nensure\nend"
    pt = s(:ensure, s(:nil).line(2)).line(2)

    assert_parse rb, pt
  end

  def test_begin_rescue_ensure_no_bodies
    rb = "begin\nrescue\nensure\nend"
    pt = s(:ensure,
           s(:rescue,
             s(:resbody, s(:array).line(2),
               nil).line(2)
            ).line(2),
           s(:nil).line(3)
          ).line(2)

    assert_parse rb, pt
  end

  def test_begin_rescue_else_ensure_bodies
    rb = "begin\n  1\nrescue\n  2\nelse\n  3\nensure\n  4\nend"
    pt = s(:ensure,
           s(:rescue,
             s(:lit, 1).line(2),
             s(:resbody, s(:array).line(3),
               s(:lit, 2).line(4)).line(3),
             s(:lit, 3).line(6)).line(2),
           s(:lit, 4).line(8)).line(2)

    s(:ensure, s(:rescue, s(:resbody, s(:array), nil)), s(:nil))

    assert_parse rb, pt
  end

  def test_begin_rescue_else_ensure_no_bodies
    rb = "begin\n\nrescue\n\nelse\n\nensure\n\nend"
    pt = s(:ensure,
           s(:rescue,
             s(:resbody, s(:array).line(3),
               # TODO: s(:nil)
               nil
              ).line(3),
            ).line(3),
          s(:nil).line(7)).line(3)

    s(:ensure, s(:rescue, s(:resbody, s(:array), nil)), s(:nil))

    assert_parse rb, pt
  end

  def test_block_append
    head = s(:args).line 1
    tail = s(:zsuper).line 2
    expected = s(:block,
                 s(:args),
                 s(:zsuper).line(2)).line 1
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_append_begin_begin
    head = s(:begin, s(:args)).line 1
    tail = s(:begin, s(:args).line(2)).line 2
    expected = s(:block,
                 s(:args),
                 s(:begin,
                   s(:args).line(2)).line(2)).line 1
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_append_block
    head = s(:block, s(:args))
    tail = s(:zsuper).line(2)
    expected = s(:block,
                 s(:args),
                 s(:zsuper).line(2)).line 1
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_append_nil_head
    head = nil
    tail = s(:zsuper)
    expected = s(:zsuper)
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_append_nil_tail
    head = s(:args)
    tail = nil
    expected = s(:args)
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_append_tail_block
    head = s(:call, nil, :f1).line 1
    tail = s(:block,
             s(:undef, s(:lit, :x)).line(2),
             s(:undef, s(:lit, :y)).line(3)).line 2
    expected = s(:block,
                 s(:call, nil, :f1),
                 s(:block,
                   s(:undef, s(:lit, :x)).line(2),
                   s(:undef, s(:lit, :y)).line(3)).line(2)).line 1
    assert_equal expected, processor.block_append(head, tail)
  end

  def test_block_decomp_splat
    rb = "f { |(*a)| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, s(:masgn, :"*a")))

    assert_parse rb, pt
  end

  def test_bug121
    skip "not ready for this yet"

    rb = "if (/a/../b/)../c/; end"
    pt = s(:if,
           s(:flip2,
             s(:flip2,
               s(:match, s(:lit, /a/)),
               s(:match, s(:lit, /b/))),
             s(:match, (s(:lit, /c/)))),
             nil,
             nil) # maybe?

    assert_parse rb, pt
  end

  def test_bug169
    rb = "m () {}"
    pt = s(:iter, s(:call, nil, :m, s(:nil)), 0)

    assert_parse rb, pt
  end

  def test_bug170
    rb = '$-'
    pt = s(:gvar, :"$-")

    if processor.class.version >= 21
      assert_syntax_error rb, /unexpected \$undefined/
    else
      assert_parse rb, pt
    end
  end

  def test_bug179
    rb = "p ()..nil"
    pt = s(:call, nil, :p, s(:dot2, s(:begin), s(:nil)))

    assert_parse rb, pt
  end

  def test_bug190
    rb = %{%r'\\\''} # stupid emacs

    assert_parse rb, s(:lit, %r%'%)

    rb = %{%r'\\''}
    pt = s(:lit, /'/)

    assert_parse rb, pt
  end

  def test_bug191
    pt = s(:if, s(:call, nil, :a), s(:str, ""), s(:call, nil, :b))

    rb = "a ? '': b"
    assert_parse rb, pt

    rb = "a ? \"\": b"
    assert_parse rb, pt
  end

  def test_bug202
    rb = "$测试 = 1\n测试 = 1"
    pt = s(:block,
           s(:gasgn, :$测试, s(:lit, 1)),
           s(:lasgn, :测试, s(:lit, 1).line(2)).line(2))

    assert_parse rb, pt
  end

  def test_bug236
    rb = "x{|a|}"
    pt = s(:iter, s(:call, nil, :x), s(:args, :a))

    assert_parse rb, pt

    rb = "x{|a,|}"
    pt = s(:iter, s(:call, nil, :x), s(:args, :a, nil))

    assert_parse rb, pt
  end

  def test_bug290
    rb = "begin\n  foo\nend"
    pt = s(:call, nil, :foo).line(2)

    assert_parse rb, pt
  end

  def test_bug_and
    rb = "true and []"
    pt = s(:and, s(:true), s(:array))

    assert_parse rb, pt

    rb = "true and\ntrue"
    pt = s(:and, s(:true), s(:true).line(2))

    assert_parse rb, pt
  end

  def test_bug_args_masgn
    rb = "f { |(a, b), c| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, s(:masgn, :a, :b), :c))

    assert_parse rb, pt.dup
  end

  def test_bug_args_masgn2
    rb = "f { |((a, b), c), d| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, s(:masgn, s(:masgn, :a, :b), :c), :d))

    assert_parse rb, pt
  end

  def test_bug_begin_else # overridden below, warns < 2.6
    rb = "begin 1; else; 2 end"
    pt = s(:block, s(:lit, 1), s(:lit, 2))

    assert_output "", "else without rescue is useless\n" do
      assert_parse rb, pt
    end
  end

  def test_bug_call_arglist_parens
    rb = "g ( 1), 2"
    pt = s(:call, nil, :g, s(:lit, 1), s(:lit, 2))

    assert_parse rb, pt

    rb = <<-CODE
      def f
        g ( 1), 2
      end
    CODE

    pt = s(:defn, :f, s(:args),
           s(:call, nil, :g, s(:lit, 1).line(2), s(:lit, 2).line(2)).line(2))

    assert_parse rb, pt

    rb = <<-CODE
      def f()
        g (1), 2
      end
    CODE

    assert_parse rb, pt
  end

  def test_bug_case_when_regexp
    rb = "case :x; when /x/ then end"
    pt = s(:case, s(:lit, :x),
           s(:when, s(:array, s(:lit, /x/)), nil),
           nil)

    assert_parse rb, pt
  end

  def test_bug_comma
    rb = "if test ?d, dir then end"
    pt = s(:if,
           s(:call, nil, :test, s(:str, "d"), s(:call, nil, :dir)),
           nil,
           nil)

    assert_parse rb, pt
  end

  def test_bug_comment_eq_begin
    rb = "\n\n#\n=begin\nblah\n=end\n\n"
    exp = rb.strip + "\n"

    refute_parse rb
    assert_equal exp, processor.lexer.comments
  end

  def test_bug_cond_pct
    rb = "case; when %r%blahblah%; end"
    pt = s(:case, nil, s(:when, s(:array, s(:lit, /blahblah/)), nil), nil)

    assert_parse rb, pt
  end

  def test_bug_masgn_right
    rb = "f { |a, (b, c)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :b, :c)))

    assert_parse rb, pt
  end

  def test_bug_not_parens
    rb = "not(a)"
    pt = s(:call, s(:call, nil, :a), :"!")

    assert_parse rb, pt
  end

  def test_bug_op_asgn_rescue
    rb = "a ||= b rescue nil"
    pt = s(:op_asgn_or,
           s(:lvar, :a),
           s(:lasgn, :a,
             s(:rescue,
               s(:call, nil, :b),
               s(:resbody, s(:array), s(:nil)))))

    assert_parse rb, pt
  end

  def test_call_and
    rb = "1 & 2"
    pt = s(:call, s(:lit, 1), :&, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_args_command
    rb = "a.b c.d 1"
    pt = s(:call, s(:call, nil, :a), :b,
           s(:call, s(:call, nil, :c), :d,
             s(:lit, 1)))

    assert_parse rb, pt
  end

  def test_call_array_arg
    rb = "1 == [:b, :c]"
    pt = s(:call, s(:lit, 1), :==, s(:array, s(:lit, :b), s(:lit, :c)))

    assert_parse rb, pt
  end

  def test_call_bang_command_call
    rb = "! a.b 1"
    pt = s(:not, s(:call, s(:call, nil, :a), :b, s(:lit, 1)))

    assert_parse rb, pt
  end

  def test_call_bang_squiggle
    rb = "1 !~ 2"
    pt = s(:not, s(:call, s(:lit, 1), :=~, s(:lit, 2))) # TODO: check for 1.9+

    assert_parse rb, pt
  end

  def test_call_carat
    rb = "1 ^ 2"
    pt = s(:call, s(:lit, 1), :^, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_colon2
    rb = "A::b"
    pt = s(:call, s(:const, :A), :b)

    assert_parse rb, pt
  end

  def test_call_div
    rb = "1 / 2"
    pt = s(:call, s(:lit, 1), :/, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_env
    processor.env[:a] = :lvar
    rb = "a.happy"
    pt = s(:call, s(:lvar, :a), :happy)

    assert_parse rb, pt
  end

  def test_call_eq3
    rb = "1 === 2"
    pt = s(:call, s(:lit, 1), :===, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_gt
    rb = "1 > 2"
    pt = s(:call, s(:lit, 1), :>, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_lt
    rb = "1 < 2"
    pt = s(:call, s(:lit, 1), :<, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_lte
    rb = "1 <= 2"
    pt = s(:call, s(:lit, 1), :<=, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_not
    rb = "not 42"
    pt = s(:not, s(:lit, 42))

    assert_parse rb, pt
  end

  def test_call_pipe
    rb = "1 | 2"
    pt = s(:call, s(:lit, 1), :|, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_rshift
    rb = "1 >> 2"
    pt = s(:call, s(:lit, 1), :>>, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_self_brackets
    rb = "self[1]"
    pt = s(:call, s(:self), :[], s(:lit, 1))

    assert_parse rb, pt
  end

  def test_call_spaceship
    rb = "1 <=> 2"
    pt = s(:call, s(:lit, 1), :<=>, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_star
    rb = "1 * 2"
    pt = s(:call, s(:lit, 1), :"*", s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_star2
    rb = "1 ** 2"
    pt = s(:call, s(:lit, 1), :"**", s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_unary_bang
    rb = "!1"
    pt = s(:not, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_class_comments
    rb = "# blah 1\n# blah 2\n\nclass X\n  # blah 3\n  def blah\n    # blah 4\n  end\nend"
    pt = s(:class, :X, nil,
           s(:defn, :blah, s(:args).line(6), s(:nil).line(6)).line(6)).line(4)

    assert_parse rb, pt

    assert_equal "# blah 1\n# blah 2\n\n", result.comments
    assert_equal "# blah 3\n", result.defn.comments
  end

  def test_cond_unary_minus
    rb = "if -1; end"
    pt = s(:if, s(:lit, -1), nil, nil)

    assert_parse rb, pt
  end

  def test_dasgn_icky2
    rb = "a do\n  v = nil\n  begin\n    yield\n  rescue Exception => v\n    break\n  end\nend"
    pt = s(:iter,
           s(:call, nil, :a),
           0,
           s(:block,
             s(:lasgn, :v, s(:nil).line(2)).line(2),
             s(:rescue,
               s(:yield).line(4),
               s(:resbody,
                 s(:array, s(:const, :Exception).line(5),
                   s(:lasgn, :v, s(:gvar, :$!).line(5)).line(5)).line(5),
                 s(:break).line(6)).line(5)).line(4)).line(2))

    assert_parse rb, pt
  end

  def test_defined_eh_parens
    rb = "defined?(42)"
    pt = s(:defined, s(:lit, 42))

    assert_parse rb, pt
  end

  def test_defn_comments
    rb = "# blah 1\n# blah 2\n\ndef blah\nend"
    pt = s(:defn, :blah, s(:args).line(4), s(:nil).line(4)).line(4)

    assert_parse rb, pt
    assert_equal "# blah 1\n# blah 2\n\n", result.comments
  end

  def test_defns_reserved
    rb = "def self.return; end"
    pt = s(:defs, s(:self), :return, s(:args), s(:nil))

    assert_parse rb, pt
  end

  def test_defs_as_arg_with_do_block_inside
    rb = "p def self.b; x.y do; end; end"
    pt = s(:call,
           nil,
           :p,
           s(:defs, s(:self), :b, s(:args),
             s(:iter, s(:call, s(:call, nil, :x), :y), 0)))

    assert_parse rb, pt
  end

  def test_defs_comments
    rb = "# blah 1\n# blah 2\n\ndef self.blah\nend"
    pt = s(:defs, s(:self).line(4), :blah, s(:args).line(4),
           s(:nil).line(4)).line(4)

    assert_parse rb, pt
    assert_equal "# blah 1\n# blah 2\n\n", result.comments
  end

  def test_do_bug # TODO: rename
    rb = "a 1\na.b do |c|\n  # do nothing\nend"
    pt = s(:block,
           s(:call, nil, :a, s(:lit, 1)),
           s(:iter,
             s(:call, s(:call, nil, :a).line(2), :b).line(2),
             s(:args, :c).line(2)).line(2))

    assert_parse rb, pt
  end

  def test_double_block_error_01
    assert_syntax_error "a(1, &b) { }", BLOCK_DUP_MSG
  end

  def test_double_block_error_02
    assert_syntax_error "a(1, &b) do end", BLOCK_DUP_MSG
  end

  def test_double_block_error_03
    assert_syntax_error "a 1, &b do end", BLOCK_DUP_MSG
  end

  def test_double_block_error_04
    assert_syntax_error "m.a(1, &b) { }", BLOCK_DUP_MSG
  end

  def test_double_block_error_05
    assert_syntax_error "m.a(1, &b) do end", BLOCK_DUP_MSG
  end

  def test_double_block_error_06
    assert_syntax_error "m.a 1, &b do end", BLOCK_DUP_MSG
  end

  def test_double_block_error_07
    assert_syntax_error "m::a(1, &b) { }", BLOCK_DUP_MSG
  end

  def test_double_block_error_08
    assert_syntax_error "m::a(1, &b) do end", BLOCK_DUP_MSG
  end

  def test_double_block_error_09
    assert_syntax_error "m::a 1, &b do end", BLOCK_DUP_MSG
  end

  def test_dstr_evstr
    rb = %q("#{'a'}#{b}")
    pt = s(:dstr, "a", s(:evstr, s(:call, nil, :b)))

    assert_parse rb, pt
  end

  def test_dstr_evstr_empty_end
    rb = ':"#{field}"'
    pt = s(:dsym, "", s(:evstr, s(:call, nil, :field)))

    assert_parse rb, pt
  end

  def test_dstr_str
    rb = %q("#{'a'} b")
    pt = s(:str, "a b")

    assert_parse rb, pt
  end

  def test_dsym_to_sym
    pt = s(:alias, s(:lit, :<<), s(:lit, :>>))

    rb = "alias :<< :>>"
    assert_parse rb, pt

    rb = 'alias :"<<" :">>"'
    assert_parse rb, pt
  end

  def test_dsym_esc_to_sym
    rb = ':"Variet\303\240"'
    pt = s(:lit, :Varietà)

    assert_parse rb, pt
  end

  def test_empty
    refute_parse ""
  end

  def test_eq_begin_line_numbers
    rb = "1\n=begin\ncomment\ncomment\n=end\n2"
    pt = s(:block,
           s(:lit, 1),
           s(:lit, 2).line(6))

    assert_parse rb, pt
  end

  def test_eq_begin_why_wont_people_use_their_spacebar?
    rb = "h[k]=begin\n       42\n     end"
    pt = s(:attrasgn,
           s(:call, nil, :h), :[]=, s(:call, nil, :k),
           s(:lit, 42).line(2))

    assert_parse rb, pt
  end

  def test_evstr_evstr
    rb = %q("#{a}#{b}")
    pt = s(:dstr, "", s(:evstr, s(:call, nil, :a)), s(:evstr, s(:call, nil, :b)))

    assert_parse rb, pt
  end

  def test_evstr_str
    rb = %q("#{a} b")
    pt = s(:dstr, "", s(:evstr, s(:call, nil, :a)), s(:str, " b"))

    assert_parse rb, pt
  end

  def test_flip2_env_lvar
    rb = "if a..b then end"
    pt = s(:if, s(:flip2, s(:call, nil, :a), s(:call, nil, :b)), nil, nil)

    assert_parse rb, pt

    top_env = processor.env.env.first

    assert_kind_of Hash, top_env

    flip = top_env.find { |k, _| k =~ /^flip/ }

    assert flip
    assert_equal :lvar, flip.last
  end

  def test_fubar_nesting
    err = "class definition in method body"

    assert_syntax_error "def a; class B; end; end", err
    assert_syntax_error "def a; def b; end; class B; end; end", err
  end

  def test_heredoc_bad_hex_escape
    rb = "s = <<eos\na\\xE9b\neos"
    pt = s(:lasgn, :s, s(:str, "a\xE9b\n".b))

    assert_parse rb, pt
  end

  def test_heredoc_lineno
    rb = "c = <<'CCC'\nline2\nline3\nline4\nCCC\n\nd = 42"
    pt = s(:block,
           s(:lasgn, :c, s(:str, "line2\nline3\nline4\n")),
           s(:lasgn, :d, s(:lit, 42).line(7)).line(7))

    assert_parse rb, pt
  end

  def test_pctW_lineno
    rb = "%W(a\\nb\nc\ d\ne\\\nf\ng\y h\\y i\\\y)"
    pt = s(:array,
           s(:str, "a\nb"),
           s(:str, "c").line(2),
           s(:str, "d").line(2),
           s(:str, "e\nf").line(3),
           s(:str, "gy").line(5),
           s(:str, "hy").line(5),
           s(:str, "iy").line(5))

    assert_parse rb, pt
  end

  def test_heredoc_bad_oct_escape
    rb = "s = <<-EOS\na\\247b\ncöd\nEOS\n"
    pt = s(:lasgn, :s, s(:str, "a\xa7b\nc\xc3\xb6d\n".b))

    assert_parse rb, pt
  end

  def test_heredoc_unicode
    rb = "<<OOTPÜT\n.\nOOTPÜT\n"
    pt = s(:str, ".\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_carriage_return_escapes
    rb = "<<EOS\nfoo\\rbar\nbaz\\r\nEOS\n"
    pt = s(:str, "foo\rbar\nbaz\r\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_carriage_return_escapes_windows
    rb = "<<EOS\r\nfoo\\rbar\r\nbaz\\r\r\nEOS\r\n"
    pt = s(:str, "foo\rbar\nbaz\r\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_extra_carriage_returns
    rb = "<<EOS\nfoo\rbar\r\nbaz\nEOS\n"
    pt = s(:str, "foo\rbar\nbaz\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_extra_carriage_returns_windows
    rb = "<<EOS\r\nfoo\rbar\r\r\nbaz\r\nEOS\r\n"
    pt = s(:str, "foo\rbar\r\nbaz\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_extra_carriage_horrible_mix?
    rb = "<<'eot'\r\nbody\r\neot\n"
    pt = s(:str, "body\r\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_interpolation_and_carriage_return_escapes
    rb = "<<EOS\nfoo\\r\#@bar\nEOS\n"
    pt = s(:dstr, "foo\r", s(:evstr, s(:ivar, :@bar).line(2)).line(2), s(:str, "\n").line(2))

    assert_parse rb, pt
  end

  def test_heredoc_with_interpolation_and_carriage_return_escapes_windows
    rb = "<<EOS\r\nfoo\\r\#@bar\r\nEOS\r\n"
    pt = s(:dstr,
           "foo\r",
           s(:evstr, s(:ivar, :@bar).line(2)).line(2),
           s(:str, "\n").line(2))

    assert_parse rb, pt
  end

  def test_heredoc_with_only_carriage_returns
    rb = "<<EOS\n\r\n\r\r\n\\r\nEOS\n"
    pt = s(:str, "\n\r\n\r\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_only_carriage_returns_windows
    rb = "<<EOS\r\n\r\r\n\r\r\r\n\\r\r\nEOS\r\n"
    pt = s(:str, "\r\n\r\r\n\r\n")

    assert_parse rb, pt
  end

  def test_heredoc_with_not_global_interpolation
    rb = "<<-HEREDOC\n#${\nHEREDOC"
    pt = s(:str, "\#${\n")

    assert_parse rb, pt
  end

  def test_i_fucking_hate_line_numbers
    rb = <<-END.gsub(/^ {6}/, "")
      if true
        p 1
        a.b 2
        c.d 3, 4
        e.f 5
        g.h 6, 7
        p(1)
        a.b(2)
        c.d(3, 4)
        e.f(5)
        g.h(6, 7)
      end
    END

    pt = s(:if, s(:true),
           s(:block,
             s(:call, nil, :p, s(:lit, 1).line(2)).line(2),
             s(:call, s(:call, nil, :a).line(3), :b,
               s(:lit, 2).line(3)).line(3),
             s(:call, s(:call, nil, :c).line(4), :d,
               s(:lit, 3).line(4), s(:lit, 4).line(4)).line(4),
             s(:call, s(:call, nil, :e).line(5), :f,
               s(:lit, 5).line(5)).line(5),
             s(:call, s(:call, nil, :g).line(6), :h,
               s(:lit, 6).line(6), s(:lit, 7).line(6)).line(6),
             s(:call, nil, :p, s(:lit, 1).line(7)).line(7),
             s(:call, s(:call, nil, :a).line(8), :b,
               s(:lit, 2).line(8)).line(8),
             s(:call, s(:call, nil, :c).line(9), :d,
               s(:lit, 3).line(9), s(:lit, 4).line(9)).line(9),
             s(:call, s(:call, nil, :e).line(10), :f,
               s(:lit, 5).line(10)).line(10),
             s(:call, s(:call, nil, :g).line(11), :h,
               s(:lit, 6).line(11), s(:lit, 7).line(11)).line(11)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_i_fucking_hate_line_numbers2
    rb = <<-EOM.gsub(/^ {6}/, "")
      if true then
        p('a')
        b = 1
        p b
        c =1
      end
      a
    EOM

    pt = s(:block,
           s(:if, s(:true),
             s(:block,
               s(:call, nil, :p, s(:str, "a").line(2)).line(2),
               s(:lasgn, :b, s(:lit, 1).line(3)).line(3),
               s(:call, nil, :p, s(:lvar, :b).line(4)).line(4),
               s(:lasgn, :c, s(:lit, 1).line(5)).line(5)).line(2),
             nil),
           s(:call, nil, :a).line(7))

    assert_parse rb, pt
  end

  def test_if_elsif
    rb = "if 1; elsif 2; end"
    pt = s(:if, s(:lit, 1), nil, s(:if, s(:lit, 2), nil, nil))

    assert_parse rb, pt
  end

  def test_if_symbol
    rb = "if f :x; end"
    pt = s(:if, s(:call, nil, :f, s(:lit, :x)), nil, nil)

    assert_parse rb, pt
  end

  def test_index_0_opasgn
    rb = "a[] += b"
    pt = s(:op_asgn1, s(:call, nil, :a), nil, :+, s(:call, nil, :b))

    assert_parse rb, pt
  end

  def test_interpolated_word_array_line_breaks
    rb = "%W(\na\nb\n)\n1"
    pt = s(:block,
           s(:array,
             s(:str, "a").line(2),
             s(:str, "b").line(3)),
           s(:lit, 1).line(5))
    assert_parse rb, pt
  end

  def test_iter_args_1
    rb = "f { |a,b| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :a, :b))

    assert_parse rb, pt
  end

  def test_iter_args_3
    rb = "f { |a, (b, c), d| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :a, s(:masgn, :b, :c), :d))

    assert_parse rb, pt
  end

  def test_label_vs_string
    rb = "_buf << ':\n'"
    pt = s(:call, s(:call, nil, :_buf), :<<, s(:str, ":\n"))

    assert_parse rb, pt
  end

  def test_lasgn_arg_rescue_arg
    rb = "a = 1 rescue 2"
    pt = s(:lasgn, :a, s(:rescue, s(:lit, 1), s(:resbody, s(:array), s(:lit, 2))))

    assert_parse rb, pt
  end

  def test_lasgn_call_bracket_rescue_arg
    rb = "a = b(1) rescue 2"
    pt = s(:lasgn, :a,
           s(:rescue,
             s(:call, nil, :b, s(:lit, 1)),
             s(:resbody, s(:array), s(:lit, 2))))

    assert_parse rb, pt
  end

  def test_lasgn_command
    rb = "a = b.c 1"
    pt = s(:lasgn, :a, s(:call, s(:call, nil, :b), :c, s(:lit, 1)))

    assert_parse rb, pt
  end

  def test_lasgn_env
    rb = "a = 42"
    pt = s(:lasgn, :a, s(:lit, 42))
    expected_env = { :a => :lvar }

    assert_parse rb, pt
    assert_equal expected_env, processor.env.all
  end

  def test_lasgn_ivar_env
    rb = "@a = 42"
    pt = s(:iasgn, :@a, s(:lit, 42))

    assert_parse rb, pt
    assert_empty processor.env.all
  end

  def test_list_append
    a = s(:lit, 1)
    b = s(:lit, 2)
    c = s(:lit, 3)

    result = processor.list_append(s(:array, b.dup), c.dup)

    assert_equal s(:array, b, c), result

    result = processor.list_append(b.dup, c.dup)

    assert_equal s(:array, b, c), result

    result = processor.list_append(result, a.dup)

    assert_equal s(:array, b, c, a), result

    lhs, rhs = s(:array, s(:lit, :iter)), s(:when, s(:const, :BRANCHING), nil)
    expected = s(:array, s(:lit, :iter), s(:when, s(:const, :BRANCHING), nil))

    assert_equal expected, processor.list_append(lhs, rhs)
  end

  def test_list_prepend
    a = s(:lit, 1)
    b = s(:lit, 2)
    c = s(:lit, 3)

    result = processor.list_prepend(b.dup, s(:array, c.dup))

    assert_equal s(:array, b, c), result

    result = processor.list_prepend(b.dup, c.dup)

    assert_equal s(:array, b, c), result

    result = processor.list_prepend(a.dup, result)

    assert_equal s(:array, a, b, c), result
  end

  def test_literal_concat_dstr_dstr
    lhs      = s(:dstr, "Failed to download spec ",
                 s(:evstr, s(:call, nil, :spec_name)),
                 s(:str, " from "),
                 s(:evstr, s(:call, nil, :source_uri)),
                 s(:str, ":\n")).line 1
    rhs      = s(:dstr, "\t",
                 s(:evstr, s(:call, s(:ivar, :@fetch_error), :message))).line 2

    expected = s(:dstr, "Failed to download spec ",
                 s(:evstr, s(:call, nil, :spec_name)),
                 s(:str, " from "),
                 s(:evstr, s(:call, nil, :source_uri)),
                 s(:str, ":\n"),
                 s(:str, "\t"),
                 s(:evstr, s(:call, s(:ivar, :@fetch_error), :message)))

    lhs.deep_each do |s|
      s.line = 1
    end

    rhs.deep_each do |s|
      s.line = 1
    end

    assert_equal expected, processor.literal_concat(lhs, rhs)
  end

  def test_literal_concat_dstr_evstr
    lhs, rhs = s(:dstr, "a"), s(:evstr, s(:call, nil, :b))
    expected = s(:dstr, "a", s(:evstr, s(:call, nil, :b)))

    assert_equal expected, processor.literal_concat(lhs, rhs)
  end

  def test_literal_concat_evstr_evstr
    lhs = s(:evstr, s(:lit, 1)).line 1
    rhs = s(:evstr, s(:lit, 2)).line 2
    expected = s(:dstr, "", s(:evstr, s(:lit, 1)), s(:evstr, s(:lit, 2)))

    assert_equal expected, processor.literal_concat(lhs, rhs)
  end

  def test_literal_concat_str_evstr
    lhs = s(:str, "").line 1
    rhs = s(:evstr, s(:str, "blah").line(2)).line 2

    assert_equal s(:str, "blah"), processor.literal_concat(lhs, rhs)
  end

  def test_logical_op_12
    lhs = s(:lit, 1).line 1
    rhs = s(:lit, 2).line 2
    exp = s(:and, s(:lit, 1), s(:lit, 2).line(2)).line 1

    assert_equal exp, processor.logical_op(:and, lhs, rhs)
  end

  def test_logical_op_1234_5
    lhs = s(:and,
            s(:lit, 1),
            s(:and,
              s(:lit, 2).line(2),
              s(:and,
                s(:lit, 3).line(3),
                s(:lit, 4).line(4)).line(3)).line(2)).line 1
    rhs = s(:lit, 5).line(5)
    exp = s(:and,
            s(:lit, 1),
            s(:and,
              s(:lit, 2).line(2),
              s(:and,
                s(:lit, 3).line(3),
                s(:and,
                  s(:lit, 4).line(4),
                  s(:lit, 5).line(5)).line(4)).line(3)).line(2)).line 1

    assert_equal exp, processor.logical_op(:and, lhs, rhs)
  end

  def test_logical_op_123_4
    lhs = s(:and,
            s(:lit, 1),
            s(:and,
              s(:lit, 2).line(2),
              s(:lit, 3).line(3)).line(2)).line 1
    rhs = s(:lit, 4).line 4
    exp = s(:and,
            s(:lit, 1),
            s(:and,
              s(:lit, 2).line(2),
              s(:and,
                s(:lit, 3).line(3),
                s(:lit, 4).line(4)).line(3)).line(2)).line 1

    assert_equal exp, processor.logical_op(:and, lhs, rhs)
  end

  def test_logical_op_12_3
    lhs = s(:and,
            s(:lit, 1),
            s(:lit, 2).line(2)).line 1
    rhs = s(:lit, 3).line 3
    exp = s(:and,
            s(:lit, 1),
            s(:and,
              s(:lit, 2).line(2),
              s(:lit, 3).line(3)).line(2)).line 1

    assert_equal exp, processor.logical_op(:and, lhs, rhs)
  end

  def test_logical_op_nested_mix
    lhs = s(:or,
            s(:call, nil, :a),
            s(:call, nil, :b).line(2)).line 1
    rhs = s(:and,
            s(:call, nil, :c).line(3),
            s(:call, nil, :d).line(4)).line 3
    exp = s(:or,
            s(:or,
              s(:call, nil, :a),
              s(:call, nil, :b).line(2)),
            s(:and,
              s(:call, nil, :c).line(3),
              s(:call, nil, :d).line(4)).line(3)).line 1

    lhs.paren = true
    rhs.paren = true

    assert_equal exp, processor.logical_op(:or, lhs, rhs)
  end

  def test_magic_encoding_comment
    rb = "# encoding: utf-8\nclass ExampleUTF8ClassNameVarietà; def self.è; così = :però; end\nend\n"

    rb.force_encoding "ASCII-8BIT" if rb.respond_to? :force_encoding

    # TODO: class vars
    # TODO: odd-ternary: a ?bb : c
    # TODO: globals

    pt = s(:class, :"ExampleUTF8ClassNameVariet\303\240", nil,
           s(:defs, s(:self).line(2), :"\303\250", s(:args).line(2),
             s(:lasgn, :"cos\303\254", s(:lit, :"per\303\262").line(2)).line(2)).line(2)).line(2)

    err = RUBY_VERSION =~ /^1\.8/ ? "Skipping magic encoding comment\n" : ""

    assert_output "", err do
      assert_parse rb, pt
    end
  end

  def test_magic_encoding_comment__bad
    rb = "#encoding: bunk\n0"
    pt = s(:lit, 0).line(2)

    assert_parse rb, pt
  end

  def test_utf8_bom
    rb = "\xEF\xBB\xBF#!/usr/bin/env ruby -w\np 0\n"
    pt = s(:call, nil, :p, s(:lit, 0).line(2)).line(2)

    assert_parse rb, pt
  end

  def test_masgn_arg_colon_arg
    rb = "a, b::c = d"
    pt = s(:masgn,
           s(:array,
             s(:lasgn, :a),
             s(:attrasgn,
               s(:call, nil, :b),
               :c=)),
           s(:to_ary,
             s(:call, nil, :d)))

    assert_parse rb, pt
  end

  def test_masgn_arg_ident
    rb = "a, b.C = d"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:attrasgn, s(:call, nil, :b), :"C=")),
           s(:to_ary, s(:call, nil, :d)))

    assert_parse rb, pt
  end

  def test_masgn_colon2
    rb = "a, b::C = 1, 2"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:const, s(:colon2, s(:call, nil, :b), :C))),
           s(:array, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_masgn_colon3
    rb = "::A, ::B = 1, 2"
    pt = s(:masgn,
           s(:array, s(:const, nil, s(:colon3, :A)), s(:const, s(:colon3, :B))),
           s(:array, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_masgn_command_call
    rb = "a, = b.c 1"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a)),
           s(:to_ary, s(:call, s(:call, nil, :b), :c, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_masgn_double_paren
    rb = "((a,b))=c" # TODO: blog
    pt = s(:masgn,
           s(:array, s(:masgn, s(:array, s(:lasgn, :a), s(:lasgn, :b)))),
           s(:to_ary, s(:call, nil, :c)))

    assert_parse rb, pt
  end

  def test_masgn_lhs_splat
    rb = "*a = 1, 2, 3"
    pt = s(:masgn,
           s(:array, s(:splat, s(:lasgn, :a))),
           s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_masgn_paren
    rb = "(a, b) = c.d"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:lasgn, :b)),
           s(:to_ary, s(:call, s(:call, nil, :c), :d)))

    assert_parse rb, pt
  end

  def test_masgn_star
    rb = "* = 1"
    pt = s(:masgn,
           s(:array, s(:splat)),
           s(:to_ary, s(:lit, 1)))

    assert_parse rb, pt
  end

  def test_module_comments
    rb = "# blah 1\n  \n  # blah 2\n\nmodule X\n  # blah 3\n  def blah\n    # blah 4\n  end\nend"
    pt = s(:module, :X,
           s(:defn, :blah, s(:args).line(7), s(:nil).line(7)).line(7)).line(5)

    assert_parse rb, pt
    assert_equal "# blah 1\n\n# blah 2\n\n", result.comments
    assert_equal "# blah 3\n", result.defn.comments
  end

  def test_non_interpolated_word_array_line_breaks
    rb = "%w(\na\nb\n)\n1"
    pt = s(:block,
           s(:array,
             s(:str, "a").line(2),
             s(:str, "b").line(3)),
           s(:lit, 1).line(5))
    assert_parse rb, pt
  end

  def test_op_asgn_command_call
    rb = "a ||= b.c 2"
    pt = s(:op_asgn_or,
           s(:lvar, :a),
           s(:lasgn, :a, s(:call, s(:call, nil, :b), :c, s(:lit, 2))))

    assert_parse rb, pt
  end

  def test_op_asgn_dot_ident_command_call
    rb = "A.B ||= c 1"
    pt = s(:op_asgn, s(:const, :A), s(:call, nil, :c, s(:lit, 1)), :B, :"||")

    assert_parse rb, pt
  end

  def test_op_asgn_index_command_call
    rb = "a[:b] ||= c 1, 2"
    pt = s(:op_asgn1, s(:call, nil, :a), s(:arglist, s(:lit, :b)),
           :"||",
           s(:call, nil, :c, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_op_asgn_primary_colon_identifier1
    rb = "A::b += 1"
    pt = s(:op_asgn, s(:const, :A), s(:lit, 1), :b, :+) # TODO: check? looks wack

    assert_parse rb, pt
  end

  def test_lasgn_middle_splat
    rb = "a = b, *c, d"
    pt = s(:lasgn, :a,
           s(:svalue,
             s(:array,
               s(:call, nil, :b),
               s(:splat, s(:call, nil, :c)),
               s(:call, nil, :d))))

    assert_parse rb, pt
  end

  def test_op_asgn_primary_colon_const_command_call
    rb = "A::B *= c d"
    pt = s(:op_asgn, s(:const, :A),
           s(:call, nil, :c, s(:call, nil, :d)),
           :B, :*)

    assert_parse rb, pt
  end

  def test_op_asgn_primary_colon_identifier_command_call
    rb = "A::b *= c d"
    pt = s(:op_asgn, s(:const, :A),
           s(:call, nil, :c, s(:call, nil, :d)),
           :b, :*)

    assert_parse rb, pt
  end

  def test_op_asgn_val_dot_ident_command_call
    rb = "a.b ||= c 1"
    pt = s(:op_asgn, s(:call, nil, :a), s(:call, nil, :c, s(:lit, 1)), :b, :"||")

    assert_parse rb, pt
  end

  def test_parse_comments
    p = RubyParser.new
    sexp = p.parse <<-CODE
      # class comment
      class Inline
        def show
          # woot
        end

        # Returns a list of things
        def list
          # woot
        end
      end
    CODE

    assert_equal "# class comment\n", sexp.comments
    act = sexp.find_nodes(:defn).map(&:comments)
    exp = ["", "# Returns a list of things\n"]

    assert_equal exp, act
    assert_equal [], processor.comments
    assert_equal "", processor.lexer.comments
  end

  def test_parse_if_not_canonical
    rb = "if not var.nil? then 'foo' else 'bar'\nend"
    pt = s(:if,
           s(:call, s(:call, nil, :var), :nil?),
           s(:str, "bar"),
           s(:str, "foo"))

    assert_parse rb, pt
  end

  def test_parse_if_not_noncanonical
    rb = "if not var.nil? then 'foo' else 'bar'\nend"
    pt = s(:if,
           s(:not, s(:call, s(:call, nil, :var), :nil?)),
           s(:str, "foo"),
           s(:str, "bar"))

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_parse_line_block
    rb = "a = 42\np a"
    pt = s(:block,
           s(:lasgn, :a, s(:lit, 42)),
           s(:call, nil, :p, s(:lvar, :a).line(2)).line(2))

    assert_parse rb, pt

    assert_equal "(string)", result.file
    assert_same result.file, result.lasgn.file
    assert_same result.file, result.call.file
  end

  def test_parse_line_block_inline_comment
    rb = "a\nb # comment\nc"
    pt = s(:block,
           s(:call, nil, :a),
           s(:call, nil, :b).line(2),
           s(:call, nil, :c).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_block_inline_comment_leading_newlines
    rb = "\n\n\na\nb # comment\n# another comment\nc"
    pt = s(:block,
           s(:call, nil, :a).line(4),
           s(:call, nil, :b).line(5),
           s(:call, nil, :c).line(7)).line(4)

    assert_parse rb, pt
  end

  def test_parse_line_block_inline_multiline_comment
    rb = "a\nb # comment\n# another comment\nc"
    pt = s(:block,
           s(:call, nil, :a),
           s(:call, nil, :b).line(2),
           s(:call, nil, :c).line(4))

    assert_parse rb, pt
  end

  def test_parse_line_call_ivar_arg_no_parens_line_break
    rb = "a @b\n"
    pt = s(:call, nil, :a, s(:ivar, :@b))

    assert_parse rb, pt
  end

  def test_parse_line_call_ivar_line_break_paren
    rb = "a(@b\n)"
    pt = s(:call, nil, :a, s(:ivar, :@b))

    assert_parse rb, pt
  end

  def test_parse_line_call_no_args
    rb = "f do |x, y|\n  x + y\nend"

    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :x, :y),
           s(:call, s(:lvar, :x).line(2), :+, s(:lvar, :y).line(2)).line(2))

    assert_parse rb, pt

    _, a, b, c, = result

    assert_equal 1, a.line,   "call should have line number"
    assert_equal 1, b.line,   "masgn should have line number"
    assert_equal 2, c.line,   "call should have line number"
  end

  def test_parse_line_defn_no_parens_args
    rb = "def f a\nend"
    pt = s(:defn, :f, s(:args, :a), s(:nil))

    assert_parse rb, pt
  end

  def test_parse_line_defn_complex
    rb = "def x(y)\n  p(y)\n  y *= 2\n  return y;\nend" # TODO: remove () & ;
    pt = s(:defn, :x, s(:args, :y),
           s(:call, nil, :p, s(:lvar, :y).line(2)).line(2),
           s(:lasgn, :y, s(:call, s(:lvar, :y).line(3), :*, s(:lit, 2).line(3)).line(3)).line(3),
           s(:return, s(:lvar, :y).line(4)).line(4))

    assert_parse rb, pt

    body = result
    assert_equal 2, body.call.line,   "call should have line number"
    assert_equal 3, body.lasgn.line,  "lasgn should have line number"
    assert_equal 4, body.return.line, "return should have line number"
  end

  def test_parse_line_defn_no_parens
    pt = s(:defn, :f, s(:args), s(:nil))

    rb = "def f\nend"
    assert_parse rb, pt

    processor.reset

    rb = "def f\n\nend"
    assert_parse rb, pt
  end

  def test_parse_line_dot2
    rb = "0..\n4\na..\nb\nc"
    pt = s(:block,
           s(:lit, 0..4),
           s(:dot2,
             s(:call, nil, :a).line(3),
             s(:call, nil, :b).line(4)).line(3),
           s(:call, nil, :c).line(5))

    assert_parse rb, pt
  end

  def test_parse_line_dot3
    rb = "0...\n4\na...\nb\nc"
    pt = s(:block,
           s(:lit, 0...4),
           s(:dot3,
             s(:call, nil, :a).line(3),
             s(:call, nil, :b).line(4)).line(3),
           s(:call, nil, :c).line(5))

    assert_parse rb, pt
  end

  def test_parse_line_dstr_escaped_newline
    rb = "\"a\\n\#{\n}\"\ntrue"
    pt = s(:block,
           s(:dstr, "a\n",
             s(:evstr)),
           s(:true).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_dstr_soft_newline
    rb = "\"a\n#\{\n}\"\ntrue"
    pt = s(:block,
           s(:dstr, "a\n", s(:evstr).line(2)),
           s(:true).line(4))

    assert_parse rb, pt
  end

  def test_parse_line_evstr_after_break
    rb = "\"a\"\\\n\"\#{b}\""
    pt = s(:dstr, "a",
           s(:evstr,
             s(:call, nil, :b).line(2)).line(2))

    assert_parse rb, pt
  end

  def test_parse_line_hash_lit
    rb = "{\n:s1 => 1,\n}"
    pt = s(:hash,
           s(:lit, :s1).line(2), s(:lit, 1).line(2),
          )

    assert_parse rb, pt
  end

  def test_parse_line_heredoc
    rb = <<-CODE
      string = <<-HEREDOC.strip
        very long string
      HEREDOC
      puts string
    CODE

    pt = s(:block,
           s(:lasgn, :string,
             s(:call,
               s(:str, "        very long string\n"),
               :strip),
              ),
           s(:call, nil, :puts,
             s(:lvar, :string).line(4)).line(4)
          )

    assert_parse rb, pt
  end

  def test_parse_line_heredoc_evstr
    rb = "<<-A\na\n\#{b}\nA"
    pt = s(:dstr,
           "a\n",
           s(:evstr, s(:call, nil, :b).line(3)).line(3), s(:str, "\n").line(3)
          )

    assert_parse rb, pt
  end

  def test_parse_line_heredoc_regexp_chars
    rb = <<-CODE
      string = <<-"^D"
        very long string
      ^D
      puts string
    CODE

    pt = s(:block,
           s(:lasgn, :string,
             s(:str, "        very long string\n")),
           s(:call, nil, :puts, s(:lvar, :string).line(4)).line(4))

    assert_parse rb, pt
  end

  def test_parse_line_iter_call_no_parens
    rb = "f a do |x, y|\n  x + y\nend"

    pt = s(:iter,
           s(:call, nil, :f, s(:call, nil, :a)),
           s(:args, :x, :y),
           s(:call, s(:lvar, :x).line(2), :+,
             s(:lvar, :y).line(2)).line(2))

    assert_parse rb, pt
  end

  def test_parse_line_iter_call_parens
    rb = "f(a) do |x, y|\n  x + y\nend"

    pt = s(:iter,
           s(:call, nil, :f, s(:call, nil, :a)),
           s(:args, :x, :y),
           s(:call, s(:lvar, :x).line(2), :+, s(:lvar, :y).line(2)).line(2))

    assert_parse rb, pt

    _, a, b, c, = result

    assert_equal 1, a.line,   "call should have line number"
    assert_equal 1, b.line,   "masgn should have line number"
    assert_equal 2, c.line,   "call should have line number"
  end

  def test_parse_line_multiline_str
    rb = "\"a\nb\"\n1"
    pt = s(:block,
           s(:str, "a\nb"),
           s(:lit, 1).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_multiline_str_literal_n
    rb = "\"a\\nb\"\n1"
    pt = s(:block,
           s(:str, "a\nb"),
           s(:lit, 1).line(2))

    assert_parse rb, pt
  end

  def test_parse_line_newlines
    rb = "true\n\n"
    pt = s(:true)

    assert_parse rb, pt
  end

  def test_parse_line_op_asgn
    rb = <<-CODE
      foo +=
        bar
      baz
    CODE

    pt = s(:block,
           s(:lasgn, :foo,
             s(:call,
               s(:lvar, :foo),
               :+,
               s(:call, nil, :bar).line(2))),
           s(:call, nil, :baz).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_postexe
    rb = "END {\nfoo\n}"
    pt = s(:iter,
           s(:postexe), 0,
           s(:call, nil, :foo).line(2))

    assert_parse rb, pt
  end

  def test_parse_line_preexe
    rb = "BEGIN {\nfoo\n}"
    pt = s(:iter,
           s(:preexe), 0,
           s(:call, nil, :foo).line(2))

    assert_parse rb, pt
  end

  def test_parse_line_rescue
    rb = "begin\n  a\nrescue\n  b\nrescue\n  c\nend\n"
    pt = s(:rescue,
           s(:call, nil, :a).line(2),
           s(:resbody, s(:array).line(3),
             s(:call, nil, :b).line(4)).line(3),
           s(:resbody, s(:array).line(5),
             s(:call, nil, :c).line(6)).line(5)).line(2)

    assert_parse rb, pt
  end

  def test_parse_line_return
    rb = <<-RUBY
      def blah
        if true then
          return 42
        end
      end
    RUBY

    pt = s(:defn, :blah, s(:args),
           s(:if, s(:true).line(2),
             s(:return, s(:lit, 42).line(3)).line(3),
             nil).line(2))

    assert_parse rb, pt

    assert_equal 3, result.if.return.line
    assert_equal 3, result.if.return.lit.line
  end

  def test_parse_line_str_with_newline_escape
    rb = 'a("\n", true)'
    pt = s(:call, nil, :a,
           s(:str, "\n"),
           s(:true))

    assert_parse rb, pt
  end

  def test_parse_line_to_ary
    rb = "a,\nb = c\nd"
    pt = s(:block,
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b).line(2)),
             s(:to_ary, s(:call, nil, :c).line(2)).line(2)),
           s(:call, nil, :d).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_trailing_newlines
    rb = "a \nb"
    pt = s(:block,
           s(:call, nil, :a),
           s(:call, nil, :b).line(2))

    assert_parse rb, pt
  end

  def test_parse_until_not_canonical
    rb = "until not var.nil?\n  'foo'\nend"

    pt = s(:while,
           s(:call, s(:call, nil, :var), :nil?),
           s(:str, "foo"), true)

    assert_parse rb, pt
  end

  def test_parse_until_not_noncanonical
    rb = "until not var.nil?\n  'foo'\nend"
    pt = s(:until,
           s(:not, s(:call, s(:call, nil, :var), :nil?)),
           s(:str, "foo"), true)

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_parse_while_not_canonical
    rb = "while not var.nil?\n  'foo'\nend"
    pt = s(:until,
           s(:call, s(:call, nil, :var), :nil?),
           s(:str, "foo"), true)

    assert_parse rb, pt
  end

  def test_parse_while_not_noncanonical
    rb = "while not var.nil?\n  'foo'\nend"
    pt = s(:while,
           s(:not, s(:call, s(:call, nil, :var), :nil?)),
           s(:str, "foo"), true)

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_pipe_space
    rb = "a.b do | | end"
    pt = s(:iter, s(:call, s(:call, nil, :a), :b), s(:args))

    assert_parse rb, pt
  end

  def test_qWords_space
    rb = "%W( )"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_qwords_empty
    rb = "%w()"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_regexp
    regexps = {
      "/wtf/" => /wtf/,
      "/wtf/n" => /wtf/n,
      "/wtf/m" => /wtf/m,
      "/wtf/nm" => /wtf/nm,
      "/wtf/nmnmnmnm" => /wtf/nm,
    }

    regexps.each do |rb, lit|
      assert_parse rb, s(:lit, lit)
    end

    # TODO: add more including interpolation etc
  end

  def test_regexp_escape_extended
    assert_parse '/\“/', s(:lit, /“/)
  end

  def test_str_backslashes
    long_string = '\n' * 100
    rb = "x '#{long_string}'"
    pt = s(:call, nil, :x, s(:str, long_string))

    assert_parse rb, pt
  end

  def test_str_evstr
    rb = "\"a #\{b}\""
    pt = s(:dstr, "a ", s(:evstr, s(:call, nil, :b)))

    assert_parse rb, pt
  end

  def test_str_evstr_escape
    char = [0x00bd].pack("U")
    rb = "\"a #\{b}\\302\\275\""
    pt = s(:dstr, "a ", s(:evstr, s(:call, nil, :b)), s(:str, char))

    assert_parse rb, pt
  end

  def test_str_heredoc_interp
    rb = "<<\"\"\n\#{x}\nblah2\n\n"
    pt = s(:dstr, "",
           s(:evstr, s(:call, nil, :x).line(2)).line(2),
           s(:str, "\nblah2\n").line(2))

    assert_parse rb, pt
  end

  def test_str_interp_ternary_or_label
    env = processor.env
    env[:a] = :lvar

    rb = '"#{a.b? ? ""+a+"": ""}"'
    pt = s(:dstr,
           "",
           s(:evstr,
             s(:if,
               s(:call, s(:lvar, :a), :b?),
               s(:call, s(:call, s(:str, ""), :+, s(:lvar, :a)), :+, s(:str, "")),
               s(:str, ""))))

    assert_parse rb, pt
  end

  def test_str_newline_hash_line_number
    rb = "\"\\n\\n\\n\\n#\"\n1"
    pt = s(:block, s(:str, "\n\n\n\n#"),
                   s(:lit, 1).line(2))

    assert_parse rb, pt
  end

  def test_str_pct_nested_nested
    rb = "%{ { #\{ \"#\{1}\" } } }"
    assert_equal " { 1 } ", eval(rb)
    pt = s(:dstr, " { ", s(:evstr, s(:lit, 1)), s(:str, " } "))

    assert_parse rb, pt
  end

  def test_str_pct_Q_nested
    rb = "%Q[before [#\{nest}] after]"
    pt = s(:dstr, "before [", s(:evstr, s(:call, nil, :nest)), s(:str, "] after"))

    assert_parse rb, pt
  end

  def test_str_pct_q
    rb = "%q{a b c}"
    pt = s(:str, "a b c")

    assert_parse rb, pt
  end

  def test_str_single_newline
    rp = "a '\n';b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\n")),
           s(:call, nil, :b).line(2))

    assert_parse rp, pt
  end

  def test_str_single_escaped_newline
    rp = "a '\\n';b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\\n")),
           s(:call, nil, :b))

    assert_parse rp, pt
  end

  def test_str_single_double_escaped_newline
    rp = "a '\\\\n';b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\\n")),
           s(:call, nil, :b))

    assert_parse rp, pt
  end

  def test_str_double_newline
    rp = "a \"\n\";b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\n")),
           s(:call, nil, :b).line(2))

    assert_parse rp, pt
  end

  def test_str_double_escaped_newline
    rp = "a \"\\n\";b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\n")),
           s(:call, nil, :b))

    assert_parse rp, pt
  end

  def test_str_double_double_escaped_newline
    rp = "a \"\\\\n\";b"
    pt = s(:block,
           s(:call, nil, :a, s(:str, "\\n")),
           s(:call, nil, :b))

    assert_parse rp, pt
  end

  def test_str_str
    rb = "\"a #\{'b'}\""
    pt = s(:str, "a b")

    assert_parse rb, pt
  end

  def test_str_str_str
    rb = "\"a #\{'b'} c\""
    pt = s(:str, "a b c")

    assert_parse rb, pt
  end

  def test_super_arg
    rb = "super 42"
    pt = s(:super, s(:lit, 42))

    assert_parse rb, pt
  end

  def test_uminus_float
    rb = "-0.0"
    pt = s(:lit, -0.0)

    assert_parse rb, pt
  end

  def test_unary_minus
    rb = "-a"
    pt = s(:call, s(:call, nil, :a), :"-@")

    assert_parse rb, pt
  end

  def test_unary_plus
    rb = "+a"
    pt = s(:call, s(:call, nil, :a), :+@)

    assert_parse rb, pt
  end

  def test_unary_tilde
    rb = "~a"
    pt = s(:call, s(:call, nil, :a), :~)

    assert_parse rb, pt
  end

  def test_when_splat
    rb = "case a; when *b then; end"
    pt = s(:case, s(:call, nil, :a),
           s(:when, s(:array, s(:splat, s(:call, nil, :b))), nil),
           nil)

    assert_parse rb, pt
  end

  def test_words_interp
    rb = '%W(#{1}b)'
    pt = s(:array, s(:dstr, "", s(:evstr, s(:lit, 1)), s(:str, "b")))

    assert_parse rb, pt
  end

  def test_wtf_7
    rb = "a.b (1) {c}"
    pt = s(:iter,
           s(:call, s(:call, nil, :a), :b, s(:lit, 1)),
           0,
           s(:call, nil, :c))

    assert_parse rb, pt
  end

  def test_wtf_8
    rb = "a::b (1) {c}"
    pt =  s(:iter,
            s(:call, s(:call, nil, :a), :b, s(:lit, 1)),
            0,
            s(:call, nil, :c))

    assert_parse rb, pt
  end

  def test_yield_arg
    rb = "yield 42"
    pt = s(:yield, s(:lit, 42))

    assert_parse rb, pt
  end

  def test_yield_empty_parens
    rb = "yield()"
    pt = s(:yield)

    assert_parse rb, pt
  end
end

module TestRubyParserShared19Plus
  include TestRubyParserShared

  def test_aref_args_lit_assocs
    rb = "[1, 2 => 3]"
    pt = s(:array, s(:lit, 1), s(:hash, s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_assoc_label
    rb = "a(b:1)"
    pt = s(:call, nil, :a, s(:hash, s(:lit, :b), s(:lit, 1)))

    assert_parse rb, pt
  end

  def test_assoc_list_19
    rb = "{1, 2, 3, 4}"

    assert_parse_error rb, "(string):1 :: parse error on value \",\" (tCOMMA)"
  end

  def test_bang_eq
    rb = "1 != 2"
    pt = s(:call, s(:lit, 1), :"!=", s(:lit, 2))

    assert_parse rb, pt
  end

  def test_block_arg_opt_arg_block
    rb = "a { |b, c=1, d, &e| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, s(:lasgn, :c, s(:lit, 1)), :d, :"&e"))

    assert_parse rb, pt
  end

  def test_block_arg_opt_splat
    rb = "a { |b, c = 1, *d| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, s(:lasgn, :c, s(:lit, 1)), :"*d"))

    assert_parse rb, pt
  end

  def test_block_arg_opt_splat_arg_block_omfg
    rb = "a { |b, c=1, *d, e, &f| }"
    pt = s(:iter,
           s(:call, nil, :a),
           s(:args, :b, s(:lasgn, :c, s(:lit, 1)), :"*d", :e, :"&f"))

    assert_parse rb, pt
  end

  def test_block_arg_optional
    rb = "a { |b = 1| }"
    pt = s(:iter,
           s(:call, nil, :a),
           s(:args, s(:lasgn, :b, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_block_arg_scope
    rb = "a { |b; c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, s(:shadow, :c)))

    assert_parse rb, pt
  end

  def test_block_arg_scope2
    rb = "a {|b; c, d| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, s(:shadow, :c, :d)))

    assert_parse rb, pt
  end

  def test_block_arg_splat_arg
    rb = "a { |b, *c, d| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, :"*c", :d))

    assert_parse rb, pt
  end

  def test_block_args_opt1
    rb = "f { |a, b = 42| [a, b] }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42))),
           s(:array, s(:lvar, :a), s(:lvar, :b)))

    assert_parse rb, pt
  end

  def test_block_args_opt2
    rb = "a { | b=1, c=2 | }"
    pt = s(:iter,
           s(:call, nil, :a),
           s(:args, s(:lasgn, :b, s(:lit, 1)), s(:lasgn, :c, s(:lit, 2))))

    assert_parse rb, pt
  end

  def test_block_args_opt2_2
    rb = "f { |a, b = 42, c = 24| [a, b, c] }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), s(:lasgn, :c, s(:lit, 24))),
           s(:array, s(:lvar, :a), s(:lvar, :b), s(:lvar, :c)))

    assert_parse rb, pt
  end

  def test_block_args_opt3
    rb = "f { |a, b = 42, c = 24, &d| [a, b, c, d] }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), s(:lasgn, :c, s(:lit, 24)), :"&d"),
           s(:array, s(:lvar, :a), s(:lvar, :b), s(:lvar, :c), s(:lvar, :d)))

    assert_parse rb, pt
  end

  def test_block_break
    rb = "break foo arg do |bar| end"
    pt = s(:break,
           s(:iter,
             s(:call, nil, :foo, s(:call, nil, :arg)),
             s(:args, :bar)))

    assert_parse rb, pt
  end

  def test_block_call_operation_colon
    rb = "a.b c do end::d"
    pt = s(:call,
           s(:iter,
             s(:call, s(:call, nil, :a), :b, s(:call, nil, :c)), 0),
           :d)

    assert_parse rb, pt
  end

  def test_block_call_operation_dot
    rb = "a.b c do end.d"
    pt = s(:call,
           s(:iter,
             s(:call, s(:call, nil, :a), :b, s(:call, nil, :c)), 0),
           :d)

    assert_parse rb, pt
  end

  def test_block_command_operation_colon
    rb = "a :b do end::c :d"
    pt = s(:call,
           s(:iter, s(:call, nil, :a, s(:lit, :b)), 0),
           :c,
           s(:lit, :d))

    assert_parse rb, pt
  end

  def test_block_command_operation_dot
    rb = "a :b do end.c :d"
    pt = s(:call,
           s(:iter, s(:call, nil, :a, s(:lit, :b)), 0),
           :c,
           s(:lit, :d))

    assert_parse rb, pt
  end

  def test_block_decomp_anon_splat_arg
    rb = "f { |(*, a)| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, s(:masgn, :*, :a)))

    assert_parse rb, pt
  end

  def test_block_decomp_arg_splat
    rb = "a { |(b, *)| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:masgn, :b, :*)))

    assert_parse rb, pt
  end

  def test_block_decomp_arg_splat_arg
    rb = "f { |(a, *b, c)| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, s(:masgn, :a, :"*b", :c)))

    assert_parse rb, pt
  end

  def test_block_next
    rb = "next foo arg do |bar| end"
    pt = s(:next,
           s(:iter,
             s(:call, nil, :foo, s(:call, nil, :arg)),
             s(:args, :bar)))

    assert_parse rb, pt
  end

  def test_block_opt_arg
    rb = "a { |b=1, c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:lasgn, :b, s(:lit, 1)), :c))

    assert_parse rb, pt
  end

  def test_block_opt_splat
    rb = "a { |b = 1, *c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:lasgn, :b, s(:lit, 1)), :"*c"))

    assert_parse rb, pt
  end

  def test_block_opt_splat_arg_block_omfg
    rb = "a { |b=1, *c, d, &e| }"
    pt = s(:iter,
           s(:call, nil, :a),
           s(:args, s(:lasgn, :b, s(:lit, 1)), :"*c", :d, :"&e"))

    assert_parse rb, pt
  end

  def test_block_optarg
    rb = "a { |b = :c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:lasgn, :b, s(:lit, :c))))

    assert_parse rb, pt
  end

  def test_block_paren_splat # TODO: rename # TODO: should work on 1.8
    rb = "a { |(b, *c)| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:masgn, :b, :"*c")))

    assert_parse rb, pt
  end

  def test_block_reg_optarg
    rb = "a { |b, c = :d| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :b, s(:lasgn, :c, s(:lit, :d))))

    assert_parse rb, pt
  end

  def test_block_return
    rb = "return foo arg do |bar| end"
    pt = s(:return,
           s(:iter,
             s(:call, nil, :foo, s(:call, nil, :arg)),
             s(:args, :bar)))

    assert_parse rb, pt
  end

  def test_block_scope
    rb = "a { |;b| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:shadow, :b)))

    assert_parse rb, pt
  end

  def test_block_splat_reg
    rb = "a { |*b, c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :"*b", :c))

    assert_parse rb, pt
  end

  def test_block_yield
    rb = "yield foo arg do |bar| end"
    pt = s(:yield,
           s(:iter,
             s(:call, nil, :foo, s(:call, nil, :arg)),
             s(:args, :bar)))

    assert_parse rb, pt
  end

  def test_bug_187
    rb = "private def f\na.b do end\nend"
    pt = s(:call,
           nil,
           :private,
           s(:defn, :f, s(:args),
             s(:iter, s(:call, s(:call, nil, :a).line(2), :b).line(2), 0).line(2)))

    assert_parse rb, pt
  end

  def test_bug_args__19
    rb = "f { |(a, b)| d }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:masgn, :a, :b)),
           s(:call, nil, :d))

    assert_parse rb, pt
  end

  def test_bug_args_masgn_outer_parens__19
    rb = "f { |((k, v), i)| }"
    pt = s(:iter,               # NOTE: same sexp as test_bug_args_masgn
           s(:call, nil, :f),
           s(:args, s(:masgn, s(:masgn, :k, :v), :i)))

    assert_parse rb, pt.dup
  end

  def test_bug_hash_args
    rb = "foo(:bar, baz: nil)"
    pt = s(:call, nil, :foo,
           s(:lit, :bar),
           s(:hash, s(:lit, :baz), s(:nil)))

    assert_parse rb, pt
  end

  def test_bug_hash_args_trailing_comma
    rb = "foo(:bar, baz: nil,)"
    pt = s(:call, nil, :foo,    # NOTE: same sexp as test_bug_hash_args
           s(:lit, :bar),
           s(:hash, s(:lit, :baz), s(:nil)))

    assert_parse rb, pt
  end

  def test_call_arg_assoc
    rb = "f(1, 2=>3)"
    pt = s(:call, nil, :f, s(:lit, 1), s(:hash, s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_call_args_assoc_trailing_comma
    rb = "f(1, 2=>3,)"
    pt = s(:call, nil, :f, s(:lit, 1), s(:hash, s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_call_array_lit_inline_hash
    rb = "a([:b, :c => 1])"
    pt = s(:call, nil, :a, s(:array, s(:lit, :b), s(:hash, s(:lit, :c), s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_call_assoc
    rb = "f(2=>3)"
    pt = s(:call, nil, :f, s(:hash, s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_call_assoc_new
    rb = "f(a:3)"
    pt = s(:call, nil, :f, s(:hash, s(:lit, :a), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_call_assoc_new_if_multiline
    rb = "a(b: if :c\n1\nelse\n2\nend)"
    pt = s(:call, nil, :a,
           s(:hash,
             s(:lit, :b),
             s(:if, s(:lit, :c), s(:lit, 1).line(2), s(:lit, 2).line(4))))

    assert_parse rb, pt
  end

  def test_call_assoc_trailing_comma
    rb = "f(1=>2,)"
    pt = s(:call, nil, :f, s(:hash, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_call_bang_command_call
    rb = "! a.b 1"
    pt = s(:call, s(:call, s(:call, nil, :a), :b, s(:lit, 1)), :"!")

    assert_parse rb, pt
  end

  def test_call_colon_parens
    rb = "1::()"
    pt = s(:call, s(:lit, 1), :call)

    assert_parse rb, pt
  end

  def test_call_dot_parens
    rb = "1.()"
    pt = s(:call, s(:lit, 1), :call)

    assert_parse rb, pt
  end

  def test_call_not
    rb = "not 42"
    pt = s(:call, s(:lit, 42), :"!")

    assert_parse rb, pt
  end

  def test_call_stabby_do_end_with_block
    rb = "a -> do 1 end do 2 end"
    pt = s(:iter, s(:call, nil, :a, s(:iter, s(:lambda), 0, s(:lit, 1))), 0, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_stabby_with_braces_block
    rb = "a -> { 1 } do 2 end"
    pt = s(:iter, s(:call, nil, :a, s(:iter, s(:lambda), 0, s(:lit, 1))), 0, s(:lit, 2))

    assert_parse rb, pt
  end

  def test_call_trailing_comma
    rb = "f(1,)"
    pt = s(:call, nil, :f, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_call_unary_bang
    rb = "!1"
    pt = s(:call, s(:lit, 1), :"!")

    assert_parse rb, pt
  end

  def test_case_then_colon_19
    rb = <<-EOM
      case x
      when Fixnum : # need the space to not hit new hash arg syntax
        42
      end
    EOM

    assert_parse_error rb, "(string):2 :: parse error on value \":\" (tCOLON)"
  end

  def test_defn_arg_asplat_arg
    rb = "def call(interp, *, args) end"
    pt = s(:defn, :call, s(:args, :interp, :*, :args), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_opt_last_arg
    rb = "def m arg = false\nend"
    pt = s(:defn, :m,
           s(:args, s(:lasgn, :arg, s(:false))),
           s(:nil))

    assert_parse rb, pt
  end

  def test_defn_opt_reg
    rb = "def f(a=nil, b) end"
    pt = s(:defn, :f, s(:args, s(:lasgn, :a, s(:nil)), :b), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_opt_splat_arg
    rb = "def f (a = 1, *b, c) end"
    pt = s(:defn, :f, s(:args, s(:lasgn, :a, s(:lit, 1)), :"*b", :c), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_reg_opt_reg
    rb = "def f(a, b = :c, d) end"
    pt = s(:defn, :f, s(:args, :a, s(:lasgn, :b, s(:lit, :c)), :d), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_splat_arg
    rb = "def f(*, a) end"
    pt = s(:defn, :f, s(:args, :*, :a), s(:nil))

    assert_parse rb, pt
  end

  def test_do_colon_19
    rb = "while false : 42 end"

    assert_parse_error rb, "(string):1 :: parse error on value \":\" (tCOLON)"
  end

  def test_do_lambda
    rb = "->() do end"
    pt = s(:iter, s(:lambda), s(:args))

    assert_parse rb, pt
  end

  def test_expr_not_bang
    rb = "! a b"
    pt = s(:call, s(:call, nil, :a, s(:call, nil, :b)), :"!")

    assert_parse rb, pt
  end

  def test_i_have_no_freakin_clue
    rb = "1 ? b('') : 2\na d: 3"
    pt = s(:block,
           s(:if, s(:lit, 1), s(:call, nil, :b, s(:str, "")), s(:lit, 2)),
           s(:call, nil, :a, s(:hash, s(:lit, :d).line(2), s(:lit, 3).line(2)).line(2)).line(2))

    assert_parse rb, pt
  end

  def test_index_0
    rb = "a[] = b"
    pt = s(:attrasgn, s(:call, nil, :a), :[]=, s(:call, nil, :b))

    assert_parse rb, pt
  end

  def test_iter_args_10_1
    rb = "f { |a, b = 42, *c| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :"*c"))

    assert_parse rb, pt
  end

  def test_iter_args_10_2
    rb = "f { |a, b = 42, *c, &d| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :"*c", :"&d"))

    assert_parse rb, pt
  end

  def test_iter_args_11_1
    rb = "f { |a, b = 42, *c, d| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :"*c", :d))

    assert_parse rb, pt
  end

  def test_iter_args_11_2
    rb = "f { |a, b = 42, *c, d, &e| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :"*c", :d, :"&e"))

    assert_parse rb, pt
  end

  def test_iter_args_2__19
    rb = "f { |(a, b)| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, s(:masgn, :a, :b)))

    assert_parse rb, pt
  end

  def test_iter_args_4
    rb = "f { |a, *b, c| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :a, :"*b", :c))

    assert_parse rb, pt
  end

  def test_iter_args_5
    rb = "f { |a, &b| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :a, :"&b"))

    assert_parse rb, pt
  end

  def test_iter_args_6
    rb = "f { |a, b=42, c| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :c))

    assert_parse rb, pt
  end

  def test_iter_args_7_1
    rb = "f { |a = 42, *b| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :"*b"))

    assert_parse rb, pt
  end

  def test_iter_args_7_2
    rb = "f { |a = 42, *b, &c| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :"*b", :"&c"))

    assert_parse rb, pt
  end

  def test_iter_args_8_1
    rb = "f { |a = 42, *b, c| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :"*b", :c))

    assert_parse rb, pt
  end

  def test_iter_args_8_2
    rb = "f { |a = 42, *b, c, &d| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :"*b", :c, :"&d"))

    assert_parse rb, pt
  end

  def test_iter_args_9_1
    rb = "f { |a = 42, b| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :b))

    assert_parse rb, pt
  end

  def test_iter_args_9_2
    rb = "f { |a = 42, b, &c| }"
    pt = s(:iter, s(:call, nil, :f),
           s(:args, s(:lasgn, :a, s(:lit, 42)), :b, :"&c"))

    assert_parse rb, pt
  end

  def test_kill_me
    rb = "f { |a, (b, *c)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :b, :"*c")))

    assert_parse rb, pt
  end

  def test_kill_me2
    rb = "f { |*a, b| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :"*a", :b))

    assert_parse rb, pt
  end

  def test_kill_me3
    rb = "f { |*a, b, &c| }"
    pt = s(:iter, s(:call, nil, :f), s(:args, :"*a", :b, :"&c"))

    assert_parse rb, pt
  end

  def test_kill_me4
    rb = "a=b ? true: false"
    pt = s(:lasgn, :a, s(:if, s(:call, nil, :b), s(:true), s(:false)))

    assert_parse rb, pt
  end

  def test_kill_me5
    rb = "f ->() { g do end }"
    pt = s(:call, nil, :f,
           s(:iter,
             s(:lambda),
             s(:args),
             s(:iter, s(:call, nil, :g), 0)))

    assert_parse rb, pt
  end

  def test_kill_me_10
    # | tSTAR f_norm_arg tCOMMA f_marg_list
    rb = "f { |a, (*b, c)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :"*b", :c)))

    assert_parse rb, pt
  end

  def test_kill_me_11
    # | tSTAR
    rb = "f { |a, (*)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :*)))

    assert_parse rb, pt
  end

  def test_kill_me_12
    # | tSTAR tCOMMA f_marg_list
    rb = "f { |a, (*, b)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :*, :b)))

    assert_parse rb, pt
  end

  def test_kill_me_6
    # | f_marg_list tCOMMA tSTAR f_norm_arg tCOMMA f_marg_list
    rb = "f { |a, (b, *c, d)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :b, :"*c", :d)))

    assert_parse rb, pt
  end

  def test_kill_me_7
    # | f_marg_list tCOMMA tSTAR
    rb = "f { |a, (b, *)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :b, :*)))

    assert_parse rb, pt
  end

  def test_kill_me_8
    # | f_marg_list tCOMMA tSTAR tCOMMA f_marg_list
    rb = "f { |a, (b, *, c)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :b, :*, :c)))

    assert_parse rb, pt
  end

  def test_kill_me_9
    # | tSTAR f_norm_arg
    rb = "f { |a, (*b)| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :a, s(:masgn, :"*b")))

    assert_parse rb, pt
  end

  def test_lambda_do_vs_brace
    pt = s(:call, nil, :f, s(:iter, s(:lambda), s(:args)))

    rb = "f ->() {}"
    assert_parse rb, pt

    rb = "f ->() do end"
    assert_parse rb, pt

    pt = s(:call, nil, :f, s(:iter, s(:lambda), 0))

    rb = "f -> {}"
    assert_parse rb, pt

    rb = "f -> do end"
    assert_parse rb, pt
  end

  def test_lasgn_lasgn_command_call
    rb = "a = b = c 1"
    pt = s(:lasgn, :a, s(:lasgn, :b, s(:call, nil, :c, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_masgn_anon_splat_arg
    rb = "*, a = b"
    pt = s(:masgn,
           s(:array, s(:splat), s(:lasgn, :a)),
           s(:to_ary, s(:call, nil, :b)))

    assert_parse rb, pt
  end

  def test_masgn_arg_splat_arg
    rb = "a, *b, c = d"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:splat, s(:lasgn, :b)), s(:lasgn, :c)),
           s(:to_ary, s(:call, nil, :d)))

    assert_parse rb, pt
  end

  def test_masgn_splat_arg
    rb = "*a, b = c"
    pt = s(:masgn,
           s(:array, s(:splat, s(:lasgn, :a)), s(:lasgn, :b)),
           s(:to_ary, s(:call, nil, :c)))

    assert_parse rb, pt
  end

  def test_masgn_splat_arg_arg
    rb = "*a, b, c = d"
    pt = s(:masgn,
           s(:array, s(:splat, s(:lasgn, :a)), s(:lasgn, :b), s(:lasgn, :c)),
           s(:to_ary, s(:call, nil, :d)))

    assert_parse rb, pt
  end

  def test_masgn_var_star_var
    rb = "a, *, b = c" # TODO: blog
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:splat), s(:lasgn, :b)),
           s(:to_ary, s(:call, nil, :c)))

    assert_parse rb, pt
  end

  def test_method_call_assoc_trailing_comma
    rb = "a.f(1=>2,)"
    pt = s(:call, s(:call, nil, :a), :f, s(:hash, s(:lit, 1), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_method_call_trailing_comma
    rb = "a.f(1,)"
    pt = s(:call, s(:call, nil, :a), :f, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_mlhs_back_anonsplat
    rb = "a, b, c, * = f"
    pt = s(:masgn,
           s(:array,
             s(:lasgn, :a), s(:lasgn, :b), s(:lasgn, :c),
             s(:splat)),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_mlhs_back_splat
    rb = "a, b, c, *s = f"
    pt = s(:masgn,
           s(:array,
             s(:lasgn, :a), s(:lasgn, :b), s(:lasgn, :c),
             s(:splat, s(:lasgn, :s))),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_mlhs_front_anonsplat
    rb = "*, x, y, z = f"
    pt = s(:masgn,
           s(:array,
             s(:splat),
             s(:lasgn, :x), s(:lasgn, :y), s(:lasgn, :z)),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_mlhs_front_splat
    rb = "*s, x, y, z = f"
    pt = s(:masgn,
           s(:array,
             s(:splat, s(:lasgn, :s)),
             s(:lasgn, :x), s(:lasgn, :y), s(:lasgn, :z)),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_mlhs_keyword
    rb = "a.!=(true, true)"
    pt = s(:call, s(:call, nil, :a), :"!=", s(:true), s(:true))

    assert_parse rb, pt
  end

  def test_mlhs_mid_anonsplat
    rb = "a, b, c, *, x, y, z = f"
    pt = s(:masgn,
           s(:array,
             s(:lasgn, :a), s(:lasgn, :b), s(:lasgn, :c),
             s(:splat),
             s(:lasgn, :x), s(:lasgn, :y), s(:lasgn, :z)),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_mlhs_mid_splat
    rb = "a, b, c, *s, x, y, z = f"
    pt = s(:masgn,
           s(:array,
             s(:lasgn, :a), s(:lasgn, :b), s(:lasgn, :c),
             s(:splat, s(:lasgn, :s)),
             s(:lasgn, :x), s(:lasgn, :y), s(:lasgn, :z)),
           s(:to_ary, s(:call, nil, :f)))

    assert_parse rb, pt
  end

  def test_call_leading_dots
    rb = "a\n.b\n.c"
    pt = s(:call, s(:call, s(:call, nil, :a), :b), :c)

    assert_parse rb, pt
  end

  def test_call_leading_dots_comment
    rb = "a\n.b\n#.c\n.d"
    pt = s(:call,
           s(:call,
             s(:call, nil, :a),
             :b),
           :d) # TODO: fix linenos: 1, 2, 4

    assert_parse rb, pt
  end

  def test_call_trailing_dots
    rb = "a.\nb.\nc"
    pt = s(:call, s(:call, s(:call, nil, :a), :b), :c)

    assert_parse rb, pt
  end

  def test_motherfuckin_leading_dots
    rb = "a\n.b"
    pt = s(:call, s(:call, nil, :a), :b)

    assert_parse rb, pt
  end

  def test_motherfuckin_leading_dots2
    rb = "1\n..3"
    pt = s(:block, s(:lit, 1),
           s(:dot2, nil, s(:lit, 3).line(2)).line(2))

    if processor.class.version >= 27
      assert_parse rb, pt
    else
      assert_parse_error rb, '(string):2 :: parse error on value ".." (tDOT2)'
    end
  end

  def test_multiline_hash_declaration
    pt = s(:call, nil, :f, s(:hash, s(:lit, :state), s(:hash)))

    assert_parse "f(state: {})",     pt
    assert_parse "f(state: {\n})",   pt

    pt = s(:call, nil, :f, s(:hash, s(:lit, :state), s(:hash).line(2)))
    assert_parse "f(state:\n {\n})", pt
  end

  def test_parse_def_special_name
    rb = "def next; end"
    pt = s(:defn, :next, s(:args), s(:nil))

    assert_parse rb, pt
  end

  def test_parse_def_xxx1
    rb = "def f(a, *b, c = nil) end"

    assert_parse_error rb, '(string):1 :: parse error on value "=" (tEQL)'
  end

  def test_parse_def_xxx2
    rb = "def f(a = nil, *b, c = nil) end"

    assert_parse_error rb, '(string):1 :: parse error on value "=" (tEQL)'
  end

  def test_parse_if_not_canonical
    rb = "if not var.nil? then 'foo' else 'bar'\nend"
    pt = s(:if,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo"),
           s(:str, "bar"))

    assert_parse rb, pt
  end

  def test_parse_if_not_noncanonical
    rb = "if not var.nil? then 'foo' else 'bar'\nend"
    pt = s(:if,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo"),
           s(:str, "bar"))

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_parse_opt_call_args_assocs_comma
    rb = "1[2=>3,]"
    pt = s(:call, s(:lit, 1), :[], s(:hash, s(:lit, 2), s(:lit, 3)))

    assert_parse rb, pt
  end

  def test_parse_opt_call_args_lit_comma
    rb = "1[2,]"
    pt = s(:call, s(:lit, 1), :[], s(:lit, 2))

    assert_parse rb, pt
  end

  def test_parse_until_not_canonical
    rb = "until not var.nil?\n  'foo'\nend"
    pt = s(:until,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo").line(2), true)

    assert_parse rb, pt
  end

  def test_parse_until_not_noncanonical
    rb = "until not var.nil?\n  'foo'\nend"
    pt = s(:until,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo").line(2), true)

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_parse_while_not_canonical
    rb = "while not var.nil?\n  'foo'\nend"
    pt = s(:while,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo").line(2), true)

    assert_parse rb, pt
  end

  def test_parse_while_not_noncanonical
    rb = "while not var.nil?\n  'foo'\nend"
    pt = s(:while,
           s(:call, s(:call, s(:call, nil, :var), :nil?), :"!"),
           s(:str, "foo").line(2), true)

    processor.canonicalize_conditions = false

    assert_parse rb, pt
  end

  def test_pipe_semicolon
    rb = "a.b do | ; c | end"
    pt = s(:iter, s(:call, s(:call, nil, :a), :b), s(:args, s(:shadow, :c)))

    assert_parse rb, pt
  end

  def test_return_call_assocs
    rb = "return y(z:1)"
    pt = s(:return, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "return y z:1"
    pt = s(:return, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "return y(z=>1)"
    pt = s(:return, s(:call, nil, :y, s(:hash, s(:call, nil, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "return y :z=>1"
    pt = s(:return, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "return 1, :z => 1"
    pt = s(:return,
           s(:array,
             s(:lit, 1),
             s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "return 1, :z => 1, :w => 2"
    pt = s(:return,
           s(:array,
             s(:lit, 1),
             s(:hash, s(:lit, :z), s(:lit, 1), s(:lit, :w), s(:lit, 2))))

    assert_parse rb, pt
  end

  def test_stabby_arg_no_paren
    rb = "->a{}"
    pt = s(:iter, s(:lambda), s(:args, :a))

    assert_parse rb, pt
  end

  def test_stabby_arg_opt_splat_arg_block_omfg
    rb = "->(b, c=1, *d, e, &f){}"
    pt = s(:iter,
           s(:lambda),
           s(:args, :b, s(:lasgn, :c, s(:lit, 1)), :"*d", :e, :"&f"))

    assert_parse rb, pt
  end

  def test_stabby_proc_scope
    rb = "->(a; b) {}"
    pt = s(:iter, s(:lambda), s(:args, :a, s(:shadow, :b)))

    assert_parse rb, pt
  end

  def test_symbol_empty
    rb = ":''"
    pt = s(:lit, "".to_sym)

    assert_parse rb, pt
  end

  def test_thingy
    pt = s(:call, s(:call, nil, :f), :call, s(:lit, 42))

    rb = "f.(42)"
    assert_parse rb, pt

    rb = "f::(42)"
    assert_parse rb, pt
  end

  def test_unary_plus_on_literal
    rb = "+:a"
    pt = s(:call, s(:lit, :a), :+@)

    assert_parse rb, pt
  end

  def test_wtf
    # lambda -> f_larglist lambda_body
    # f_larglist -> f_args opt_bv_decl
    # opt_bv_decl
    # bv_decls
    # bvar

    rb = "->(a, b=nil) { p [a, b] }"
    pt = s(:iter,
           s(:lambda),
           s(:args, :a, s(:lasgn, :b, s(:nil))),
           s(:call, nil, :p, s(:array, s(:lvar, :a), s(:lvar, :b))))

    assert_parse rb, pt

    # rb = "->(a; b) { p [a, b] }"
    #
    # assert_parse rb, pt
  end

  def test_yield_call_assocs
    rb = "yield y(z:1)"
    pt = s(:yield, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "yield y z:1"
    pt = s(:yield, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "yield y(z=>1)"
    pt = s(:yield, s(:call, nil, :y, s(:hash, s(:call, nil, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "yield y :z=>1"
    pt = s(:yield, s(:call, nil, :y, s(:hash, s(:lit, :z), s(:lit, 1))))

    assert_parse rb, pt

    rb = "yield 1, :z => 1"
    pt = s(:yield,
           s(:lit, 1),
           s(:hash, s(:lit, :z), s(:lit, 1)))

    assert_parse rb, pt

    rb = "yield 1, :z => 1, :w => 2"
    pt = s(:yield,
           s(:lit, 1),
           s(:hash, s(:lit, :z), s(:lit, 1), s(:lit, :w), s(:lit, 2)))

    assert_parse rb, pt
  end

  def test_zomg_sometimes_i_hate_this_project
    rb = <<-RUBY
      {
        a: lambda { b ? c() : d },
        e: nil,
      }
    RUBY

    pt = s(:hash,
           s(:lit, :a).line(2),
           s(:iter,
             s(:call, nil, :lambda).line(2),
             0,
             s(:if, s(:call, nil, :b).line(2),
               s(:call, nil, :c).line(2),
               s(:call, nil, :d).line(2)).line(2)).line(2),

           s(:lit, :e).line(3),
           s(:nil).line(3))

    assert_parse rb, pt
  end
end

module TestRubyParserShared20Plus
  include TestRubyParserShared19Plus

  def test_read_escape_unicode_h4
    rb = '?\u00a0'
    pt = s(:str, ?\u00a0)

    assert_parse rb, pt
  end

  def test_read_escape_unicode_curlies
    rb = '?\u{00a0}'
    pt = s(:str, ?\u00a0)

    assert_parse rb, pt
  end

  def test_regexp_unicode_curlies
    rb = '/\u{df}/'
    pt = s(:lit, /\u{df}/)

    assert_parse rb, pt

    rb = '/\u{c0de babe}/'
    pt = s(:lit, /\u{c0de babe}/)

    assert_parse rb, pt
  end

  def test_qw_escape
    rb = "%q(\1\\\')"
    pt = s(:str, "\001\\'")

    assert_parse rb, pt
  end

  def test_pct_nl
    rb = "x = %\n\n"
    pt = s(:lasgn, :x, s(:str, ""))

    assert_parse rb, pt
  end

  def test_regexp_esc_C_slash
    rb = "/\\cC\\d/"
    pt = s(:lit, Regexp.new('\cC\d')) # https://bugs.ruby-lang.org/issues/18449

    assert_parse rb, pt
  end

  def test_heredoc_wtf_I_hate_you
    rb = "p <<-END+'b\n  a\n  END\n  c'+'d'"
    pt = s(:call, nil, :p,
           s(:call,
             s(:call, s(:str, "  a\n"), :+,
               s(:str, "b\n  c")),
             :+, s(:str, "d").line(4)))

    assert_parse rb, pt
  end

  def test_heredoc_nested
    rb = "[<<A,\n\#{<<B}\nb\nB\na\nA\n0]"
    pt = s(:array, s(:str, "b\n\na\n"),
           s(:lit, 0).line(7))

    assert_parse rb, pt
  end

  def test_pct_w_heredoc_interp_nested
    rb = "%W( 1 \#{<<A} 3\n2\nA\n      4 5 )"
    pt = s(:array,
           s(:str, "1"),
           s(:str, "2\n"),
           s(:str, "3"),
           s(:str, "4").line(4),
           s(:str, "5").line(4))

    assert_parse rb, pt
  end

  def test_regexp_esc_u
    rb = "/[\\u0021-\\u0027]/"
    pt = s(:lit, /[\u0021-\u0027]/)

    assert_parse rb, pt
  end

  def test_qw_escape_term
    rb = "%q|blah blah \\| blah blah|"
    pt = s(:str, "blah blah | blah blah")

    assert_parse rb, pt
  end

  def test_args_kw_block
    rb = "def f(a: 1, &b); end"
    pt = s(:defn, :f, s(:args, s(:kwarg, :a, s(:lit, 1)), :"&b"), s(:nil))

    assert_parse rb, pt
  end

  def test_heredoc_backslash_nl
    rb = %Q("  why would someone do this? \\\n  blah\n")
    pt = s(:str, "  why would someone do this?   blah\n")

    assert_parse rb, pt

    rb = "<<-DESC\n  why would someone do this? \\\n  blah\nDESC"

    assert_parse rb, pt
  end

  def test_heredoc_comma_arg
    rb = "[\"  some text\n\",]"
    pt = s(:array, s(:str, "  some text\n"))

    assert_parse rb, pt

    rb = "[<<-FILE,\n  some text\nFILE\n]"

    assert_parse rb, pt
  end

  def test_heredoc_trailing_slash_continued_call
    rb = "<<END\\\nblah\nEND\n.strip"
    pt = s(:call, s(:str, "blah\n"), :strip)

    assert_parse rb, pt
  end

  def test_pct_q_backslash_nl
    rb = "%q{ \\\n}"
    pt = s(:str, " \\\n")

    assert_parse rb, pt
  end

  def test_pct_Q_backslash_nl
    rb = "%Q{ \\\n}"
    pt = s(:str, " ")

    assert_parse rb, pt
  end

  def test_block_arg_kwsplat
    rb = "a { |**b| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, :"**b"))

    assert_parse rb, pt
  end

  def test_block_call_dot_op2_brace_block
    rb = "a.b c() do d end.e do |f| g end"
    pt = s(:iter,
           s(:call,
             s(:iter,
               s(:call, s(:call, nil, :a), :b, s(:call, nil, :c)),
               0,
               s(:call, nil, :d)),
             :e),
           s(:args, :f),
           s(:call, nil, :g))

    assert_parse rb, pt
  end

  def test_call_array_block_call
    rb = "a [ nil, b do end ]"
    pt = s(:call, nil, :a,
           s(:array,
             s(:nil),
             s(:iter, s(:call, nil, :b), 0)))

    assert_parse rb, pt
  end

  def test_block_call_paren_call_block_call
    rb = "a (b)\nc.d do end"
    pt = s(:block,
           s(:call, nil, :a, s(:call, nil, :b)),
           s(:iter, s(:call, s(:call, nil, :c).line(2), :d).line(2), 0).line(2))


    assert_parse rb, pt
  end

  def test_block_call_defn_call_block_call
    rb = "a def b(c)\n d\n end\n e.f do end"
    pt = s(:block,
           s(:call, nil, :a,
             s(:defn, :b, s(:args, :c),
               s(:call, nil, :d).line(2))),
           s(:iter, s(:call, s(:call, nil, :e).line(4), :f).line(4), 0).line(4))

    assert_parse rb, pt
  end

  def test_call_array_lambda_block_call
    rb = "a [->() {}] do\nend"
    pt = s(:iter,
           s(:call, nil, :a,
             s(:array, s(:iter, s(:lambda), s(:args)))),
           0)

    assert_parse rb, pt
  end

  def test_call_begin_call_block_call
    rb = "a begin\nb.c do end\nend"
    pt = s(:call, nil, :a,
           s(:iter,
             s(:call, s(:call, nil, :b).line(2), :c).line(2),
             0).line(2))

    assert_parse rb, pt
  end

  def test_messy_op_asgn_lineno
    rb = "a (B::C *= d e)"
    pt = s(:call, nil, :a,
           s(:op_asgn, s(:const, :B),
             s(:call, nil, :d, s(:call, nil, :e)),
             :C,
             :*))

    assert_parse rb, pt
  end

  def test_str_lit_concat_bad_encodings
    rb = '"\xE3\xD3\x8B\xE3\x83\xBC\x83\xE3\x83\xE3\x82\xB3\xA3\x82\x99" \
        "\xE3\x83\xB3\xE3\x83\x8F\xE3\x82\x9A\xC3\xBD;foo@bar.com"'.b
    pt = s(:str, "\xE3\xD3\x8B\xE3\x83\xBC\x83\xE3\x83\xE3\x82\xB3\xA3\x82\x99\xE3\x83\xB3\xE3\x83\x8F\xE3\x82\x9A\xC3\xBD;foo@bar.com".b)

    assert_parse rb, pt

    sexp = processor.parse rb
    assert_equal Encoding::ASCII_8BIT, sexp.last.encoding
  end

  def test_block_call_dot_op2_cmd_args_do_block
    rb = "a.b c() do d end.e f do |g| h end"
    pt = s(:iter,
           s(:call,
             s(:iter,
               s(:call, s(:call, nil, :a), :b, s(:call, nil, :c)),
               0,
               s(:call, nil, :d)),
             :e,
             s(:call, nil, :f)),
           s(:args, :g),
           s(:call, nil, :h))

    assert_parse rb, pt
  end

  def test_block_kwarg_lvar
    rb = "bl { |kw: :val| kw }"
    pt = s(:iter, s(:call, nil, :bl), s(:args, s(:kwarg, :kw, s(:lit, :val))),
           s(:lvar, :kw))

    assert_parse rb, pt
  end

  def test_block_kwarg_lvar_multiple
    rb = "bl { |kw: :val, kw2: :val2 | kw }"
    pt = s(:iter, s(:call, nil, :bl),
           s(:args,
             s(:kwarg, :kw, s(:lit, :val)),
             s(:kwarg, :kw2, s(:lit, :val2))),
           s(:lvar, :kw))

    assert_parse rb, pt
  end

  def test_bug_249
    rb = "mount (Class.new do\ndef initialize\nend\n end).new, :at => 'endpoint'"
    pt = s(:call, nil, :mount,
           s(:call,
             s(:iter,
               s(:call, s(:const, :Class), :new),
               0,
               s(:defn, :initialize, s(:args).line(2), s(:nil).line(2)).line(2)),
             :new),
           s(:hash, s(:lit, :at).line(4), s(:str, "endpoint").line(4)).line(4))

    assert_parse rb, pt
  end

  def test_call_arg_assoc_kwsplat
    rb = "f(1, kw: 2, **3)"
    pt = s(:call, nil, :f,
           s(:lit, 1),
           s(:hash, s(:lit, :kw), s(:lit, 2), s(:kwsplat, s(:lit, 3))))

    assert_parse rb, pt
  end

  def test_call_arg_kwsplat
    rb = "a(b, **1)"
    pt = s(:call, nil, :a, s(:call, nil, :b), s(:hash, s(:kwsplat, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_call_kwsplat
    rb = "a(**1)"
    pt = s(:call, nil, :a, s(:hash, s(:kwsplat, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_defn_kwarg_env
    rb = "def test(**testing) test_splat(**testing) end"
    pt = s(:defn, :test, s(:args, :"**testing"),
           s(:call, nil, :test_splat, s(:hash, s(:kwsplat, s(:lvar, :testing)))))

    assert_parse rb, pt
  end

  def test_defn_kwarg_kwarg
    rb = "def f(a, b: 1, c: 2) end"
    pt = s(:defn, :f, s(:args, :a,
                        s(:kwarg, :b, s(:lit, 1)),
                        s(:kwarg, :c, s(:lit, 2))),
           s(:nil))

    assert_parse rb, pt
  end

  def test_defn_kwarg_kwsplat
    rb = "def a(b: 1, **c) end"
    pt = s(:defn, :a, s(:args, s(:kwarg, :b, s(:lit, 1)), :"**c"), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_kwarg_kwsplat_anon
    rb = "def a(b: 1, **) end"
    pt = s(:defn, :a, s(:args, s(:kwarg, :b, s(:lit, 1)), :"**"), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_kwarg_lvar
    rb = "def fun(kw: :val); kw; end"
    pt = s(:defn, :fun, s(:args, s(:kwarg, :kw, s(:lit, :val))), s(:lvar, :kw))

    assert_parse rb, pt
  end

  def test_defn_kwarg_no_parens
    rb = "def f a: 1\nend"
    pt = s(:defn, :f, s(:args, s(:kwarg, :a, s(:lit, 1))), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_kwarg_val
    rb = "def f(a, b:1) end"
    pt = s(:defn, :f, s(:args, :a, s(:kwarg, :b, s(:lit, 1))), s(:nil))

    assert_parse rb, pt
  end

  def test_defn_powarg
    rb = "def f(**opts) end"
    pt = s(:defn, :f, s(:args, :"**opts"), s(:nil))

    assert_parse rb, pt
  end

  def test_defs_kwarg
    rb = "def self.a b: 1\nend"
    pt = s(:defs, s(:self), :a, s(:args, s(:kwarg, :b, s(:lit, 1))), s(:nil))

    assert_parse rb, pt
  end

  def test_dstr_lex_state
    rb = '"#{p:a}"'
    pt = s(:dstr, "", s(:evstr, s(:call, nil, :p, s(:lit, :a))))

    assert_parse rb, pt
  end

  def test_interpolated_symbol_array_line_breaks
    rb = "%I(\na\nb\n)\n1"
    pt = s(:block,
           s(:array,
             s(:lit, :a).line(2),
             s(:lit, :b).line(3)),
           s(:lit, 1).line(5))
    assert_parse rb, pt
  end

  def test_iter_array_curly
    rb = "f :a, [:b] { |c, d| }" # yes, this is bad code... that's their problem
    pt = s(:iter,
           s(:call, nil, :f, s(:lit, :a), s(:array, s(:lit, :b))),
           s(:args, :c, :d))

    if processor.class.version >= 25 then
      msg = /parse error on value "\{" \(tLCURLY\)/
      assert_syntax_error rb, msg, Racc::ParseError
    else
      assert_parse rb, pt
    end
  end

  def test_iter_kwarg
    rb = "a { |b: 1| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:kwarg, :b, s(:lit, 1))))

    assert_parse rb, pt
  end

  def test_iter_kwarg_kwsplat
    rb = "a { |b: 1, **c| }"
    pt = s(:iter, s(:call, nil, :a), s(:args, s(:kwarg, :b, s(:lit, 1)), :"**c"))

    assert_parse rb, pt
  end

  def test_non_interpolated_symbol_array_line_breaks
    rb = "%i(\na\nb\n)\n1"
    pt = s(:block,
           s(:array,
             s(:lit, :a).line(2),
             s(:lit, :b).line(3)),
           s(:lit, 1).line(5))
    assert_parse rb, pt
  end

  def test_qsymbols
    rb = "%I(a b c)"
    pt = s(:array, s(:lit, :a), s(:lit, :b), s(:lit, :c))

    assert_parse rb, pt
  end

  def test_qsymbols_empty
    rb = "%I()"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_qsymbols_empty_space
    rb = "%I( )"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_qsymbols_interp
    rb = '%I(a b#{1+1} c)'
    pt = s(:array,
           s(:lit, :a),
           s(:dsym, "b", s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1)))),
           s(:lit, :c))

    assert_parse rb, pt
  end

  def test_stabby_block_iter_call
    rb = "x -> () do\na.b do\nend\nend"
    pt = s(:call, nil, :x,
           s(:iter,
             s(:lambda),
             s(:args),
             s(:iter, s(:call, s(:call, nil, :a).line(2), :b).line(2), 0).line(2)))

    assert_parse rb, pt
  end

  def test_stabby_block_iter_call_no_target_with_arg
    rb = "x -> () do\na(1) do\nend\nend"
    pt = s(:call, nil, :x,
           s(:iter,
             s(:lambda),
             s(:args),
             s(:iter,
               s(:call, nil, :a,
                 s(:lit, 1).line(2)).line(2), 0).line(2)))

    assert_parse rb, pt
  end

  def test_symbols
    rb = "%i(a b c)"
    pt = s(:array, s(:lit, :a), s(:lit, :b), s(:lit, :c))

    assert_parse rb, pt
  end

  def test_symbols_empty
    rb = "%i()"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_symbols_empty_space
    rb = "%i( )"
    pt = s(:array)

    assert_parse rb, pt
  end

  def test_symbols_interp
    rb = '%i(a b#{1+1} c)'
    pt = s(:array, s(:lit, :a), s(:lit, :'b#{1+1}'), s(:lit, :c))

    assert_parse rb, pt
  end
end

module TestRubyParserShared21Plus
  include TestRubyParserShared20Plus

  def test_array_lits_trailing_calls
    rb = "[].b"
    pt = s(:call, s(:array), :b)

    assert_parse rb, pt

    rb = "%w[].b"

    assert_parse rb, pt
  end

  def test_block_kw
    rb = "blah { |k:42| }"
    pt = s(:iter, s(:call, nil, :blah), s(:args, s(:kwarg, :k, s(:lit, 42))))

    assert_parse rb, pt

    rb = "blah { |k:42| }"
    assert_parse rb, pt
  end

  def test_block_kw__required
    rb = "blah do |k:| end"
    pt = s(:iter, s(:call, nil, :blah), s(:args, s(:kwarg, :k)))

    assert_parse rb, pt

    rb = "blah do |k:| end"
    assert_parse rb, pt
  end

  def test_bug162__21plus
    rb = %q(<<E\nfoo\nE\rO)
    emsg = "can't match /E(?=\\r?\\n|\\z)/ anywhere in . near line 1: \"\""

    assert_syntax_error rb, emsg
  end

  def test_defn_unary_not
    rb = "def !@; true; end" # I seriously HATE this
    pt = s(:defn, :"!@", s(:args), s(:true))

    assert_parse rb, pt
  end

  def test_f_kw
    rb = "def x k:42; end"
    pt = s(:defn, :x, s(:args, s(:kwarg, :k, s(:lit, 42))), s(:nil))

    assert_parse rb, pt
  end

  def test_f_kw__required
    rb = "def x k:; end"
    pt = s(:defn, :x, s(:args, s(:kwarg, :k)), s(:nil))

    assert_parse rb, pt
  end

  def test_parse_line_heredoc_hardnewline
    rb = <<-'CODE'.gsub(/^      /, "")
      <<-EOFOO
      \n\n\n\n\n\n\n\n\n
      EOFOO

      class Foo
      end
    CODE

    pt = s(:block,
           s(:str, "\n\n\n\n\n\n\n\n\n\n"),
           s(:class, :Foo, nil).line(5))

    assert_parse rb, pt
  end

  def test_stabby_block_kw
    rb = "-> (k:42) { }"
    pt = s(:iter, s(:lambda), s(:args, s(:kwarg, :k, s(:lit, 42))))

    assert_parse rb, pt
  end

  def test_stabby_block_kw__required
    rb = "-> (k:) { }"
    pt = s(:iter, s(:lambda), s(:args, s(:kwarg, :k)))

    assert_parse rb, pt
  end
end

module TestRubyParserShared22Plus
  include TestRubyParserShared21Plus

  def test_bug_hash_interp_array
    rp = '{ "#{}": [] }'
    pt = s(:hash, s(:dsym, "", s(:evstr)), s(:array))

    assert_parse rp, pt
  end

  def test_call_args_assoc_quoted
    pt = s(:call, nil, :x, s(:hash, s(:lit, :k), s(:lit, 42)))

    rb = "x 'k':42"
    assert_parse rb, pt

    rb = 'x "k":42'
    assert_parse rb, pt

    rb = 'x "#{k}":42'
    pt = s(:call, nil, :x, s(:hash, s(:dsym, "", s(:evstr, s(:call, nil, :k))), s(:lit, 42)))

    assert_parse rb, pt
  end

  def test_quoted_symbol_hash_arg
    rb = "puts 'a': {}"
    pt = s(:call, nil, :puts, s(:hash, s(:lit, :a), s(:hash)))

    assert_parse rb, pt
  end

  def test_quoted_symbol_keys
    rb = "{ 'a': :b }"
    pt = s(:hash, s(:lit, :a), s(:lit, :b))

    assert_parse rb, pt
  end
end

module TestRubyParserShared23Plus
  include TestRubyParserShared22Plus

  def test_bug_215
    rb = "undef %s(foo)"
    pt = s(:undef, s(:lit, :foo))

    assert_parse rb, pt
  end

  def test_const_2_op_asgn_or2
    rb = "::X::Y ||= 1"
    pt = s(:op_asgn_or, s(:colon2, s(:colon3, :X), :Y), s(:lit, 1))

    assert_parse rb, pt
  end

  def test_const_3_op_asgn_or
    rb = "::X ||= 1"
    pt = s(:op_asgn_or, s(:colon3, :X), s(:lit, 1))

    assert_parse rb, pt
  end

  def test_const_op_asgn_and1
    rb = "::X &= 1"
    pt = s(:op_asgn, s(:colon3, :X), :"&", s(:lit, 1))

    assert_parse rb, pt
  end

  def test_const_op_asgn_and2
    rb = "::X &&= 1"
    pt = s(:op_asgn_and, s(:colon3, :X), s(:lit, 1))

    assert_parse rb, pt
  end

  def test_const_op_asgn_or
    rb = "X::Y ||= 1"
    pt = s(:op_asgn_or, s(:colon2, s(:const, :X), :Y), s(:lit, 1))

    assert_parse rb, pt
  end

  def test_float_with_if_modifier
    rb = "1.0if true"
    pt = s(:if, s(:true), s(:lit, 1.0), nil)

    assert_parse rb, pt
  end

  def test_heredoc__backslash_dos_format
    rb = "str = <<-XXX\r\nbefore\\\r\nafter\r\nXXX\r\n"
    pt = s(:lasgn, :str, s(:str, "before\nafter\n"))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly
    rb = "a = <<~\"EOF\"\n  x\n  y\n  z\n  EOF\n\n"
    pt = s(:lasgn, :a, s(:str, "x\ny\nz\n"))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_interp
    rb = "a = <<~EOF\n      w\n  x#\{42} y\n    z\n  EOF"
    pt = s(:lasgn, :a, s(:dstr, "    w\nx",
                         s(:evstr, s(:lit, 42).line(3)).line(3),
                         s(:str, " y\n  z\n").line(3)))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_tabs
    rb = "a = <<~\"EOF\"\n        blah blah\n\t blah blah\n  EOF\n\n"
    pt = s(:lasgn, :a, s(:str, "blah blah\n blah blah\n"))

    assert_parse rb, pt
  end

  # mri handles tabs in a pretty specific way:
  # https://github.com/ruby/ruby/blob/trunk/parse.y#L5925
  def test_heredoc_squiggly_tabs_extra
    rb = "a = <<~\"EOF\"\n  blah blah\n \tblah blah\n  EOF\n\n"
    pt = s(:lasgn, :a, s(:str, "blah blah\n\tblah blah\n"))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_no_indent
    rb = "<<~A\na\nA"
    pt = s(:str, "a\n")

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_blank_lines
    rb = "a = <<~EOF\n  x\n\n  z\nEOF\n\n"
    pt = s(:lasgn, :a, s(:str, "x\n\nz\n"))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_visually_blank_lines
    rb = "a = <<~EOF\n  x\n \n  z\nEOF\n\n"
    pt = s(:lasgn, :a, s(:str, "x\n\nz\n"))

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_empty
    rb = "<<~A\nA"
    pt = s(:str, "")

    assert_parse rb, pt
  end

  def test_heredoc_squiggly_blank_line_plus_interpolation
    rb = "a = foo(<<~EOF.chop)\n\n    #\{bar}baz\n  EOF"
    pt = s(:lasgn, :a,
           s(:call,
             nil,
             :foo,
             s(:call,
               s(:dstr, "\n",
                 s(:evstr, s(:call, nil, :bar).line(3)).line(3),
                 s(:str, "baz\n").line(3)).line(1),
               :chop).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_integer_with_if_modifier
    rb = "1_234if true"
    pt = s(:if, s(:true), s(:lit, 1234), nil)

    assert_parse rb, pt
  end

  def test_required_kwarg_no_value
    rb = "def x a:, b:\nend"
    pt = s(:defn, :x,
           s(:args,
             s(:kwarg, :a),
             s(:kwarg, :b)),
           s(:nil))

    assert_parse rb, pt
  end

  def test_ruby21_numbers
    rb = "[1i, 2r, 3ri]"
    pt = s(:array, s(:lit, Complex(0, 1)), s(:lit, Rational(2)), s(:lit, Complex(0, Rational(3))))

    assert_parse rb, pt
  end

  def test_safe_attrasgn
    rb = "a&.b = 1"
    pt = s(:safe_attrasgn, s(:call, nil, :a), :"b=", s(:lit, 1))

    assert_parse rb, pt
  end

  def test_safe_attrasgn_constant
    rb = "a&.B = 1"
    pt = s(:safe_attrasgn, s(:call, nil, :a), :"B=", s(:lit, 1))

    assert_parse rb, pt
  end

  def test_safe_call
    rb = "a&.b"
    pt = s(:safe_call, s(:call, nil, :a), :b)

    assert_parse rb, pt
  end

  def test_safe_call_after_newline
    rb = "a\n&.b"
    pt = s(:safe_call, s(:call, nil, :a), :b)

    assert_parse rb, pt
  end

  def test_safe_call_dot_parens
    rb = "a&.()"
    pt = s(:safe_call, s(:call, nil, :a), :call)

    assert_parse rb, pt
  end

  def test_safe_call_newline
    rb = "a&.b\n"
    pt = s(:safe_call, s(:call, nil, :a), :b)

    assert_parse rb, pt
  end

  def test_safe_call_operator
    rb = "a&.> 1"
    pt = s(:safe_call, s(:call, nil, :a), :>, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_safe_call_rhs_newline
    rb = "c = a&.b\n"
    pt = s(:lasgn, :c, s(:safe_call, s(:call, nil, :a), :b))

    assert_parse rb, pt
  end

  def test_safe_calls
    rb = "a&.b&.c(1)"
    pt = s(:safe_call, s(:safe_call, s(:call, nil, :a), :b), :c, s(:lit, 1))

    assert_parse rb, pt
  end

  def test_safe_op_asgn
    rb = "a&.b += x 1"
    pt = s(:safe_op_asgn, s(:call, nil, :a), s(:call, nil, :x, s(:lit, 1)), :b, :+)

    assert_parse rb, pt
  end

  def test_safe_op_asgn2
    rb = "a&.b ||=\nx;"
    pt = s(:safe_op_asgn2,
           s(:call, nil, :a), :b=, :"||", s(:call, nil, :x).line(2))

    assert_parse rb, pt
  end

  def test_slashy_newlines_within_string
    rb = %(puts "hello\\
 my\\
 dear\\
 friend"

a + b
    )

    pt = s(:block,
           s(:call, nil, :puts, s(:str, "hello my dear friend")),
           s(:call, s(:call, nil, :a).line(6),
             :+,
             s(:call, nil, :b).line(6)).line(6)
          )

    assert_parse rb, pt
  end
end

module TestRubyParserShared24Plus
  include TestRubyParserShared23Plus

  def test_lasgn_call_nobracket_rescue_arg
    rb = "a = b 1 rescue 2"
    pt = s(:lasgn, :a,
           s(:rescue,
             s(:call, nil, :b, s(:lit, 1)),
             s(:resbody, s(:array), s(:lit, 2))))

    assert_parse rb, pt
  end
end

module TestRubyParserShared25Plus
  include TestRubyParserShared24Plus

  # ...version specific tests to go here...
end

module TestRubyParserShared26Plus
  include TestRubyParserShared25Plus

  def test_dot2_nil__26
    rb = "a.."
    pt = s(:dot2, s(:call, nil, :a), nil)

    assert_parse rb, pt
  end

  def test_begin_else_return_value # overrides above, warns < 2.6
    rb = "begin; else 2; end"

    assert_syntax_error rb, "else without rescue is useless"
  end

  def test_bug_begin_else # overrides above, warns < 2.6
    rb = "begin 1; else; 2 end"

    assert_syntax_error rb, "else without rescue is useless"
  end

  def test_dot3_nil__26
    rb = "a..."
    pt = s(:dot3, s(:call, nil, :a), nil)

    assert_parse rb, pt
  end

  def test_symbol_list
    rb = '%I[#{a} #{b}]'
    pt = s(:array,
           s(:dsym, "", s(:evstr, s(:call, nil, :a))),
           s(:dsym, "", s(:evstr, s(:call, nil, :b)))).line 1

    assert_parse rb, pt
  end
end

module TestPatternMatching
  def rip rb
    require "ripper"
    puts
    pp Sexp.from_array Ripper.sexp rb
  end

  def assert_case_in lit, exp_pt
    rb = "case :a\nin #{lit}\nend"

    if ENV["VERBOSE_TEST"] then
      puts
      puts rb
    end

    pt = s(:case, s(:lit, :a),
           s(:in, exp_pt, nil).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_09
    assert_case_in(":b, [:c]",
                   s(:array_pat, nil,
                     s(:lit, :b).line(2),
                     s(:array_pat, nil, s(:lit, :c).line(2)).line(2)).line(2))
  end

  def test_case_in_10
    assert_case_in "nil, nil, nil", s(:array_pat,
                                      nil,
                                      s(:nil).line(2),
                                      s(:nil).line(2),
                                      s(:nil).line(2)).line(2)
  end

  def test_case_in_21
    assert_case_in "Symbol()", s(:array_pat, s(:const, :Symbol).line(2)).line(2)
  end

  def test_case_in_26
    assert_case_in "(42)", s(:lit, 42).line(2)
  end

  def test_case_in_27
    assert_case_in("[A, *, B]",
                   s(:array_pat, nil,
                     s(:const, :A).line(2),
                     :*,
                     s(:const, :B).line(2)).line(2))
  end

  def test_case_in_28_2
    assert_case_in '{ "b": }', s(:hash_pat, nil, s(:lit, :b).line(2), nil).line(2)
  end

  def test_case_in_28
    assert_case_in "[]", s(:array_pat).line(2)
  end

  def test_case_in_29
    assert_case_in "**nil", s(:hash_pat, nil, s(:kwrest, :"**nil").line(2)).line(2)
  end

  def test_case_in_30
    assert_case_in "{}", s(:hash_pat, nil).line(2)
  end

  def test_case_in_31?
    rb = "case :a\nin [:b, *c]\n  :d\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat, nil, s(:lit, :b).line(2), :"*c").line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_32
    assert_case_in "(1...3)", s(:dot3, s(:lit, 1).line(2), s(:lit, 3).line(2)).line(2)
  end

  def test_case_in_33
    assert_case_in "(1...)", s(:dot3, s(:lit, 1).line(2), nil).line(2)
  end

  def test_case_in_34
    assert_case_in "(..10)", s(:dot2, nil, s(:lit, 10).line(2)).line(2)
  end

  def test_case_in_35
    assert_case_in "(...10)", s(:dot3, nil, s(:lit, 10).line(2)).line(2)
  end

  def test_case_in_36
    rb = "[:a, b, c, [:d, *e, nil]]"
    pt = s(:array_pat,
           nil,
           s(:lit, :a).line(2),
           s(:lasgn, :b).line(2),
           s(:lasgn, :c).line(2),
           s(:array_pat,
             nil,
             s(:lit, :d).line(2),
             :"*e",
             s(:nil).line(2)).line(2)).line(2)

    assert_case_in rb, pt
  end

  def test_case_in_37
    rb = "case :a\nin { b: [Hash, *] }\n  :c\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:lit, :b).line(2),
               s(:array_pat, nil, s(:const, :Hash).line(2), :"*").line(2)
              ).line(2),
             s(:lit, :c).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_42
    rb = "case :a\nin :b, *_ then nil\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               nil,
               s(:lit, :b).line(2),
               :"*_",
              ).line(2),
             s(:nil).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_42_2
    rb = "case :a\nin A(*list) then nil\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               s(:const, :A).line(2),
               :"*list").line(2),
             s(:nil).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_42_3
    assert_case_in ":b, *_, :c", s(:array_pat, nil,
                                   s(:lit, :b).line(2),
                                   :"*_",
                                   s(:lit, :c).line(2)).line(2)
  end


  def test_case_in_47
    rb = "case :a\nin [*, :b, :c]\n  :d\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat, nil, :*,
               s(:lit, :b).line(2), s(:lit, :c).line(2)).line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_67
    rb = "case :a\nin 1.. then nil\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in, s(:dot2, s(:lit, 1).line(2), nil).line(2),
             s(:nil).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_76
    assert_case_in "`echo hi`", s(:xstr, "echo hi").line(2)
  end

  def test_case_in_77
    assert_case_in "/regexp/", s(:lit, /regexp/).line(2)
  end

  def test_case_in_78
    assert_case_in "%W[a b]", s(:array_pat, nil, s(:str, "a").line(2), s(:str, "b").line(2)).line(2)
  end

  def test_case_in_79
    assert_case_in "%w[a b]", s(:array_pat, nil, s(:str, "a").line(2), s(:str, "b").line(2)).line(2)
  end

  def test_case_in_80
    assert_case_in "%I[a b]", s(:array_pat, nil, s(:lit, :a).line(2), s(:lit, :b).line(2)).line(2)
  end

  def test_case_in_81
    assert_case_in "%i[a b]", s(:array_pat, nil, s(:lit, :a).line(2), s(:lit, :b).line(2)).line(2)
  end

  def test_case_in_83
    rb = "[->(b) { true }, c]"
    pt = s(:array_pat, nil,
           s(:iter, s(:lambda).line(2), s(:args, :b).line(2),
             s(:true).line(2)).line(2),
           s(:lasgn, :c).line(2)).line(2)

    assert_case_in rb, pt
  end

  def test_case_in_85
    rb = "[[:b, c], [:d, ^e]]"
    pt = s(:array_pat, nil,
           s(:array_pat, nil,
             s(:lit, :b).line(2),
             s(:lasgn, :c).line(2)).line(2),
           s(:array_pat,
             nil,
             s(:lit, :d).line(2),
             s(:lvar, :e).line(2)).line(2),
          ).line(2)

    assert_case_in rb, pt
  end

  def test_case_in_86
    rb = "case [:a, :b]\nin ::NilClass, * then nil\nend"
    pt = s(:case,
           s(:array, s(:lit, :a), s(:lit, :b)),
           s(:in,
             s(:array_pat,
               nil,
               s(:colon3, :NilClass).line(2),
               :*).line(2),
             s(:nil).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_86_2
    rb = "case [:a, :b]\nin *, ::NilClass then nil\nend"
    pt = s(:case,
           s(:array, s(:lit, :a), s(:lit, :b)),
           s(:in,
             s(:array_pat,
               nil,
               :*,
               s(:colon3, :NilClass).line(2)).line(2),
             s(:nil).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_array_pat_const
    rb = "case :a\nin B[c]\n  :d\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               s(:const, :B).line(2),
               s(:lasgn, :c).line(2)).line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_array_pat_const2
    rb = "case :a\nin B::C[d]\n  :e\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               s(:const, s(:colon2, s(:const, :B).line(2), :C).line(2)).line(2),
               s(:lasgn, :d).line(2)).line(2),
             s(:lit, :e).line(3)).line(2),
          nil)

    assert_parse rb, pt
  end

  def test_case_in_array_pat_paren_assign
    rb = "case :a\nin B(C => d)\n  :d\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:array_pat,
               s(:const, :B).line(2),
               s(:lasgn, :d, s(:const, :C).line(2)).line(2)).line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_const
    rb = "case Array\nin Class\n  :b\nend"
    pt = s(:case, s(:const, :Array),
           s(:in, s(:const, :Class).line(2),
             s(:lit, :b).line(3)).line(2),
           nil).line 1

    assert_parse rb, pt
  end

  def test_case_in_else
    rb = "case Array\nin Class\n  :b\nelse\n  :c\nend\n"
    pt = s(:case, s(:const, :Array),
           s(:in, s(:const, :Class).line(2),
             s(:lit, :b).line(3)).line(2),
          s(:lit, :c).line(5)).line 1

    assert_parse rb, pt
  end

  def test_case_in_hash_pat
    rb = "case :a\nin { b: 'c', d: \"e\" } then\n  :f\nend\n"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:lit, :b).line(2), s(:str, "c").line(2),
               s(:lit, :d).line(2), s(:str, "e").line(2)).line(2),
             s(:lit, :f).line(3)
             ).line(2),
          nil)

    assert_parse rb, pt
  end

  def test_case_in_hash_pat_assign
    rb = "case :a\nin { b: Integer => x, d: \"e\", f: } then\n  :g\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:lit, :b).line(2), # =>
               s(:lasgn, :x, s(:const, :Integer).line(2)).line(2),
               s(:lit, :d).line(2), s(:str, "e").line(2),
               s(:lit, :f).line(2), nil).line(2),
             s(:lit, :g).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_hash_pat_paren_assign
    rb = "case :a\nin B(a: 42)\n  :d\nend"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:hash_pat,
               s(:const, :B).line(2),
               s(:lit, :a).line(2), s(:lit, 42).line(2)).line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_hash_pat_paren_true
    rb = "case :a\nin b: true then\n  :c\nend\n"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:lit, :b).line(2), s(:true).line(2)).line(2),
             s(:lit, :c).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_hash_pat_rest
    rb = "case :a\nin b: c, **rest then :d\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:lit, :b).line(2),
               s(:lasgn, :c).line(2),
               s(:kwrest, :"**rest").line(2)).line(2),
             s(:lit, :d).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_hash_pat_rest_solo
    rb = "case :a\nin **rest then :d\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:hash_pat,
               nil,
               s(:kwrest, :"**rest").line(2)).line(2),
             s(:lit, :d).line(2)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_if_unless_post_mod
    rb = "case :a\nin A if true\n  :C\nin D unless false\n  :E\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:if, s(:true).line(2), s(:const, :A).line(2), nil).line(2),
             s(:lit, :C).line(3)).line(2),
           s(:in,
             s(:if, s(:false).line(4), nil, s(:const, :D).line(4)).line(4),
             s(:lit, :E).line(5)).line(4),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_multiple
    rb = "case :a\nin A::B\n  :C\nin D::E\n  :F\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:const, s(:colon2, s(:const, :A).line(2), :B).line(2)).line(2),
             s(:lit, :C).line(3)).line(2),
           s(:in,
             s(:const, s(:colon2, s(:const, :D).line(4), :E).line(4)).line(4),
             s(:lit, :F).line(5)).line(4),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_or
    rb = "case :a\nin B | C\n  :d\nend\n"
    pt = s(:case, s(:lit, :a),
           s(:in,
             s(:or,
               s(:const, :B).line(2),
               s(:const, :C).line(2)).line(2),
             s(:lit, :d).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_in_expr_no_case
    rb = "'woot' in String"
    pt = s(:case, s(:str, "woot"),
           s(:in, s(:const, :String),
             nil),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_019
    rb = <<~RUBY
        case 0
        in -1..1
          true
        end
      RUBY

    pt = s(:case,
           s(:lit, 0),
           s(:in, s(:dot2, s(:lit, -1).line(2), s(:lit, 1).line(2)).line(2),
             s(:true).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_044
    rb = <<~RUBY
      case obj
      in Object[]
        true
      end
    RUBY
    pt = s(:case,
           s(:call, nil, :obj),
           s(:in, s(:array_pat, s(:const, :Object).line(2)).line(2),
             s(:true).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_051
    rb = <<~RUBY
        case [0, 1, 2]
        in [0, 1,]
          true
        end
      RUBY
    pt = s(:case,
           s(:array,
             s(:lit, 0),
             s(:lit, 1),
             s(:lit, 2)),
           s(:in,
             s(:array_pat,
               nil,
               s(:lit, 0).line(2),
               s(:lit, 1).line(2),
               :*).line(666),
             s(:true).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_058
    rb = <<~RUBY
        case {a: 0}
        in {a:, **rest}
          [a, rest]
        end
      RUBY
    pt = s(:case,
           s(:hash,
             s(:lit, :a),
             s(:lit, 0)),
           s(:in,
             s(:hash_pat, nil, s(:lit, :a).line(2), nil,
               s(:kwrest, :"**rest").line(2)).line(2),
             s(:array,
               s(:lvar, :a).line(3),
               s(:lvar, :rest).line(3)).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_058_2
    rb = <<~RUBY
        case {a: 0}
        in {a:, **}
          [a]
        end
      RUBY
    pt = s(:case,
           s(:hash,
             s(:lit, :a),
             s(:lit, 0)),
           s(:in,
             s(:hash_pat, nil, s(:lit, :a).line(2), nil,
               s(:kwrest, :"**").line(2)).line(2),
             s(:array,
               s(:lvar, :a).line(3)).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_parse_pattern_069
    rb = <<~RUBY
        case :a
        in Object[b: 1]
          1
        end
      RUBY
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:hash_pat, s(:const, :Object).line(2),
               s(:lit, :b).line(2), s(:lit, 1).line(2)).line(2),
             s(:lit, 1).line(3)).line(2),
           nil)


    assert_parse rb, pt
  end

  def test_parse_pattern_076
    rb = <<~RUBY
        case {a: 1}
        in {a: 1, **nil}
          true
        end
      RUBY
    pt = s(:case,
           s(:hash, s(:lit, :a), s(:lit, 1)),
           s(:in,
             s(:hash_pat, nil,
               s(:lit, :a).line(2), s(:lit, 1).line(2),
               s(:kwrest, :"**nil").line(2)).line(2),
             s(:true).line(3)).line(2),
           nil)

    assert_parse rb, pt
  end

  # def test_case_in_TEMPLATE
  #   rb = "case :a\nin XXX then\n  YYY\nend\n"
  #   pt = s(:case, s(:lit, :a),
  #          s(:in,
  #            ZZZ,
  #            WWW).line(2),
  #          nil)
  #
  #   assert_parse rb, pt
  # end
end

module TestPatternMatching30
  def test_case_in_20
    assert_case_in("Symbol(*lhs, x, *rhs)",
                   s(:find_pat,
                     s(:const, :Symbol).line(2),
                     :"*lhs",
                     s(:lasgn, :x).line(2),
                     :"*rhs").line(2))
  end

  def test_case_in_22
    assert_case_in("Symbol[*lhs, x, *rhs]",
                   s(:find_pat, s(:const, :Symbol).line(2),
                     :"*lhs",
                     s(:lasgn, :x).line(2),
                     :"*rhs").line(2))
  end
end

module TestRubyParserShared27Plus
  include TestRubyParserShared26Plus
  include TestPatternMatching

  def test_block_args_kwargs
    rb = "f { |**kwargs| kwargs }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :"**kwargs"),
           s(:lvar, :kwargs))

    assert_parse rb, pt
  end

  def test_block_args_no_kwargs
    rb = "f { |**nil| }"
    pt = s(:iter,
           s(:call, nil, :f),
           s(:args, :"**nil"))

    assert_parse rb, pt
  end

  def test_defn_forward_args
    rb = "def a(...); b(...); end"
    pt = s(:defn, :a, s(:args, s(:forward_args)),
          s(:call, nil, :b, s(:forward_args)))

    assert_parse rb, pt
  end

  def test_defn_arg_forward_args
    rb = "def a(x, ...); b(x, ...); end"
    pt = s(:defn, :a, s(:args, :x, s(:forward_args)),
           s(:call, nil, :b, s(:lvar, :x), s(:forward_args)))

    assert_parse rb, pt
  end

  def test_defn_args_forward_args
    rb = "def a(x, y, z, ...); b(:get, z, ...); end"
    pt = s(:defn, :a, s(:args, :x, :y, :z, s(:forward_args)),
           s(:call, nil, :b, s(:lit, :get), s(:lvar, :z),
             s(:forward_args)))

    assert_parse rb, pt
  end

  def test_defn_no_kwargs
    # def x(**nil)
    # end
    #
    # def y(**kw)
    # end
    #
    # def z()
    # end
    #
    # x arg: 42 # $!: no keywords accepted (ArgumentError)
    # y arg: 42 # fine
    # z arg: 42 # $!: wrong number of arguments (given 1, expected 0) (ArgumentError)

    rb = "def x(**nil); end"
    pt = s(:defn, :x, s(:args, :"**nil"),
           s(:nil))

    assert_parse rb, pt
  end

  def test_call_forward_args_outside_method_definition
    rb = "b(...)"

    assert_syntax_error rb, "Unexpected ..."
  end

  def test_call_arg_forward_args_outside_method_definition
    rb = "b(x, ...)"

    assert_syntax_error rb, "Unexpected ..."
  end

  def test_mlhs_rescue
    # same:
    # a = (24 rescue 42)
    # a = 24 rescue 42

    # same:
    # a, b = (f rescue 42)
    # a, b = f rescue 42

    rb = "a, b = f rescue 42"
    pt = s(:masgn,
           s(:array, s(:lasgn, :a), s(:lasgn, :b)),
           s(:to_ary,
             s(:rescue,
               s(:call, nil, :f),
               s(:resbody, s(:array),
                 s(:lit, 42)))))

    assert_parse rb, pt
  end
end

module TestRubyParserShared30Plus
  include TestRubyParserShared27Plus
  include TestPatternMatching30

  def test_rhs_asgn
    rb = "42 => n"
    pt = s(:case,
           s(:lit, 42),
           s(:in, s(:lasgn, :n), nil), nil)

    assert_parse rb, pt
  end

  def test_case_in_find
    rb = "case :a\n  in *a, :+, *b\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:find_pat, nil,
               :"*a",
               s(:lit, :+).line(2),
               :"*b").line(2),
             nil).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_case_in_find_array
    rb = "case :a\nin [*, :b, c, *]\nend"
    pt = s(:case,
           s(:lit, :a),
           s(:in,
             s(:find_pat, nil,
               :*,
               s(:lit, :b).line(2), s(:lasgn, :c).line(2),
               :*).line(2),
             nil).line(2),
           nil)

    assert_parse rb, pt
  end

  def test_defn_oneliner
    rb = "def exec(cmd) = system(cmd)"
    pt = s(:defn, :exec, s(:args, :cmd),
           s(:call, nil, :system, s(:lvar, :cmd)))

    assert_parse rb, pt
  end

  def test_defn_oneliner_noargs_parentheses
    rb = "def exec() = system"
    pt = s(:defn, :exec, s(:args),
            s(:call, nil, :system))

    assert_parse rb, pt
  end

  def test_defn_oneliner_noargs
    rb = "def exec = system"
    pt = s(:defn, :exec, s(:args),
            s(:call, nil, :system))

    assert_parse rb, pt
  end

  def test_defn_oneliner_rescue
    rb = "def exec(cmd)\n  system(cmd)\nrescue\n  nil\nend\n"
    pt = s(:defn, :exec, s(:args, :cmd),
           s(:rescue,
             s(:call, nil, :system, s(:lvar, :cmd).line(2)).line(2),
             s(:resbody, s(:array).line(3),
               s(:nil).line(4)).line(3)).line(2))

    assert_parse rb, pt

    rb = "def exec(cmd)\n  system(cmd) rescue nil\nend\n"
    assert_parse rb, pt.deep_each { |s| s.line = 2 if s.line && s.line > 1 }

    rb = "def exec(cmd) = system(cmd) rescue nil"
    assert_parse rb, pt.deep_each { |s| s.line = 1 }
  end

  def test_defn_oneliner_comment
    p = RubyParser.new
    rb = "# blah\ndef exec(cmd) = system(cmd)"
    sexp = p.parse rb

    assert_equal :defn, sexp.sexp_type
    assert_equal "# blah\n", sexp.comments
  end

  def test_defs_oneliner
    rb = "def self.exec(cmd) = system(cmd)"
    pt = s(:defs, s(:self), :exec, s(:args, :cmd),
           s(:call, nil, :system, s(:lvar, :cmd)))

    assert_parse rb, pt
  end

  def test_defs_oneliner_rescue
    rb = "def self.exec(cmd)\n  system(cmd)\nrescue\n  nil\nend\n"
    pt = s(:defs, s(:self), :exec, s(:args, :cmd),
           s(:rescue,
             s(:call, nil, :system, s(:lvar, :cmd).line(2)).line(2),
            s(:resbody, s(:array).line(3), s(:nil).line(4)).line(3)).line(2))
    assert_parse rb, pt

    rb = "def self.exec(cmd)\n  system(cmd) rescue nil\nend\n"
    assert_parse rb, pt.deep_each { |s| s.line = 2 if s.line && s.line > 1 }

    rb = "def self.exec(cmd) = system(cmd) rescue nil"
    assert_parse rb, pt.deep_each { |s| s.line = 1 }
  end

  def test_defs_oneliner_comment
    p = RubyParser.new
    rb = "# blah\ndef self.exec(cmd) = system(cmd)"
    sexp = p.parse rb

    assert_equal :defs, sexp.sexp_type
    assert_equal "# blah\n", sexp.comments
  end

  def test_defn_oneliner_setter
    rb = "class X\n  def x=(o) = 42\nend"

    assert_syntax_error rb, /setter method cannot be defined/

    rb = "class X\n  def []=(k, v) = 42\nend"

    assert_syntax_error rb, /setter method cannot be defined/
  end

  def test_defs_oneliner_setter
    rb = "class X\n  def self.x=(o) = 42\nend"

    assert_syntax_error rb, /setter method cannot be defined/

    rb = "class X\n  def self.[]=(k, v) = 42\nend"

    assert_syntax_error rb, /setter method cannot be defined/
  end

  def test_defn_oneliner_eq2
    rb = "class X\n  def ==(o) = 42\nend"
    pt = s(:class, :X, nil,
           s(:defn, :==, s(:args, :o).line(2),
             s(:lit, 42).line(2)).line(2)
          ).line(1)

    assert_parse rb, pt
  end

  def test_defs_oneliner_eq2
    rb = "class X\n  def self.==(o) = 42\nend"
    pt = s(:class, :X, nil,
           s(:defs, s(:self).line(2), :==, s(:args, :o).line(2),
             s(:lit, 42).line(2)).line(2)
          ).line(1)

    assert_parse rb, pt
  end
end

module TestRubyParserShared31Plus
  include TestRubyParserShared30Plus

  def test_assoc__bare
    rb = "{ y: }"
    pt = s(:hash, s(:lit, :y), nil)

    assert_parse rb, pt
  end

  def test_block_arg__bare
    rb = "def x(&); end"
    pt = s(:defn, :x, s(:args, :&).line(1),
           s(:nil).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_case_in_carat_parens
    processor.env[:a] = :lvar

    rb = "[^(a)]"
    pt = s(:array_pat, nil,
           s(:lvar, :a).line(2)).line(2)

    assert_case_in rb, pt
  end

  def test_case_in_carat_nonlocal_vars
    processor.env[:a] = :lvar

    rb = "[^@a, ^$b, ^@@c]"
    pt = s(:array_pat,
           nil,
           s(:ivar, :@a).line(2),
           s(:gvar, :$b).line(2),
           s(:cvar, :@@c).line(2)).line(2)

    assert_case_in rb, pt
  end

  def test_case_in_quoted_label
    rb = " \"b\": "
    pt = s(:hash_pat, nil, s(:lit, :b).line(2), nil).line(2)

    assert_case_in rb, pt
  end

  def test_call_block_arg_named
    processor.env[:blk] = :lvar
    rb = "x(&blk)"
    pt = s(:call, nil, :x,
           s(:block_pass, s(:lvar, :blk).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_call_block_arg_unnamed
    rb = "x(&)"
    pt = s(:call, nil, :x,
           s(:block_pass).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_defn_endless_command
    rb = "def some_method = other_method 42"
    pt = s(:defn, :some_method, s(:args).line(1),
           s(:call, nil, :other_method, s(:lit, 42).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_defn_endless_command_rescue
    rb = "def some_method = other_method 42 rescue 24"
    pt = s(:defn, :some_method, s(:args).line(1),
           s(:rescue,
             s(:call, nil, :other_method, s(:lit, 42).line(1)).line(1),
             s(:resbody, s(:array).line(1),
               s(:lit, 24).line(1)).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_defs_endless_command
    rb = "def x.some_method = other_method 42"
    pt = s(:defs, s(:call, nil, :x).line(1), :some_method, s(:args).line(1),
           s(:call, nil, :other_method, s(:lit, 42).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end

  def test_defs_endless_command_rescue
    rb = "def x.some_method = other_method 42 rescue 24"
    pt = s(:defs, s(:call, nil, :x).line(1), :some_method, s(:args).line(1),
           s(:rescue,
             s(:call, nil, :other_method, s(:lit, 42).line(1)).line(1),
             s(:resbody, s(:array).line(1),
               s(:lit, 24).line(1)).line(1)).line(1)).line(1)

    assert_parse rb, pt
  end
end

module TestRubyParserShared32Plus
  include TestRubyParserShared31Plus
end

class Minitest::Test
  def skip s = "blah"
    warn "ignoring skip for %s: %s" % [name, s]
  end
end if ENV["NOSKIP"]

class TestRubyParser < Minitest::Test
  def test_cls_version
    assert_equal 23, RubyParser::V23.version
    assert_equal 24, RubyParser::V24.version
    assert_equal 24, Ruby24Parser.version
    refute RubyParser::Parser.version
  end

  def test_parse
    processor = RubyParser.new

    rb = "a.()"
    pt = s(:call, s(:call, nil, :a), :call)

    assert_equal pt, processor.parse(rb)

    # bad syntax
    e = assert_raises Racc::ParseError do
      capture_io do
        processor.parse "a.("
      end
    end

    assert_includes e.message, 'parse error on value "$" ($end)'
  end

  def test_parse_error_from_first
    processor = RubyParser.new

    e = assert_raises Racc::ParseError do
      capture_io do
        processor.parse "a -> () {"
      end
    end

    # This is a 2.x error, will fail on 1.8/1.9.
    assert_includes e.message, 'parse error on value "$" ($end)'
  end
end

class RubyParserTestCase < ParseTreeTestCase
  attr_accessor :result, :processor

  make_my_diffs_pretty!

  def self.previous key
    "Ruby"
  end

  def self.generate_test klass, node, data, input_name, output_name
    return if node.to_s =~ /bmethod|dmethod/
    return if Array === data["Ruby"]

    output_name = "ParseTree"

    super
  end

  attr_accessor :assert_parse_ran

  require "ruby2ruby" if ENV["R2R"]

  def assert_parse rb, pt
    self.processor.reset if assert_parse_ran # allows multiple calls
    self.assert_parse_ran = true

    timeout = (ENV["RP_TIMEOUT"] || 10).to_i

    pt.deep_each { |s| s.line ||= 1 }
    pt.line ||= 1

    self.result = processor.parse rb, "(string)", timeout

    # just try it for now:
    Ruby2Ruby.new.process(result.deep_clone) if ENV["R2R"]

    assert_equal pt, result
  end

  def assert_parse_error rb, emsg
    e = nil
    assert_silent do
      e = assert_raises Racc::ParseError do
        processor.parse rb
      end
    end

    if Regexp === emsg then
      assert_match emsg, e.message
    else
      assert_equal emsg, e.message
    end
  end

  def assert_syntax_error rb, emsg, klass = RubyParser::SyntaxError
    e = nil
    assert_silent do
      e = assert_raises klass do
        processor.parse rb
      end
    end

    case emsg
    when String
      assert_equal emsg, e.message
    else
      assert_match emsg, e.message
    end
  end

  def refute_parse rb
    self.result = processor.parse rb
    assert_nil result
  end
end

class TestRubyParserV20 < RubyParserTestCase
  include TestRubyParserShared20Plus

  def setup
    super

    self.processor = RubyParser::V20.new
  end
end

class TestRubyParserV21 < RubyParserTestCase
  include TestRubyParserShared21Plus

  def setup
    super

    self.processor = RubyParser::V21.new
  end
end

class TestRubyParserV22 < RubyParserTestCase
  include TestRubyParserShared22Plus

  def setup
    super

    self.processor = RubyParser::V22.new
  end
end

class TestRubyParserV23 < RubyParserTestCase
  include TestRubyParserShared23Plus

  def setup
    super

    self.processor = RubyParser::V23.new
  end

  def test_lasgn_call_nobracket_rescue_arg
    rb = "a = b 1 rescue 2"
    pt = s(:rescue,
          s(:lasgn, :a, s(:call, nil, :b, s(:lit, 1))),
          s(:resbody, s(:array), s(:lit, 2)))

    assert_parse rb, pt
  end
end

class TestRubyParserV24 < RubyParserTestCase
  include TestRubyParserShared24Plus

  def setup
    super

    self.processor = RubyParser::V24.new
  end

  def test_rescue_parens
    rb = "a (b rescue c)"
    pt = s(:call, nil, :a,
           s(:rescue, s(:call, nil, :b),
             s(:resbody, s(:array), s(:call, nil, :c))))

    assert_parse rb, pt

    assert_parse_error "a(b rescue c)", /parse error on value .rescue/
  end
end

class TestRubyParserV25 < RubyParserTestCase
  include TestRubyParserShared25Plus

  def setup
    super

    self.processor = RubyParser::V25.new
  end

  def test_rescue_do_end_ensure_result
    rb = "proc do\n  :begin\nensure\n  :ensure\nend.call"
    pt = s(:call,
           s(:iter,
             s(:call, nil, :proc), 0,
             s(:ensure,
               s(:lit, :begin).line(2),
               s(:lit, :ensure).line(4)).line(2)),
           :call)

    assert_parse rb, pt
  end

  def test_rescue_do_end_no_raise
    rb = "tap do\n  :begin\nrescue\n  :rescue\nelse\n  :else\nensure\n  :ensure\nend"
    pt = s(:iter,
           s(:call, nil, :tap), 0,
           s(:ensure,
             s(:rescue,
               s(:lit, :begin).line(2),
               s(:resbody, s(:array).line(3),
                 s(:lit, :rescue).line(4)).line(3),
               s(:lit, :else).line(6)).line(2),
             s(:lit, :ensure).line(8)).line(2))

    assert_parse rb, pt
  end

  def test_rescue_do_end_raised
    rb = "tap do\n  raise\nensure\n  :ensure\nend"
    pt = s(:iter,
           s(:call, nil, :tap), 0,
           s(:ensure,
             s(:call, nil, :raise).line(2),
             s(:lit, :ensure).line(4)).line(2))

    assert_parse rb, pt
  end

  def test_rescue_do_end_rescued
    rb = "tap do\n  raise\nrescue\n  :rescue\nelse\n  :else\nensure\n  :ensure\nend"
    pt = s(:iter,
           s(:call, nil, :tap),
           0,
           s(:ensure,
             s(:rescue,
               s(:call, nil, :raise).line(2),
               s(:resbody,
                 s(:array).line(3),
                 s(:lit, :rescue).line(4)).line(3),
               s(:lit, :else).line(6)).line(2),
             s(:lit, :ensure).line(8)).line(2))

    assert_parse rb, pt
  end

  def test_rescue_in_block
    rb = "blah do\nrescue\n  stuff\nend"
    pt = s(:iter,
           s(:call, nil, :blah), 0,
           s(:rescue,
             s(:resbody, s(:array).line(2),
               s(:call, nil, :stuff).line(3)).line(2)).line(2))

    assert_parse rb, pt
  end
end

class TestRubyParserV26 < RubyParserTestCase
  include TestRubyParserShared26Plus

  def setup
    super

    self.processor = RubyParser::V26.new
  end

  def test_parse_line_dot2_open
    rb = "0..\n; a..\n; c"
    pt = s(:block,
           s(:dot2, s(:lit, 0), nil),
           s(:dot2, s(:call, nil, :a).line(2), nil).line(2),
           s(:call, nil, :c).line(3))

    assert_parse rb, pt
  end

  def test_parse_line_dot3_open
    rb = "0...\n; a...\n; c"
    pt = s(:block,
           s(:dot3, s(:lit, 0), nil),
           s(:dot3, s(:call, nil, :a).line(2), nil).line(2),
           s(:call, nil, :c).line(3))

    assert_parse rb, pt
  end
end

class TestRubyParserV27 < RubyParserTestCase
  make_my_diffs_pretty!

  include TestRubyParserShared27Plus

  def setup
    super

    self.processor = RubyParser::V27.new
  end

  def test_bdot2
    rb = "..10\n; ..a\n; c"
    pt = s(:block,
           s(:dot2, nil, s(:lit, 10)),
           s(:dot2, nil, s(:call, nil, :a).line(2)).line(2),
           s(:call, nil, :c).line(3))

    assert_parse rb, pt
  end

  def test_bdot3
    rb = "...10\n; ...a\n; c"
    pt = s(:block,
           s(:dot3, nil, s(:lit, 10)),
           s(:dot3, nil, s(:call, nil, :a).line(2)).line(2),
           s(:call, nil, :c).line(3))

    assert_parse rb, pt
  end
end

class TestRubyParserV30 < RubyParserTestCase
  include TestRubyParserShared30Plus

  def setup
    super

    self.processor = RubyParser::V30.new
  end
end

class TestRubyParserV31 < RubyParserTestCase
  include TestRubyParserShared31Plus

  def setup
    super

    self.processor = RubyParser::V31.new
  end
end

class TestRubyParserV32 < RubyParserTestCase
  include TestRubyParserShared32Plus

  def setup
    super

    self.processor = RubyParser::V32.new
  end
end

RubyParser::VERSIONS.each do |klass|
  v = klass.version
  describe "block args arity #{v}" do
    attr_accessor :parser

    before do
      self.parser = RubyParser.const_get("V#{v}").new
    end

    {
      "->       {    }" => s(:iter, s(:lambda),                       0),
      "lambda   {    }" => s(:iter, s(:call, nil, :lambda),           0),
      "proc     {    }" => s(:iter, s(:call, nil, :proc),             0),
      "Proc.new {    }" => s(:iter, s(:call, s(:const, :Proc), :new), 0),

      "-> ()    {    }" => s(:iter, s(:lambda),                       s(:args)),
      "lambda   { || }" => s(:iter, s(:call, nil, :lambda),           s(:args)),
      "proc     { || }" => s(:iter, s(:call, nil, :proc),             s(:args)),
      "Proc.new { || }" => s(:iter, s(:call, s(:const, :Proc), :new), s(:args)),

    }.each do |input, expected|
      next if v == 18 and input =~ /->/
      next if v == 19 and input =~ /-> \(\)/

      it "parses '#{input}'" do
        assert_equal expected, parser.parse(input)
      end

      input = input.sub(/\{/, "do").sub(/\}/, "end")
      it "parses '#{input}'" do
        assert_equal expected, parser.parse(input)
      end
    end
  end
end
