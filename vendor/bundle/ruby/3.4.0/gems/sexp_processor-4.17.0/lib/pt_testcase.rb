# encoding: US-ASCII

$TESTING = true
# :stopdoc:

require "minitest/test"
require "sexp_processor" # for deep_clone

# key:
# wwtt = what were they thinking?

class Examples
  attr_reader :reader
  attr_writer :writer

  def a_method x; x+1; end
  alias an_alias a_method

  define_method(:bmethod_noargs) do
    x + 1
  end

  define_method(:unsplatted) do |x|
    x + 1
  end

  define_method :splatted do |*args|
    y = args.first
    y + 42
  end

  define_method :dmethod_added, instance_method(:a_method) if
    RUBY_VERSION < "1.9"
end

class ParseTreeTestCase < Minitest::Test
  all_versions  = %w[18 19 20 21 22 23 24 25 26 27 30 31 32]
  most_versions = all_versions.drop(1)

  TEST_SUFFIX = "_#{most_versions.join "_"}"
  VER_RE      = /(#{Regexp.union(*all_versions)})/

  attr_accessor :processor # to be defined by subclass

  def setup
    super
    @processor = nil
  end

  def after_process_hook klass, node, data, input_name, output_name
  end

  def before_process_hook klass, node, data, input_name, output_name
  end

  def self.add_test name, data, klass = self.name[4..-1]
    name = name.to_s
    klass = klass.to_s

    if testcases.has_key? name then
      if testcases[name].has_key? klass then
        warn "testcase #{klass}##{name} already has data"
      else
        testcases[name][klass] = data
      end
    else
      warn "testcase #{name} does not exist"
    end
  end

  def self.add_tests name, hash
    name = name.to_s

    hash.each do |klass, data|
      warn "testcase #{klass}##{name} already has data" if
        testcases[name].has_key? klass
      testcases[name][klass] = data
    end
  end

  def self.add_18tests name, hash
    add_tests "#{name}__18", hash
  end

  def self.add_19tests name, hash
    add_tests "#{name}_#{TEST_SUFFIX}", hash # HACK?
  end

  def self.add_19edgecases ruby, sexp, cases
    cases.each do |name, code|
      add_19tests name, "Ruby" => code, "ParseTree" => sexp, "Ruby2Ruby" => ruby
    end
  end

  def self.clone_same
    @@testcases.each do |node, data|
      data.each do |key, val|
        if val == :same then
          prev_key = self.previous(key)
          data[key] = data[prev_key].deep_clone
        end
      end
    end
  end

  def self.copy_test_case nonverbose, klass
    verbose = nonverbose + "_mri_verbose_flag"
    testcases[verbose][klass] = testcases[nonverbose][klass]
  end

  def self.generate_test klass, node, data, input_name, output_name
    klass.send :define_method, "test_#{node}" do
      flunk "Processor is nil" if processor.nil?

      tversions = node[/(?:_#{VER_RE})+$/]
      if tversions then
        cversion = self.class.name[/#{VER_RE}/]

        assert true # shut up prove_it!

        # can't push this up because it may be generating into an
        # abstract test class and the actual subclass is versioned.
        return "version specific test" unless tversions.include? cversion if cversion
      end

      assert data.has_key?(input_name), "Unknown input data"
      assert data.has_key?(output_name), "Missing test data"

      $missing[node] << output_name unless data.has_key? output_name

      input    = data[input_name].deep_clone
      expected = data[output_name].deep_clone

      case expected
      when :unsupported then
        assert_raises(UnsupportedNodeError) do
          processor.process(input)
        end
      else
        extra_expected = []
        extra_input = []

        _, expected, extra_expected = *expected if
          Array === expected and expected.sexp_type == :defx
        _, input, extra_input = *input if
          Array === input and input.sexp_type == :defx

        # OMG... I can't believe I have to do this this way.  these
        # hooks are here instead of refactoring this define_method
        # body into an assertion. It'll allow subclasses to hook in
        # and add behavior before or after the processor does it's
        # thing. If you go the body refactor route, some of the
        # RawParseTree test cases fail for completely bogus reasons.

        before_process_hook klass, node, data, input_name, output_name
        refute_nil data[input_name], "testcase does not exist?"
        timeout = (ENV["RP_TIMEOUT"] || 10).to_i
        @result = processor.process input, "(string)", timeout
        assert_equal(expected, @result,
                     "failed on input: #{data[input_name].inspect}")
        after_process_hook klass, node, data, input_name, output_name

        extra_input.each do |extra|
          processor.process(extra)
        end
        extra = if processor.respond_to?(:extra_methods) then
                  processor.extra_methods
                else
                  []
                end
        assert_equal extra_expected, extra
      end
    end
  end

  def self.generate_tests klass
    install_missing_reporter
    clone_same

    output_name = klass.name.to_s.sub(/^Test/, "")

    input_name = self.previous(output_name)

    @@testcases.each do |node, data|
      next if [:skip, :unsupported].include? data[input_name]
      next if data[output_name] == :skip

      generate_test klass, node, data, input_name, output_name
    end
  end

  def self.inherited klass
    super

    generate_tests klass unless klass.name =~ /TestCase/
  end

  def self.install_missing_reporter
    unless defined? $missing then
      $missing = Hash.new { |h,k| h[k] = [] }
      at_exit {
        at_exit {
          warn ""
          $missing.sort.each do |name, klasses|
            warn "add_tests(#{name.inspect},"
            klasses.map! { |klass| "          #{klass.inspect} => :same" }
            warn klasses.join("\n") + ")"
          end
          warn ""
        }
      }
    end
  end

  def self.previous key, extra=0 # FIX: remove R2C code
    idx = @@testcase_order.index(key)

    raise "Unknown class #{key} in @@testcase_order" if idx.nil?

    case key
    when "RubyToRubyC" then
      idx -= 1
    end
    @@testcase_order[idx - 1 - extra]
  end

  def self.testcase_order; @@testcase_order; end
  def self.testcases; @@testcases; end

  def self.unsupported_tests *tests
    tests.flatten.each do |name|
      add_test name, :unsupported
    end
  end

  ############################################################
  # Shared TestCases:

  @@testcase_order = %w(Ruby ParseTree)

  @@testcases = Hash.new { |h,k| h[k] = {} }

  ###
  # 1.8 specific tests

  add_18tests("call_arglist_norm_hash_splat",
              "Ruby"         => "o.m(42, :a => 1, :b => 2, *c)",
              "ParseTree"    => s(:call,
                                  s(:call, nil, :o), :m,
                                  s(:lit, 42),
                                  s(:hash,
                                    s(:lit, :a), s(:lit, 1),
                                    s(:lit, :b), s(:lit, 2)),
                                  s(:splat, s(:call, nil, :c))))

  add_18tests("call_arglist_space",
              "Ruby"         => "a (1,2,3)",
              "ParseTree"    => s(:call, nil, :a,
                                  s(:lit, 1), s(:lit, 2), s(:lit, 3)),
              "Ruby2Ruby"    => "a(1, 2, 3)")

  add_18tests("fcall_arglist_norm_hash_splat",
              "Ruby"         => "m(42, :a => 1, :b => 2, *c)",
              "ParseTree"    => s(:call, nil, :m,
                                  s(:lit, 42),
                                  s(:hash,
                                    s(:lit, :a), s(:lit, 1),
                                    s(:lit, :b), s(:lit, 2)),
                                  s(:splat, s(:call, nil, :c))))

  add_18tests("if_args_no_space_symbol",
              "Ruby"       => "x if y:z",
              "ParseTree"  => s(:if,
                                s(:call, nil, :y,  s(:lit, :z)),
                                s(:call, nil, :x),
                                nil),
              "Ruby2Ruby"  => "x if y(:z)")

  add_18tests("if_post_not",
              "Ruby"         => "a if not b",
              "ParseTree"    => s(:if, s(:call, nil, :b), nil,
                                  s(:call, nil, :a)),
              "Ruby2Ruby"    => "a unless b")

  add_18tests("if_pre_not",
              "Ruby"         => "if not b then a end",
              "ParseTree"    => s(:if, s(:call, nil, :b), nil,
                                  s(:call, nil, :a)),
              "Ruby2Ruby"    => "a unless b")

  add_18tests("iter_args_ivar",
              "Ruby"         => "a { |@a| 42 }",
              "ParseTree"    => s(:iter,
                                  s(:call, nil, :a),
                                  s(:args, :@a),
                                  s(:lit, 42)))

  add_18tests("iter_masgn_args_ivar",
              "Ruby"         => "a { |a, @b| 42 }",
              "ParseTree"    => s(:iter,
                                  s(:call, nil, :a),
                                  s(:args, :a, :@b),
                                  s(:lit, 42)))

  add_18tests("not",
              "Ruby"         => "(not true)",
              "ParseTree"    => s(:not, s(:true)))

  add_18tests("str_question_control",
              "Ruby"         => '?\M-\C-a',
              "ParseTree"    => s(:lit, 129),
              "Ruby2Ruby"    => "129")

  add_18tests("str_question_escape",
              "Ruby"         => '?\n',
              "ParseTree"    => s(:lit, 10),
              "Ruby2Ruby"    => "10")

  add_18tests("str_question_literal",
              "Ruby"         => "?a",
              "ParseTree"    => s(:lit, 97),
              "Ruby2Ruby"    => "97")

  add_18tests("unless_post_not",
              "Ruby"         => "a unless not b",
              "ParseTree"    => s(:if, s(:call, nil, :b),
                                  s(:call, nil, :a), nil),
              "Ruby2Ruby"    => "a if b")

  add_18tests("unless_pre_not",
              "Ruby"         => "unless not b then a end",
              "ParseTree"    => s(:if, s(:call, nil, :b),
                                  s(:call, nil, :a), nil),
              "Ruby2Ruby"    => "a if b")

  add_18tests("until_post_not",
              "Ruby"         => "begin\n  (1 + 1)\nend until not true",
              "ParseTree"    => s(:while, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), false),
              "Ruby2Ruby"    => "begin\n  (1 + 1)\nend while true")

  add_18tests("until_pre_not",
              "Ruby"         => "until not true do\n  (1 + 1)\nend",
              "ParseTree"    => s(:while, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "while true do\n  (1 + 1)\nend")

  add_18tests("until_pre_not_mod",
              "Ruby"         => "(1 + 1) until not true",
              "ParseTree"    => s(:while, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "while true do\n  (1 + 1)\nend")

  add_18tests("while_post_not",
              "Ruby"         => "begin\n  (1 + 1)\nend while not true",
              "ParseTree"    => s(:until, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), false),
              "Ruby2Ruby"    => "begin\n  (1 + 1)\nend until true")

  add_18tests("while_pre_not",
              "Ruby"         => "while not true do\n  (1 + 1)\nend",
              "ParseTree"    => s(:until, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "until true do\n  (1 + 1)\nend")

  add_18tests("while_pre_not_mod",
              "Ruby"         => "(1 + 1) while not true",
              "ParseTree"    => s(:until, s(:true),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "until true do\n  (1 + 1)\nend") # FIX

  ###
  # 1.9 specific tests

  add_19edgecases("-> () { (x + 1) }",
                  s(:iter,
                    s(:lambda),
                    s(:args),
                    s(:call, s(:call, nil, :x), :+, s(:lit, 1))),
                  "stabby_args"                   => "->() { (x + 1) }",
                  "stabby_args_doend"             => "->() do (x + 1) end")

  add_19edgecases("-> { (x + 1) }",
                  s(:iter,
                    s(:lambda),
                    0,
                    s(:call, s(:call, nil, :x), :+, s(:lit, 1))),
                  "stabby_args_0_no_parens"       => "-> { (x + 1) }",
                  "stabby_args_0_no_parens_doend" => "-> do (x + 1) end",
                  "stabby_args_0_spacebar_broken" => "->{x+1}") # I hate you

  add_19edgecases("-> (x, y) { (x + y) }",
                  s(:iter,
                    s(:lambda),
                    s(:args, :x, :y),
                    s(:call, s(:lvar, :x), :+, s(:lvar, :y))),
                  "stabby_args_2"                 => "->(x, y) { (x + y) }",
                  "stabby_args_2_doend"           => "->(x, y) do (x + y) end",
                  "stabby_args_2_no_parens"       => "-> x, y { (x + y) }",
                  "stabby_args_2_no_parens_doend" => "-> x, y do (x + y) end")

  add_19edgecases("-> (x) { (x + 1) }",
                  s(:iter,
                    s(:lambda),
                    s(:args, :x),
                    s(:call, s(:lvar, :x), :+, s(:lit, 1))),
                  "stabby_args_1"                 => "->(x) { (x + 1) }",
                  "stabby_args_1_doend"           => "->(x) do (x + 1) end",
                  "stabby_args_1_no_parens"       => "-> x { (x + 1) }",
                  "stabby_args_1_no_parens_doend" => "-> x do (x + 1) end")

  add_19tests("array_bare_hash",
              "Ruby"         => "[:a, :b => :c]",
              "ParseTree"    => s(:array,
                                  s(:lit, :a),
                                  s(:hash,
                                    s(:lit, :b),
                                    s(:lit, :c))),
              "Ruby2Ruby"    => "[:a, { :b => :c }]")

  add_19tests("array_bare_hash_labels",
              "Ruby"         => "[:a, b: :c]",
              "ParseTree"    => s(:array,
                                  s(:lit, :a),
                                  s(:hash,
                                    s(:lit, :b),
                                    s(:lit, :c))),
              "Ruby2Ruby"    => "[:a, { :b => :c }]")

  add_19tests("call_arglist_norm_hash_colons",
              "Ruby"         => "o.m(42, a: 1, b: 2)",
              "ParseTree"    => s(:call,
                                  s(:call, nil, :o),
                                  :m,
                                  s(:lit, 42),
                                  s(:hash,
                                    s(:lit, :a), s(:lit, 1),
                                    s(:lit, :b), s(:lit, 2))),
              "Ruby2Ruby"    => "o.m(42, :a => 1, :b => 2)")

  add_19tests("call_arglist_trailing_comma",
              "Ruby"         => "a(1,2,3,)",
              "ParseTree"    => s(:call,
                                  nil,
                                  :a,
                                  s(:lit, 1), s(:lit, 2), s(:lit, 3)),
              "Ruby2Ruby"    => "a(1, 2, 3)")

  add_19tests("call_bang",
              "Ruby"         => "!a",
              "ParseTree"    => s(:call,
                                  s(:call, nil, :a),
                                  :"!"),
              "Ruby2Ruby"    => "(not a)")

  add_19tests("call_bang_empty",
              "Ruby"         => "! ()",
              "ParseTree"    => s(:call, s(:nil), :"!"),
              "Ruby2Ruby"    => "(not nil)")

  add_19tests("call_fonz",
              "Ruby"         => "a.()",
              "ParseTree"    => s(:call, s(:call, nil, :a), :call),
              "Ruby2Ruby"    => "a.call")

  add_19tests("call_fonz_cm",
              "Ruby"         => "a::()",
              "ParseTree"    => s(:call, s(:call, nil, :a), :call),
              "Ruby2Ruby"    => "a.call")

  add_19tests("call_not",
              "Ruby"      => "not (42)",
              "ParseTree" => s(:call, s(:lit, 42), :"!"),
              "Ruby2Ruby" => "(not 42)")

  # add_19tests("call_not_empty",
  #             "Ruby"      => "not ()",
  #             "ParseTree" => s(:call, s(:lit, 42), :"!"))

  add_19tests("call_not_equal",
            "Ruby"         => "a != b",
            "ParseTree"    => s(:call,
                                s(:call, nil, :a),
                                :"!=",
                                s(:call, nil, :b)),
            "Ruby2Ruby"    => "(a != b)")

  add_19tests("call_splat_mid",
              "Ruby"      => "def f(a = nil, *b, c)\n  # do nothing\nend",
              "ParseTree" => s(:defn, :f,
                               s(:args, s(:lasgn, :a, s(:nil)), :"*b", :c),
                               s(:nil)))

  add_19tests("defn_args_mand_opt_mand",
              "Ruby"      => "def f(mand1, opt = 42, mand2)\n  # do nothing\nend",
              "ParseTree" => s(:defn, :f,
                               s(:args, :mand1, s(:lasgn, :opt, s(:lit, 42)), :mand2),
                               s(:nil)))

  add_19tests("defn_args_mand_opt_splat_mand",
              "Ruby"      => "def f(mand1, opt = 42, *rest, mand2)\n  # do nothing\nend",
              "ParseTree" => s(:defn, :f,
                               s(:args, :mand1, s(:lasgn, :opt, s(:lit, 42)), :"*rest", :mand2),
                               s(:nil)))

  add_19tests("defn_args_opt_mand",
              "Ruby"      => "def f(opt = 42, mand)\n  # do nothing\nend",
              "ParseTree" => s(:defn, :f,
                               s(:args, s(:lasgn, :opt, s(:lit, 42)), :mand),
                               s(:nil)))

  add_19tests("defn_args_opt_splat_mand",
              "Ruby"      => "def f(opt = 42, *rest, mand)\n  # do nothing\nend",
              "ParseTree" => s(:defn, :f,
                               s(:args, s(:lasgn, :opt, s(:lit, 42)), :"*rest", :mand),
                               s(:nil)))

  add_19tests("defn_args_splat_mand",
              "Ruby"         => "def f(*rest, mand)\n  # do nothing\nend",
              "ParseTree"    => s(:defn, :f,
                                  s(:args, :"*rest", :mand),
                                  s(:nil)))

  add_19tests("defn_args_splat_middle",
            "Ruby"         => "def f(first, *middle, last)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :first, :"*middle", :last),
                                s(:nil)))

  add_19tests("fcall_arglist_hash_colons",
              "Ruby"         => "m(a: 1, b: 2)",
              "ParseTree"    => s(:call, nil, :m,
                                  s(:hash,
                                    s(:lit, :a), s(:lit, 1),
                                    s(:lit, :b), s(:lit, 2))),
              "Ruby2Ruby"    => "m(:a => 1, :b => 2)")

  add_19tests("hash_new",
              "Ruby"         => "{ a: 1, b: 2 }",
              "ParseTree"    => s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2)),
              "Ruby2Ruby"    => "{ :a => 1, :b => 2 }")

  add_19tests("hash_new_no_space",
              "Ruby"         => "{a:1,b:2}",
              "ParseTree"    => s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2)),
              "Ruby2Ruby"    => "{ :a => 1, :b => 2 }")

  add_19tests("hash_new_with_keyword",
              "Ruby"         => "{ true: 1, b: 2 }",
              "ParseTree"    => s(:hash,
                                  s(:lit, :true), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2)),
              "Ruby2Ruby"    => "{ :true => 1, :b => 2 }")

  add_19tests("if_post_not",
              "Ruby"         => "a if not b",
              "ParseTree"    => s(:if, s(:call, s(:call, nil, :b), :"!"),
                                  s(:call, nil, :a),
                                  nil),
              "Ruby2Ruby"    => "a unless b")

  add_19tests("if_pre_not",
              "Ruby"         => "if not b then a end",
              "ParseTree"    => s(:if, s(:call, s(:call, nil, :b), :"!"),
                                  s(:call, nil, :a),
                                  nil),
              "Ruby2Ruby"    => "a unless b")

  add_19tests("label_in_bare_hash_in_array_in_ternary",
              "Ruby"         => "1 ? [:a, b: 2] : 1",
              "ParseTree"    => s(:if, s(:lit, 1),
                                  s(:array,
                                    s(:lit, :a),
                                    s(:hash, s(:lit, :b), s(:lit, 2))),
                                  s(:lit, 1)),
              "Ruby2Ruby"    => "1 ? ([:a, { :b => 2 }]) : (1)")

  add_19tests("label_in_callargs_in_ternary",
              "Ruby"         => "1 ? m(a: 2) : 1",
              "ParseTree"    => s(:if, s(:lit, 1),
                                  s(:call, nil, :m,
                                    s(:hash, s(:lit, :a), s(:lit, 2))),
                                  s(:lit, 1)),
              "Ruby2Ruby"    => "1 ? (m(:a => 2)) : (1)")

  add_19tests("not",
              "Ruby"         => "(not true)",
              "ParseTree"    => s(:call, s(:true), :"!"))

  add_19tests("splat_fcall_middle",
              "Ruby"         => "meth(1, *[2], 3)",
              "ParseTree"    => s(:call,
                                  nil,
                                  :meth,
                                  s(:lit, 1),
                                  s(:splat, s(:array, s(:lit, 2))),
                                  s(:lit, 3)))

  add_19tests("str_question_control",
              "Ruby"         => '?\M-\C-a',
              "ParseTree"    => s(:str, "\x81"),
              "Ruby2Ruby"    => "\"\\x81\"")

  add_19tests("str_question_escape",
              "Ruby"         => '?\n',
              "ParseTree"    => s(:str, "\n"),
              "Ruby2Ruby"    => "\"\\n\"")

  add_19tests("str_question_literal",
              "Ruby"         => "?a",
              "ParseTree"    => s(:str, "a"),
              "Ruby2Ruby"    => '"a"')

  add_19tests("unless_post_not",
              "Ruby"         => "a unless not b",
              "ParseTree"    => s(:if, s(:call, s(:call, nil, :b), :"!"),
                                  nil,
                                  s(:call, nil, :a)),
              "Ruby2Ruby"    => "a if b")

  add_19tests("unless_pre_not",
              "Ruby"         => "unless not b then a end",
              "ParseTree"    => s(:if, s(:call, s(:call, nil, :b), :"!"),
                                  nil,
                                  s(:call, nil, :a)),
              "Ruby2Ruby"    => "a if b")

  add_19tests("until_post_not",
              "Ruby"         => "begin\n  (1 + 1)\nend until not true",
              "ParseTree"    => s(:until, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), false),
              "Ruby2Ruby"    => "begin\n  (1 + 1)\nend while true")

  add_19tests("until_pre_not",
              "Ruby"         => "until not true do\n  (1 + 1)\nend",
              "ParseTree"    => s(:until, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "while true do\n  (1 + 1)\nend")

  add_19tests("until_pre_not_mod",
              "Ruby"         => "(1 + 1) until not true",
              "ParseTree"    => s(:until, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "while true do\n  (1 + 1)\nend")

  add_19tests("while_post_not",
              "Ruby"         => "begin\n  (1 + 1)\nend while not true",
              "ParseTree"    => s(:while, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), false),
              "Ruby2Ruby"    => "begin\n  (1 + 1)\nend until true")

  add_19tests("while_pre_not",
              "Ruby"         => "while not true do\n  (1 + 1)\nend",
              "ParseTree"    => s(:while, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "until true do\n  (1 + 1)\nend")

  add_19tests("while_pre_not_mod",
              "Ruby"         => "(1 + 1) while not true",
              "ParseTree"    => s(:while, s(:call, s(:true), :"!"),
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
              "Ruby2Ruby"    => "until true do\n  (1 + 1)\nend") # FIX

  ###
  # Shared tests:

  add_tests("alias",
            "Ruby"         => "class X\n  alias :y :x\nend",
            "ParseTree"    => s(:class, :X, nil,
                                s(:alias, s(:lit, :y), s(:lit, :x))))

  add_tests("alias_ugh",
            "Ruby"         => "class X\n  alias y x\nend",
            "ParseTree"    => s(:class, :X, nil,
                                s(:alias, s(:lit, :y), s(:lit, :x))),
            "Ruby2Ruby"    => "class X\n  alias :y :x\nend")

  add_tests("and",
            "Ruby"         => "a and b",
            "ParseTree"    => s(:and,
                                s(:call, nil, :a),
                                s(:call, nil, :b)))

  add_tests("argscat_inside",
            "Ruby"         => "a = [b, *c]",
            "ParseTree"    => s(:lasgn, :a,
                                s(:array,
                                  s(:call, nil, :b),
                                  s(:splat, s(:call, nil, :c)))))

  add_tests("argscat_svalue",
            "Ruby"         => "a = b, c, *d",
            "ParseTree"    => s(:lasgn, :a,
                                s(:svalue,
                                  s(:array,
                                    s(:call, nil, :b),
                                    s(:call, nil, :c),
                                    s(:splat,
                                      s(:call, nil, :d))))))

  add_tests("argspush",
            "Ruby"         => "a[*b] = c",
            "ParseTree"    => s(:attrasgn,
                                s(:call, nil, :a),
                                :[]=,
                                s(:splat,
                                  s(:call, nil, :b)),
                                s(:call, nil, :c)))

  add_tests("array",
            "Ruby"         => "[1, :b, \"c\"]",
            "ParseTree"    => s(:array, s(:lit, 1), s(:lit, :b), s(:str, "c")))

  add_tests("array_pct_W",
            "Ruby"         => "%W[a b c]",
            "ParseTree"    => s(:array,
                                s(:str, "a"), s(:str, "b"), s(:str, "c")),
            "Ruby2Ruby"    => "[\"a\", \"b\", \"c\"]")

  add_tests("array_pct_W_dstr",
            "Ruby"         => "%W[a #\{@b} c]",
            "ParseTree"    => s(:array,
                                s(:str, "a"),
                                s(:dstr, "", s(:evstr, s(:ivar, :@b))),
                                s(:str, "c")),
            "Ruby2Ruby"    => "[\"a\", \"#\{@b}\", \"c\"]")

  add_tests("array_pct_w",
            "Ruby"         => "%w[a b c]",
            "ParseTree"    => s(:array,
                                s(:str, "a"), s(:str, "b"), s(:str, "c")),
            "Ruby2Ruby"    => "[\"a\", \"b\", \"c\"]")

  add_tests("array_pct_w_dstr",
            "Ruby"         => "%w[a #\{@b} c]",
            "ParseTree"    => s(:array,
                                s(:str, "a"),
                                s(:str, "#\{@b}"),
                                s(:str, "c")),
            "Ruby2Ruby"    => "[\"a\", \"\\\#{@b}\", \"c\"]") # TODO: huh?

  add_tests("attrasgn",
            "Ruby"         => "y = 0\n42.method = y\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :y, s(:lit, 0)),
                                s(:attrasgn,
                                  s(:lit, 42), :method=, s(:lvar, :y))))

  add_tests("attrasgn_index_equals",
            "Ruby"         => "a[42] = 24",
            "ParseTree"    => s(:attrasgn,
                                s(:call, nil, :a),
                                :[]=,
                                s(:lit, 42), s(:lit, 24)))

  add_tests("attrasgn_index_equals_space",
            "Ruby"         => "a = []; a [42] = 24",
            "ParseTree"    => s(:block,
                                s(:lasgn, :a, s(:array)),
                                s(:attrasgn, s(:lvar, :a), :[]=,
                                  s(:lit, 42), s(:lit, 24))),
            "Ruby2Ruby"    => "a = []\na[42] = 24\n")

  add_tests("back_ref",
            "Ruby"         => "[$&, $`, $', $+]",
            "ParseTree"    => s(:array,
                                s(:back_ref, :&),
                                s(:back_ref, :"`"),
                                s(:back_ref, :"'"),
                                s(:back_ref, :+)))

  add_tests("begin",
            "Ruby"         => "begin\n  (1 + 1)\nend",
            "ParseTree"    => s(:call, s(:lit, 1), :+, s(:lit, 1)),
            "Ruby2Ruby"    => "(1 + 1)")

  add_tests("begin_def",
            "Ruby"         => "def m\n  begin\n\n  end\nend",
            "ParseTree"    => s(:defn, :m, s(:args), s(:nil)),
            "Ruby2Ruby"    => "def m\n  # do nothing\nend")

  add_tests("begin_rescue_ensure",
            "Ruby"         => "begin\n  a\nrescue\n  # do nothing\nensure\n  # do nothing\nend",
            "ParseTree"    => s(:ensure,
                                s(:rescue,
                                  s(:call, nil, :a),
                                  s(:resbody, s(:array), nil)),
                                s(:nil)))

  add_tests("begin_rescue_ensure_all_empty",
            "Ruby"         => "begin\n  # do nothing\nrescue\n  # do nothing\nensure\n  # do nothing\nend",
            "ParseTree"    => s(:ensure,
                                s(:rescue,
                                  s(:resbody, s(:array), nil)),
                                s(:nil)))

  add_tests("begin_rescue_twice",
            "Ruby"         => "begin\n  a\nrescue => mes\n  # do nothing\nend\nbegin\n  b\nrescue => mes\n  # do nothing\nend\n",
            "ParseTree"    => s(:block,
                                s(:rescue,
                                  s(:call, nil, :a),
                                  s(:resbody,
                                    s(:array, s(:lasgn, :mes, s(:gvar, :$!))),
                                    nil)),
                                s(:rescue,
                                  s(:call, nil, :b),
                                  s(:resbody,
                                    s(:array,
                                      s(:lasgn, :mes, s(:gvar, :$!))),
                                    nil))))
  copy_test_case "begin_rescue_twice", "Ruby"
  copy_test_case "begin_rescue_twice", "ParseTree"

  add_tests("block_attrasgn",
            "Ruby" => "def self.setup(ctx)\n  bind = allocate\n  bind.context = ctx\n  return bind\nend",
            "ParseTree" => s(:defs, s(:self), :setup,
                             s(:args, :ctx),
                             s(:lasgn, :bind, s(:call, nil, :allocate)),
                             s(:attrasgn,
                               s(:lvar, :bind), :context=, s(:lvar, :ctx)),
                             s(:return, s(:lvar, :bind))))

  add_tests("block_lasgn",
            "Ruby"         => "x = (y = 1\n(y + 2))",
            "ParseTree"    => s(:lasgn, :x,
                                s(:block,
                                  s(:lasgn, :y, s(:lit, 1)),
                                  s(:call, s(:lvar, :y), :+, s(:lit, 2)))))

  add_tests("block_mystery_block",
            "Ruby"         => "a(b) do\n  if b then\n    true\n  else\n    c = false\n    d { |x| c = true }\n    c\n  end\nend",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a, s(:call, nil, :b)),
                                0,
                                s(:if,
                                  s(:call, nil, :b),
                                  s(:true),
                                  s(:block,
                                    s(:lasgn, :c, s(:false)),
                                    s(:iter,
                                      s(:call, nil, :d),
                                      s(:args, :x),
                                      s(:lasgn, :c, s(:true))),
                                    s(:lvar, :c)))))

  add_tests("block_pass_args_and_splat",
            "Ruby"         => "def blah(*args, &block)\n  other(42, *args, &block)\nend",
            "ParseTree"    => s(:defn, :blah, s(:args, :"*args", :"&block"),
                                s(:call, nil, :other,
                                  s(:lit, 42),
                                  s(:splat, s(:lvar, :args)),
                                  s(:block_pass, s(:lvar, :block)))))

  add_tests("block_pass_call_0",
            "Ruby"         => "a.b(&c)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :a),
                                :b,
                                s(:block_pass, s(:call, nil, :c))))

  add_tests("block_pass_call_1",
            "Ruby"         => "a.b(4, &c)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :a),
                                :b,
                                s(:lit, 4),
                                s(:block_pass, s(:call, nil, :c))))

  add_tests("block_pass_call_n",
            "Ruby"         => "a.b(1, 2, 3, &c)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :a),
                                :b,
                                s(:lit, 1), s(:lit, 2), s(:lit, 3),
                                s(:block_pass, s(:call, nil, :c))))

  add_tests("block_pass_fcall_0",
            "Ruby"         => "a(&b)",
            "ParseTree"    => s(:call, nil, :a,
                                s(:block_pass, s(:call, nil, :b))))

  add_tests("block_pass_fcall_1",
            "Ruby"         => "a(4, &b)",
            "ParseTree"    => s(:call, nil, :a,
                                s(:lit, 4),
                                s(:block_pass, s(:call, nil, :b))))

  add_tests("block_pass_fcall_n",
            "Ruby"         => "a(1, 2, 3, &b)",
            "ParseTree"    => s(:call, nil, :a,
                                s(:lit, 1), s(:lit, 2), s(:lit, 3),
                                s(:block_pass, s(:call, nil, :b))))

  add_tests("block_pass_omgwtf",
            "Ruby"         => "define_attr_method(:x, :sequence_name, &Proc.new { |*args| nil })",
            "ParseTree"    => s(:call, nil, :define_attr_method,
                                s(:lit, :x),
                                s(:lit, :sequence_name),
                                s(:block_pass,
                                  s(:iter,
                                    s(:call, s(:const, :Proc), :new),
                                    s(:args, :"*args"),
                                    s(:nil)))))

  add_tests("block_pass_splat",
            "Ruby"         => "def blah(*args, &block)\n  other(*args, &block)\nend",
            "ParseTree"    => s(:defn, :blah,
                                s(:args, :"*args", :"&block"),
                                s(:call, nil, :other,
                                  s(:splat, s(:lvar, :args)),
                                  s(:block_pass, s(:lvar, :block)))))

  add_tests("block_pass_thingy",
            "Ruby"         => "r.read_body(dest, &block)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :r),
                                :read_body,
                                s(:call, nil, :dest),
                                s(:block_pass, s(:call, nil, :block))))

  add_tests("block_stmt_after",
            "Ruby"         => "def f\n  begin\n    b\n  rescue\n    c\n  end\n\n  d\nend",
            "ParseTree"    => s(:defn, :f, s(:args),
                                s(:rescue,
                                  s(:call, nil, :b),
                                  s(:resbody,
                                    s(:array),
                                    s(:call, nil, :c))),
                                s(:call, nil, :d)),
            "Ruby2Ruby"    => "def f\n  b rescue c\n  d\nend")
  copy_test_case "block_stmt_after", "Ruby"
  copy_test_case "block_stmt_after", "ParseTree"
  copy_test_case "block_stmt_after", "Ruby2Ruby"

  add_tests("block_stmt_before",
            "Ruby"         => "def f\n  a\n  begin\n    b\n  rescue\n    c\n  end\nend",
            "ParseTree"    => s(:defn, :f, s(:args),
                                s(:call, nil, :a),
                                s(:rescue, s(:call, nil, :b),
                                  s(:resbody,
                                    s(:array),
                                    s(:call, nil, :c)))),
            "Ruby2Ruby"    => "def f\n  a\n  b rescue c\nend")
  # oddly... this one doesn't HAVE any differences when verbose... new?
  copy_test_case "block_stmt_before", "Ruby"
  copy_test_case "block_stmt_before", "ParseTree"
  copy_test_case "block_stmt_before", "Ruby2Ruby"

  add_tests("block_stmt_both",
            "Ruby"         => "def f\n  a\n  begin\n    b\n  rescue\n    c\n  end\n  d\nend",
            "ParseTree"    => s(:defn, :f, s(:args),
                                s(:call, nil, :a),
                                s(:rescue,
                                  s(:call, nil, :b),
                                  s(:resbody,
                                    s(:array),
                                    s(:call, nil, :c))),
                                s(:call, nil, :d)),
            "Ruby2Ruby"    => "def f\n  a\n  b rescue c\n  d\nend")
  copy_test_case "block_stmt_both", "Ruby"
  copy_test_case "block_stmt_both", "ParseTree"
  copy_test_case "block_stmt_both", "Ruby2Ruby"

  add_tests("bmethod",
            "Ruby"         => [Examples, :unsplatted],
            "ParseTree"    => s(:defn, :unsplatted, s(:args, :x),
                                s(:call, s(:lvar, :x), :+, s(:lit, 1))),
            "Ruby2Ruby"    => "def unsplatted(x)\n  (x + 1)\nend")

  add_tests("bmethod_noargs",
            "Ruby"         => [Examples, :bmethod_noargs],
            "ParseTree"    => s(:defn, :bmethod_noargs, s(:args),
                                s(:call,
                                  s(:call, nil, :x),
                                  :"+",
                                  s(:lit, 1))),
            "Ruby2Ruby"    => "def bmethod_noargs\n  (x + 1)\nend")

  add_tests("bmethod_splat",
            "Ruby"         => [Examples, :splatted],
            "ParseTree"    => s(:defn, :splatted, s(:args, :"*args"),
                                s(:lasgn, :y,
                                  s(:call, s(:lvar, :args), :first)),
                                s(:call, s(:lvar, :y), :+, s(:lit, 42))),
            "Ruby2Ruby"    => "def splatted(*args)\n  y = args.first\n  (y + 42)\nend")

  add_tests("break",
            "Ruby"         => "loop { break if true }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :loop),
                                0,
                                s(:if, s(:true), s(:break), nil)))

  add_tests("break_arg",
            "Ruby"         => "loop { break 42 if true }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :loop),
                                0,
                                s(:if, s(:true), s(:break, s(:lit, 42)), nil)))

  add_tests("call",
            "Ruby"         => "self.method",
            "ParseTree"    => s(:call, s(:self), :method))

  add_tests("call_arglist",
            "Ruby"         => "o.puts(42)",
            "ParseTree"    => s(:call, s(:call, nil, :o), :puts, s(:lit, 42)))

  add_tests("call_arglist_hash",
            "Ruby"         => "o.m(:a => 1, :b => 2)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :o), :m,
                                s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2))))

  add_tests("call_arglist_norm_hash",
            "Ruby"         => "o.m(42, :a => 1, :b => 2)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :o), :m,
                                s(:lit, 42),
                                s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2))))

  add_tests("call_command",
            "Ruby"         => "1.b(c)",
            "ParseTree"    => s(:call,
                                s(:lit, 1),
                                :b,
                                s(:call, nil, :c)))

  add_tests("call_expr",
            "Ruby"         => "(v = (1 + 1)).zero?",
            "ParseTree"    => s(:call,
                                s(:lasgn, :v,
                                  s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                :zero?))

  add_tests("call_index",
            "Ruby"         => "a = []\na[42]\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :a, s(:array)),
                                s(:call, s(:lvar, :a), :[], s(:lit, 42))))

  add_tests("call_index_no_args",
            "Ruby"         => "a[]",
            "ParseTree"    => s(:call, s(:call, nil, :a),
                                :[]))

  add_tests("call_index_space",
            "Ruby"         => "a = []\na [42]\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :a, s(:array)),
                                s(:call, s(:lvar, :a), :[], s(:lit, 42))),
            "Ruby2Ruby"    => "a = []\na[42]\n")

  add_tests("call_no_space_symbol",
            "Ruby"         => "foo:bar",
            "ParseTree"    => s(:call, nil, :foo, s(:lit, :bar)),
            "Ruby2Ruby"    => "foo(:bar)")

  add_tests("call_unary_neg",
            "Ruby"         => "-2**31",
            "ParseTree"    => s(:call,
                                s(:call, s(:lit, 2), :**, s(:lit, 31)),
                                :-@),
            "Ruby2Ruby"    => "-(2 ** 31)")

  add_tests("case",
            "Ruby"         => "var = 2\nresult = \"\"\ncase var\nwhen 1 then\n  puts(\"something\")\n  result = \"red\"\nwhen 2, 3 then\n  result = \"yellow\"\nwhen 4 then\n  # do nothing\nelse\n  result = \"green\"\nend\ncase result\nwhen \"red\" then\n  var = 1\nwhen \"yellow\" then\n  var = 2\nwhen \"green\" then\n  var = 3\nend\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :var, s(:lit, 2)),
                                s(:lasgn, :result, s(:str, "")),
                                s(:case,
                                  s(:lvar, :var),
                                  s(:when,
                                    s(:array, s(:lit, 1)),
                                    s(:call, nil, :puts, s(:str, "something")),
                                    s(:lasgn, :result, s(:str, "red"))),
                                  s(:when,
                                    s(:array, s(:lit, 2), s(:lit, 3)),
                                    s(:lasgn, :result, s(:str, "yellow"))),
                                  s(:when, s(:array, s(:lit, 4)), nil),
                                  s(:lasgn, :result, s(:str, "green"))),
                                s(:case,
                                  s(:lvar, :result),
                                  s(:when, s(:array, s(:str, "red")),
                                    s(:lasgn, :var, s(:lit, 1))),
                                  s(:when, s(:array, s(:str, "yellow")),
                                    s(:lasgn, :var, s(:lit, 2))),
                                  s(:when, s(:array, s(:str, "green")),
                                    s(:lasgn, :var, s(:lit, 3))),
                                  nil)))

  add_tests("case_nested",
            "Ruby"         => "var1 = 1\nvar2 = 2\nresult = nil\ncase var1\nwhen 1 then\n  case var2\n  when 1 then\n    result = 1\n  when 2 then\n    result = 2\n  else\n    result = 3\n  end\nwhen 2 then\n  case var2\n  when 1 then\n    result = 4\n  when 2 then\n    result = 5\n  else\n    result = 6\n  end\nelse\n  result = 7\nend\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :var1, s(:lit, 1)),
                                s(:lasgn, :var2, s(:lit, 2)),
                                s(:lasgn, :result, s(:nil)),
                                s(:case,
                                  s(:lvar, :var1),
                                  s(:when, s(:array, s(:lit, 1)),
                                    s(:case,
                                      s(:lvar, :var2),
                                      s(:when, s(:array, s(:lit, 1)),
                                        s(:lasgn, :result, s(:lit, 1))),
                                      s(:when, s(:array, s(:lit, 2)),
                                        s(:lasgn, :result, s(:lit, 2))),
                                      s(:lasgn, :result, s(:lit, 3)))),
                                  s(:when, s(:array, s(:lit, 2)),
                                    s(:case,
                                      s(:lvar, :var2),
                                      s(:when, s(:array, s(:lit, 1)),
                                        s(:lasgn, :result, s(:lit, 4))),
                                      s(:when, s(:array, s(:lit, 2)),
                                        s(:lasgn, :result, s(:lit, 5))),
                                      s(:lasgn, :result, s(:lit, 6)))),
                                  s(:lasgn, :result, s(:lit, 7)))))

  add_tests("case_nested_inner_no_expr",
            "Ruby"         => "case a\nwhen b then\n  case\n  when (d and e) then\n    f\n  end\nend",
            "ParseTree"    => s(:case, s(:call, nil, :a),
                                s(:when,
                                  s(:array, s(:call, nil, :b)),
                                  s(:case, nil,
                                    s(:when,
                                      s(:array,
                                        s(:and,
                                          s(:call, nil, :d),
                                          s(:call, nil, :e))),
                                      s(:call, nil, :f)),
                                    nil)),
                                nil))

  add_tests("case_no_expr",
            "Ruby"         => "case\nwhen (a == 1) then\n  :a\nwhen (a == 2) then\n  :b\nelse\n  :c\nend",
            "ParseTree"    => s(:case, nil,
                                s(:when,
                                  s(:array,
                                    s(:call,
                                      s(:call, nil, :a),
                                      :==,
                                      s(:lit, 1))),
                                  s(:lit, :a)),
                                s(:when,
                                  s(:array,
                                    s(:call,
                                      s(:call, nil, :a),
                                      :==,
                                      s(:lit, 2))),
                                  s(:lit, :b)),
                                s(:lit, :c)))

  add_tests("case_splat",
            "Ruby"         => "case a\nwhen :b, *c then\n  d\nelse\n  e\nend",
            "ParseTree"    => s(:case, s(:call, nil, :a),
                                s(:when,
                                  s(:array,
                                    s(:lit, :b),
                                    s(:splat, s(:call, nil, :c))),
                                  s(:call, nil, :d)),
                                s(:call, nil, :e)))

  add_tests("cdecl",
            "Ruby"         => "X = 42",
            "ParseTree"    => s(:cdecl, :X, s(:lit, 42)))

  add_tests("class_plain",
            "Ruby"         => "class X\n  puts((1 + 1))\n  \n  def blah\n    puts(\"hello\")\n  end\nend",
            "ParseTree"    => s(:class, :X, nil,
                                s(:call, nil, :puts,
                                  s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                s(:defn, :blah, s(:args),
                                  s(:call, nil, :puts, s(:str, "hello")))))

  add_tests("class_scoped",
            "Ruby"         => "class X::Y\n  c\nend",
            "ParseTree"    => s(:class, s(:colon2, s(:const, :X), :Y), nil,
                                s(:call, nil, :c)))

  add_tests("class_scoped3",
            "Ruby"         => "class ::Y\n  c\nend",
            "ParseTree"    => s(:class, s(:colon3, :Y), nil,
                                s(:call, nil, :c)))

  add_tests("class_super_array",
            "Ruby"         => "class X < Array\nend",
            "ParseTree"    => s(:class, :X, s(:const, :Array)))

  add_tests("class_super_expr",
            "Ruby"         => "class X < expr\nend",
            "ParseTree"    => s(:class, :X, s(:call, nil, :expr)))

  add_tests("class_super_object",
            "Ruby"         => "class X < Object\nend",
            "ParseTree"    => s(:class, :X, s(:const, :Object)))

  add_tests("colon2",
            "Ruby"         => "X::Y",
            "ParseTree"    => s(:colon2, s(:const, :X), :Y))

  add_tests("colon3",
            "Ruby"         => "::X",
            "ParseTree"    => s(:colon3, :X))

  add_tests("const",
            "Ruby"         => "X",
            "ParseTree"    => s(:const, :X))

  add_tests("constX",
            "Ruby"         => "X = 1",
            "ParseTree"    => s(:cdecl, :X, s(:lit, 1)))

  add_tests("constY",
            "Ruby"         => "::X = 1",
            "ParseTree"    => s(:cdecl, s(:colon3, :X), s(:lit, 1)))

  add_tests("constZ",
            "Ruby"         => "X::Y = 1",
            "ParseTree"    => s(:cdecl,
                                s(:colon2, s(:const, :X), :Y),
                                s(:lit, 1)))

  add_tests("cvar",
            "Ruby"         => "@@x",
            "ParseTree"    => s(:cvar, :@@x))

  add_tests("cvasgn",
            "Ruby"         => "def x\n  @@blah = 1\nend",
            "ParseTree"    => s(:defn, :x, s(:args),
                                s(:cvasgn, :@@blah, s(:lit, 1))))

  add_tests("cvasgn_cls_method",
            "Ruby"         => "def self.quiet_mode=(boolean)\n  @@quiet_mode = boolean\nend",
            "ParseTree"    => s(:defs, s(:self), :quiet_mode=,
                                s(:args, :boolean),
                                s(:cvasgn, :@@quiet_mode,
                                  s(:lvar, :boolean))))

  add_tests("cvdecl",
            "Ruby"         => "class X\n  @@blah = 1\nend",
            "ParseTree"    => s(:class, :X, nil,
                                s(:cvdecl, :@@blah, s(:lit, 1))))

  add_tests("dasgn_0",
            "Ruby"         => "a.each { |x| b.each { |y| x = (x + 1) } if true }",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :a), :each),
                                s(:args, :x),
                                s(:if, s(:true),
                                  s(:iter,
                                    s(:call, s(:call, nil, :b), :each),
                                    s(:args, :y),
                                    s(:lasgn, :x,
                                      s(:call, s(:lvar, :x), :+, s(:lit, 1)))),
                                  nil)))

  add_tests("dasgn_1",
            "Ruby"         => "a.each { |x| b.each { |y| c = (c + 1) } if true }",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :a), :each),
                                s(:args, :x),
                                s(:if, s(:true),
                                  s(:iter,
                                    s(:call, s(:call, nil, :b), :each),
                                    s(:args, :y),
                                    s(:lasgn, :c,
                                      s(:call, s(:lvar, :c), :+, s(:lit, 1)))),
                                  nil)))

  add_tests("dasgn_2",
            "Ruby"         => "a.each do |x|\n  if true then\n    c = 0\n    b.each { |y| c = (c + 1) }\n  end\nend",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :a), :each),
                                s(:args, :x),
                                s(:if, s(:true),
                                  s(:block,
                                    s(:lasgn, :c, s(:lit, 0)),
                                    s(:iter,
                                      s(:call, s(:call, nil, :b), :each),
                                      s(:args, :y),
                                      s(:lasgn, :c,
                                        s(:call, s(:lvar, :c), :+,
                                          s(:lit, 1))))),
                                  nil)))

  add_tests("dasgn_curr",
            "Ruby"         => "data.each do |x, y|\n  a = 1\n  b = a\n  b = a = x\nend",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :data), :each),
                                s(:args, :x, :y),
                                s(:block,
                                  s(:lasgn, :a, s(:lit, 1)),
                                  s(:lasgn, :b, s(:lvar, :a)),
                                  s(:lasgn, :b, s(:lasgn, :a, s(:lvar, :x))))))

  add_tests("dasgn_icky",
            "Ruby"         => "a do\n  v = nil\n  assert_block(full_message) do\n    begin\n      yield\n    rescue Exception => v\n      break\n    end\n  end\nend",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                0,
                                s(:block,
                                  s(:lasgn, :v, s(:nil)),
                                  s(:iter,
                                    s(:call, nil, :assert_block,
                                      s(:call, nil, :full_message)),
                                    0,
                                    s(:rescue,
                                      s(:yield),
                                      s(:resbody,
                                        s(:array,
                                          s(:const, :Exception),
                                          s(:lasgn, :v, s(:gvar, :$!))),
                                        s(:break)))))))

  add_tests("dasgn_mixed",
            "Ruby"         => "t = 0\nns.each { |n| t += n }\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :t, s(:lit, 0)),
                                s(:iter,
                                  s(:call, s(:call, nil, :ns), :each),
                                  s(:args, :n),
                                  s(:lasgn, :t,
                                    s(:call, s(:lvar, :t), :+, s(:lvar, :n))))),
            "Ruby2Ruby"    => "t = 0\nns.each { |n| t = (t + n) }\n")

  add_tests("defined",
            "Ruby"         => "defined? $x",
            "ParseTree"    => s(:defined, s(:gvar, :$x)))

  add_tests("defn_args_block", # TODO: make all the defn_args* p their arglist
            "Ruby"         => "def f(&block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f, s(:args, :"&block"),
                                s(:nil)))

  add_tests("defn_args_mand",
            "Ruby"         => "def f(mand)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f, s(:args, :mand),
                                s(:nil)))

  add_tests("defn_args_mand_block",
            "Ruby"         => "def f(mand, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f, s(:args, :mand, :"&block"),
                                 s(:nil)))

  add_tests("defn_args_mand_opt",
            "Ruby"         => "def f(mand, opt = 42)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, s(:lasgn, :opt, s(:lit, 42))),
                                s(:nil)))

  add_tests("defn_args_mand_opt_block",
            "Ruby"         => "def f(mand, opt = 42, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, s(:lasgn, :opt, s(:lit, 42)), :"&block"),
                                s(:nil)))

  add_tests("defn_args_mand_opt_splat",
            "Ruby"         => "def f(mand, opt = 42, *rest)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, s(:lasgn, :opt, s(:lit, 42)), :"*rest"),
                                s(:nil)))

  add_tests("defn_args_mand_opt_splat_block",
            "Ruby"         => "def f(mand, opt = 42, *rest, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, s(:lasgn, :opt, s(:lit, 42)), :"*rest", :"&block"),
                                s(:nil)))

  add_tests("defn_args_mand_opt_splat_no_name",
            "Ruby"         => "def x(a, b = 42, *)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :x,
                                s(:args, :a, s(:lasgn, :b, s(:lit, 42)), :"*"),
                                s(:nil)))

  add_tests("defn_args_mand_splat",
            "Ruby"         => "def f(mand, *rest)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, :"*rest"),
                                s(:nil)))

  add_tests("defn_args_mand_splat_block",
            "Ruby"         => "def f(mand, *rest, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, :mand, :"*rest", :"&block"),
                                s(:nil)))

  add_tests("defn_args_mand_splat_no_name",
            "Ruby"         => "def x(a, *args)\n  p(a, args)\nend",
            "ParseTree"    => s(:defn, :x, s(:args, :a, :"*args"),
                                s(:call, nil, :p,
                                  s(:lvar, :a), s(:lvar, :args))))

  add_tests("defn_args_none",
            "Ruby"         => "def empty\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :empty, s(:args),
                                s(:nil)))

  add_tests("defn_args_opt",
            "Ruby"         => "def f(opt = 42)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, s(:lasgn, :opt, s(:lit, 42))),
                                s(:nil)))

  add_tests("defn_args_opt_block",
            "Ruby"         => "def f(opt = 42, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, s(:lasgn, :opt, s(:lit, 42)), :"&block"),
                                s(:nil)))

  add_tests("defn_args_opt_splat",
            "Ruby"         => "def f(opt = 42, *rest)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args, s(:lasgn, :opt, s(:lit, 42)), :"*rest"),
                                s(:nil)))

  add_tests("defn_args_opt_splat_block",
            "Ruby"         => "def f(opt = 42, *rest, &block)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f,
                                s(:args,
                                  s(:lasgn, :opt, s(:lit, 42)),
                                  :"*rest", :"&block"),
                                s(:nil)))

  add_tests("defn_args_opt_splat_no_name",
            "Ruby"         => "def x(b = 42, *)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :x,
                                s(:args, s(:lasgn, :b, s(:lit, 42)), :"*"),
                                s(:nil)))

  add_tests("defn_args_splat",
            "Ruby"         => "def f(*rest)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :f, s(:args, :"*rest"),
                                s(:nil)))

  add_tests("defn_args_splat_no_name",
            "Ruby"         => "def x(*)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :x, s(:args, :"*"),
                                s(:nil)))

  add_tests("defn_or",
            "Ruby"         => "def |(o)\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :|, s(:args, :o),
                                s(:nil)))

  add_tests("defn_rescue",
            "Ruby"         => "def eql?(resource)\n  (self.uuid == resource.uuid)\nrescue\n  false\nend",
            "ParseTree"    => s(:defn, :eql?,
                                s(:args, :resource),
                                s(:rescue,
                                  s(:call,
                                    s(:call, s(:self), :uuid),
                                    :==,
                                    s(:call, s(:lvar, :resource), :uuid)),
                                  s(:resbody, s(:array), s(:false)))),
            "Ruby2Ruby"    => "def eql?(resource)\n  (self.uuid == resource.uuid) rescue false\nend")

  add_tests("defn_rescue_mri_verbose_flag",
            "Ruby"         => "def eql?(resource)\n  (self.uuid == resource.uuid)\nrescue\n  false\nend",
            "ParseTree"    => s(:defn, :eql?,
                                s(:args, :resource),
                                s(:rescue,
                                  s(:call,
                                    s(:call, s(:self), :uuid),
                                    :==,
                                    s(:call, s(:lvar, :resource), :uuid)),
                                  s(:resbody, s(:array), s(:false)))),
            "Ruby2Ruby"    => "def eql?(resource)\n  (self.uuid == resource.uuid) rescue false\nend")

  add_tests("defn_something_eh",
            "Ruby"         => "def something?\n  # do nothing\nend",
            "ParseTree"    => s(:defn, :something?,
                                s(:args),
                                s(:nil)))

  add_tests("defn_splat_no_name",
            "Ruby"         => "def x(a, *)\n  p(a)\nend",
            "ParseTree"    => s(:defn, :x,
                                s(:args, :a, :"*"),
                                s(:call, nil, :p, s(:lvar, :a))))

  add_tests("defn_zarray",
            "Ruby"         => "def zarray\n  a = []\n  return a\nend",
            "ParseTree"    => s(:defn, :zarray,
                                s(:args),
                                s(:lasgn, :a, s(:array)),
                                s(:return, s(:lvar, :a))))

  add_tests("defs",
            "Ruby"         => "def self.x(y)\n  (y + 1)\nend",
            "ParseTree"    => s(:defs, s(:self), :x,
                                s(:args, :y),
                                s(:call, s(:lvar, :y), :+, s(:lit, 1))))

  add_tests("defs_empty",
            "Ruby"         => "def self.empty\n  # do nothing\nend",
            "ParseTree"    => s(:defs, s(:self), :empty, s(:args), s(:nil)))

  add_tests("defs_empty_args",
            "Ruby"         => "def self.empty(*)\n  # do nothing\nend",
            "ParseTree"    => s(:defs, s(:self), :empty,
                                s(:args, :*),
                                s(:nil)))

  add_tests("defs_expr_wtf",
            "Ruby"         => "def (a.b).empty(*)\n  # do nothing\nend",
            "ParseTree"    => s(:defs,
                                s(:call, s(:call, nil, :a), :b),
                                :empty,
                                s(:args, :*),
                                s(:nil)))

  add_tests("dmethod",
            "Ruby"         => [Examples, :dmethod_added],
            "ParseTree"    => s(:defn, :dmethod_added,
                                s(:args, :x),
                                s(:call, s(:lvar, :x), :+, s(:lit, 1))),
            "Ruby2Ruby"    => "def dmethod_added(x)\n  (x + 1)\nend")

  add_tests("dot2",
            "Ruby"         => "(a..b)",
            "ParseTree"    => s(:dot2,
                                s(:call, nil, :a),
                                s(:call, nil, :b)))

  add_tests("dot3",
            "Ruby"         => "(a...b)",
            "ParseTree"    => s(:dot3,
                                s(:call, nil, :a),
                                s(:call, nil, :b)))

  add_tests("dregx",
            "Ruby"         => "/x#\{(1 + 1)}y/",
            "ParseTree"    => s(:dregx, "x",
                                s(:evstr,
                                  s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                s(:str, "y")))

  add_tests("dregx_interp",
            "Ruby"         => "/#\{@rakefile}/",
            "ParseTree"    => s(:dregx, "", s(:evstr, s(:ivar, :@rakefile))))

  add_tests("dregx_interp_empty",
            "Ruby"         => "/a#\{}b/",
            "ParseTree"    => s(:dregx, "a", s(:evstr), s(:str, "b")))

  add_tests("dregx_n",
            "Ruby"         => '/#{1}/n',
            "ParseTree"    => s(:dregx, "",
                                s(:evstr, s(:lit, 1)), /x/n.options))

  add_tests("dregx_once",
            "Ruby"         => "/x#\{(1 + 1)}y/o",
            "ParseTree"    => s(:dregx_once, "x",
                                s(:evstr,
                                  s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                s(:str, "y")))

  add_tests("dregx_once_n_interp",
            "Ruby"         => "/#\{IAC}#\{SB}/no",
            "ParseTree"    => s(:dregx_once, "",
                                s(:evstr, s(:const, :IAC)),
                                s(:evstr, s(:const, :SB)), /x/n.options))

  add_tests("dstr",
            "Ruby"         => "argl = 1\n\"x#\{argl}y\"\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :argl, s(:lit, 1)),
                                s(:dstr, "x", s(:evstr, s(:lvar, :argl)),
                                  s(:str, "y"))))

  add_tests("dstr_2",
            "Ruby"         => "argl = 1\n\"x#\{(\"%.2f\" % 3.14159)}y\"\n",
            "ParseTree"    =>   s(:block,
                                  s(:lasgn, :argl, s(:lit, 1)),
                                  s(:dstr,
                                    "x",
                                    s(:evstr,
                                      s(:call, s(:str, "%.2f"), :%,
                                        s(:lit, 3.14159))),
                                    s(:str, "y"))))

  add_tests("dstr_3",
            "Ruby"         => "max = 2\nargl = 1\n\"x#\{(\"%.#\{max}f\" % 3.14159)}y\"\n",
            "ParseTree"    =>   s(:block,
                                  s(:lasgn, :max, s(:lit, 2)),
                                  s(:lasgn, :argl, s(:lit, 1)),
                                  s(:dstr, "x",
                                    s(:evstr,
                                      s(:call,
                                        s(:dstr, "%.",
                                          s(:evstr, s(:lvar, :max)),
                                          s(:str, "f")),
                                        :%,
                                        s(:lit, 3.14159))),
                                    s(:str, "y"))))

  add_tests("dstr_concat",
            "Ruby"         => '"#{22}aa" "cd#{44}" "55" "#{66}"',
            "ParseTree"    => s(:dstr,
                                "",
                                s(:evstr, s(:lit, 22)),
                                s(:str, "aa"),
                                s(:str, "cd"),
                                s(:evstr, s(:lit, 44)),
                                s(:str, "55"),
                                s(:evstr, s(:lit, 66))),
            "Ruby2Ruby"    => '"#{22}aacd#{44}55#{66}"')

  add_tests("dstr_gross",
            "Ruby"         => '"a #$global b #@ivar c #@@cvar d"',
            "ParseTree"    => s(:dstr, "a ",
                                s(:evstr, s(:gvar, :$global)),
                                s(:str, " b "),
                                s(:evstr, s(:ivar, :@ivar)),
                                s(:str, " c "),
                                s(:evstr, s(:cvar, :@@cvar)),
                                s(:str, " d")),
            "Ruby2Ruby" => '"a #{$global} b #{@ivar} c #{@@cvar} d"')

  add_tests("dstr_heredoc_expand",
            "Ruby"         => "<<EOM\n  blah\n#\{1 + 1}blah\nEOM\n",
            "ParseTree"    => s(:dstr, "  blah\n",
                                s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                s(:str, "blah\n")),
            "Ruby2Ruby"    => "\"  blah\\n#\{(1 + 1)}blah\\n\"")

  add_tests("dstr_heredoc_windoze_sucks",
            "Ruby"         => "<<-EOF\r\ndef test_#\{action}_valid_feed\r\n  EOF\r\n",
            "ParseTree"    => s(:dstr,
                                "def test_",
                                s(:evstr, s(:call, nil, :action)),
                                s(:str, "_valid_feed\n")),
            "Ruby2Ruby"    => "\"def test_#\{action}_valid_feed\\n\"")

  add_tests("dstr_heredoc_yet_again",
            "Ruby"         => "<<-EOF\ns1 '#\{RUBY_PLATFORM}' s2\n#\{__FILE__}\n        EOF\n",
            "ParseTree"    => s(:dstr, "s1 '",
                                s(:evstr, s(:const, :RUBY_PLATFORM)),
                                s(:str, "' s2\n"),
                                s(:str, "(string)"),
                                s(:str, "\n")),
            "Ruby2Ruby"    => "\"s1 '#\{RUBY_PLATFORM}' s2\\n(string)\\n\"")

  add_tests("dstr_nest",
            "Ruby"         => "%Q[before [#\{nest}] after]",
            "ParseTree"    => s(:dstr, "before [",
                                s(:evstr, s(:call, nil, :nest)),
                                s(:str, "] after")),
            "Ruby2Ruby"    => "\"before [#\{nest}] after\"")

  add_tests("dstr_str_lit_start",
            "Ruby"         => '"#{"blah"}#{__FILE__}:#{__LINE__}: warning: #{$!.message} (#{$!.class})"',
            "ParseTree"    => s(:dstr,
                                "blah(string):",
                                s(:evstr, s(:lit, 1)),
                                s(:str, ": warning: "),
                                s(:evstr, s(:call, s(:gvar, :$!), :message)),
                                s(:str, " ("),
                                s(:evstr, s(:call, s(:gvar, :$!), :class)),
                                s(:str, ")")),
            "Ruby2Ruby"    => '"blah(string):#{1}: warning: #{$!.message} (#{$!.class})"')

  add_tests("dstr_the_revenge",
            "Ruby"         => '"before #{from} middle #{to} (#{__FILE__}:#{__LINE__})"',
            "ParseTree"    => s(:dstr,
                                "before ",
                                s(:evstr, s(:call, nil, :from)),
                                s(:str, " middle "),
                                s(:evstr, s(:call, nil, :to)),
                                s(:str, " ("),
                                s(:str, "(string)"),
                                s(:str, ":"),
                                s(:evstr, s(:lit, 1)),
                                s(:str, ")")),
            "Ruby2Ruby"    => '"before #{from} middle #{to} ((string):#{1})"')

  add_tests("dsym",
            "Ruby"         => ":\"x#\{(1 + 1)}y\"",
            "ParseTree"    => s(:dsym, "x",
                                s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1))),
                                s(:str, "y")))

  add_tests("dxstr",
            "Ruby"         => "t = 5\n`touch #\{t}`\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :t, s(:lit, 5)),
                                s(:dxstr, "touch ", s(:evstr, s(:lvar, :t)))))

  add_tests("ensure",
            "Ruby"         => "begin\n  (1 + 1)\nrescue SyntaxError => e1\n  2\nrescue Exception => e2\n  3\nelse\n  4\nensure\n  5\nend",
            "ParseTree"    => s(:ensure,
                                s(:rescue,
                                  s(:call, s(:lit, 1), :+, s(:lit, 1)),
                                  s(:resbody,
                                    s(:array,
                                      s(:const, :SyntaxError),
                                      s(:lasgn, :e1, s(:gvar, :$!))),
                                    s(:lit, 2)),
                                  s(:resbody,
                                    s(:array,
                                      s(:const, :Exception),
                                      s(:lasgn, :e2, s(:gvar, :$!))),
                                    s(:lit, 3)),
                                  s(:lit, 4)),
                                s(:lit, 5)))

  add_tests("false",
            "Ruby"         => "false",
            "ParseTree"    => s(:false))

  add_tests("fbody",
            "Ruby"         => [Examples, :an_alias],
            "ParseTree"    => s(:defn, :an_alias, s(:args, :x),
                                s(:call, s(:lvar, :x), :+, s(:lit, 1))),
            "Ruby2Ruby"    => "def an_alias(x)\n  (x + 1)\nend")

  add_tests("fcall_arglist",
            "Ruby"         => "m(42)",
            "ParseTree"    => s(:call, nil, :m, s(:lit, 42)))

  add_tests("fcall_arglist_hash",
            "Ruby"         => "m(:a => 1, :b => 2)",
            "ParseTree"    => s(:call, nil, :m,
                                s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2))))

  add_tests("fcall_arglist_norm_hash",
            "Ruby"         => "m(42, :a => 1, :b => 2)",
            "ParseTree"    => s(:call, nil, :m,
                                s(:lit, 42),
                                s(:hash,
                                  s(:lit, :a), s(:lit, 1),
                                  s(:lit, :b), s(:lit, 2))))

  add_tests("fcall_block",
            "Ruby"         => "a(:b) { :c }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a, s(:lit, :b)),
                                0,
                                s(:lit, :c)))

  add_tests("fcall_index_space",
            "Ruby"         => "a [42]",
            "ParseTree"    => s(:call, nil, :a, s(:array, s(:lit, 42))),
            "Ruby2Ruby"    => "a([42])")

  add_tests("fcall_inside_parens",
            "Ruby"         => "( a (b), c)",
            "ParseTree"    => s(:call, nil, :a,
                                s(:call, nil, :b), s(:call, nil, :c)),
            "Ruby2Ruby"    => "a(b, c)")

  add_tests("fcall_keyword",
            "Ruby"         => "42 if block_given?",
            "ParseTree"    => s(:if,
                                s(:call, nil, :block_given?),
                                s(:lit, 42), nil))

  add_tests("flip2",
            "Ruby"         => "x = if ((i % 4) == 0)..((i % 3) == 0) then\n  i\nelse\n  nil\nend",
            "ParseTree"    => s(:lasgn,
                                :x,
                                s(:if,
                                  s(:flip2,
                                    s(:call,
                                      s(:call, s(:call, nil, :i),
                                        :%,
                                        s(:lit, 4)),
                                      :==,
                                      s(:lit, 0)),
                                    s(:call,
                                      s(:call, s(:call, nil, :i),
                                        :%,
                                        s(:lit, 3)),
                                      :==,
                                      s(:lit, 0))),
                                  s(:call, nil, :i),
                                  s(:nil))))

  add_tests("flip2_method",
            "Ruby"         => "if 1..2.a?(b) then\n  nil\nend",
            "ParseTree"    => s(:if,
                                s(:flip2,
                                  s(:lit, 1),
                                  s(:call, s(:lit, 2), :a?, s(:call, nil, :b))),
                                s(:nil),
                                nil))

  add_tests("flip3",
            "Ruby"         => "x = if ((i % 4) == 0)...((i % 3) == 0) then\n  i\nelse\n  nil\nend",
            "ParseTree"    => s(:lasgn,
                                :x,
                                s(:if,
                                  s(:flip3,
                                    s(:call,
                                      s(:call, s(:call, nil, :i),
                                        :%,
                                        s(:lit, 4)),
                                      :==,
                                      s(:lit, 0)),
                                    s(:call,
                                      s(:call, s(:call, nil, :i),
                                        :%,
                                        s(:lit, 3)),
                                      :==,
                                      s(:lit, 0))),
                                  s(:call, nil, :i),
                                  s(:nil))))

  add_tests("for",
            "Ruby"         => "for o in ary do\n  puts(o)\nend",
            "ParseTree"    => s(:for,
                                s(:call, nil, :ary),
                                s(:lasgn, :o),
                                s(:call, nil, :puts, s(:lvar, :o))))

  add_tests("for_no_body",
            "Ruby"         => "for i in (0..max) do\n  # do nothing\nend",
            "ParseTree"    => s(:for,
                                s(:dot2,
                                  s(:lit, 0),
                                  s(:call, nil, :max)),
                                s(:lasgn, :i)))

  add_tests("gasgn",
            "Ruby"         => "$x = 42",
            "ParseTree"    => s(:gasgn, :$x, s(:lit, 42)))

  add_tests("global",
            "Ruby"         => "$stderr",
            "ParseTree"    =>  s(:gvar, :$stderr))

  add_tests("gvar",
            "Ruby"         => "$x",
            "ParseTree"    => s(:gvar, :$x))

  add_tests("gvar_underscore",
            "Ruby"         => "$_",
            "ParseTree"    => s(:gvar, :$_))

  add_tests("gvar_underscore_blah",
            "Ruby"         => "$__blah",
            "ParseTree"    => s(:gvar, :$__blah))

  add_tests("hash",
            "Ruby"         => "{ 1 => 2, 3 => 4 }",
            "ParseTree"    => s(:hash,
                                s(:lit, 1), s(:lit, 2),
                                s(:lit, 3), s(:lit, 4)))

  add_tests("hash_rescue",
            "Ruby"         => "{ 1 => (2 rescue 3) }",
            "ParseTree"    => s(:hash,
                                s(:lit, 1),
                                s(:rescue,
                                  s(:lit, 2),
                                  s(:resbody, s(:array), s(:lit, 3)))))

  add_tests("iasgn",
            "Ruby"         => "@a = 4",
            "ParseTree"    => s(:iasgn, :@a, s(:lit, 4)))

  add_tests("if_block_condition",
            "Ruby"         => "if (x = 5\n(x + 1)) then\n  nil\nend",
            "ParseTree"    => s(:if,
                                s(:block,
                                  s(:lasgn, :x, s(:lit, 5)),
                                  s(:call, s(:lvar, :x), :+, s(:lit, 1))),
                                s(:nil),
                                nil))

  add_tests("if_lasgn_short",
            "Ruby"         => "if x = obj.x then\n  x.do_it\nend",
            "ParseTree"    => s(:if,
                                s(:lasgn, :x,
                                  s(:call,
                                    s(:call, nil, :obj),
                                    :x)),
                                s(:call, s(:lvar, :x), :do_it),
                                nil))

  add_tests("if_nested",
            "Ruby"         => "return if false unless true",
            "ParseTree"    => s(:if, s(:true), nil,
                                s(:if, s(:false), s(:return), nil)))

  add_tests("if_post",
            "Ruby"         => "a if b",
            "ParseTree"    => s(:if, s(:call, nil, :b),
                                s(:call, nil, :a), nil))

  add_tests("if_pre",
            "Ruby"         => "if b then a end",
            "ParseTree"    => s(:if, s(:call, nil, :b),
                                s(:call, nil, :a), nil),
            "Ruby2Ruby"    => "a if b")

  add_tests("iter_call_arglist_space",
            "Ruby" => "a (1) {|c|d}",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a, s(:lit, 1)),
                                s(:args, :c),
                                s(:call, nil, :d)),
            "Ruby2Ruby"    => "a(1) { |c| d }")

  add_tests("iter_dasgn_curr_dasgn_madness",
            "Ruby"         => "as.each { |a|\n  b += a.b(false) }",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :as), :each),
                                s(:args, :a),
                                s(:lasgn, :b,
                                  s(:call,
                                    s(:lvar, :b),
                                    :+,
                                    s(:call, s(:lvar, :a), :b, s(:false))))),
            "Ruby2Ruby"    => "as.each { |a| b = (b + a.b(false)) }")

  add_tests("iter_downto",
            "Ruby"         => "3.downto(1) { |n| puts(n.to_s) }",
            "ParseTree"    => s(:iter,
                                s(:call, s(:lit, 3), :downto, s(:lit, 1)),
                                s(:args, :n),
                                s(:call, nil, :puts,
                                  s(:call, s(:lvar, :n), :to_s))))

  add_tests("iter_each_lvar",
            "Ruby"         => "array = [1, 2, 3]\narray.each { |x| puts(x.to_s) }\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :array,
                                  s(:array,
                                    s(:lit, 1), s(:lit, 2), s(:lit, 3))),
                                s(:iter,
                                  s(:call, s(:lvar, :array), :each),
                                  s(:args, :x),
                                  s(:call, nil, :puts,
                                    s(:call, s(:lvar, :x), :to_s)))))

  add_tests("iter_each_nested",
            "Ruby"         => "array1 = [1, 2, 3]\narray2 = [4, 5, 6, 7]\narray1.each do |x|\n  array2.each do |y|\n    puts(x.to_s)\n    puts(y.to_s)\n  end\nend\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :array1,
                                  s(:array,
                                    s(:lit, 1), s(:lit, 2), s(:lit, 3))),
                                s(:lasgn, :array2,
                                  s(:array,
                                    s(:lit, 4), s(:lit, 5),
                                    s(:lit, 6), s(:lit, 7))),
                                s(:iter,
                                  s(:call, s(:lvar, :array1), :each),
                                  s(:args, :x),
                                  s(:iter,
                                    s(:call, s(:lvar, :array2), :each),
                                    s(:args, :y),
                                    s(:block,
                                      s(:call, nil, :puts,
                                        s(:call, s(:lvar, :x), :to_s)),
                                      s(:call, nil, :puts,
                                        s(:call, s(:lvar, :y), :to_s)))))))

  add_tests("iter_loop_empty",
            "Ruby"         => "loop { }",
            "ParseTree"    => s(:iter, s(:call, nil, :loop), 0))

  add_tests("iter_masgn_2",
            "Ruby"         => "a { |b, c| p(c) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :b, :c),
                                s(:call, nil, :p, s(:lvar, :c))))

  add_tests("iter_masgn_args_splat",
            "Ruby"         => "a { |b, c, *d| p(c) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :b, :c, :"*d"),
                                s(:call, nil, :p, s(:lvar, :c))))

  add_tests("iter_masgn_args_splat_no_name",
            "Ruby"         => "a { |b, c, *| p(c) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :b, :c, :*),
                                s(:call, nil, :p, s(:lvar, :c))))

  add_tests("iter_masgn_splat",
            "Ruby"         => "a { |*c| p(c) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :"*c"),
                                s(:call, nil, :p, s(:lvar, :c))))

  add_tests("iter_masgn_splat_no_name",
            "Ruby"         => "a { |*| p(c) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :*),
                                s(:call, nil, :p, s(:call, nil, :c))))

  add_tests("iter_shadowed_var",
            "Ruby"         => "a do |x|\n  b do |x|\n    puts x\n  end\nend",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :a),
                                s(:args, :x),
                                s(:iter,
                                  s(:call, nil, :b),
                                  s(:args, :x),
                                  s(:call, nil, :puts, s(:lvar, :x)))),
            "Ruby2Ruby"    => "a { |x| b { |x| puts(x) } }")

  add_tests("iter_upto",
            "Ruby"         => "1.upto(3) { |n| puts(n.to_s) }",
            "ParseTree"    => s(:iter,
                                s(:call, s(:lit, 1), :upto, s(:lit, 3)),
                                s(:args, :n),
                                s(:call, nil, :puts,
                                  s(:call, s(:lvar, :n), :to_s))))

  add_tests("iter_while",
            "Ruby"         => "argl = 10\nwhile (argl >= 1) do\n  puts(\"hello\")\n  argl = (argl - 1)\nend\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :argl, s(:lit, 10)),
                                s(:while,
                                  s(:call, s(:lvar, :argl), :">=", s(:lit, 1)),
                                  s(:block,
                                    s(:call, nil, :puts, s(:str, "hello")),
                                    s(:lasgn,
                                      :argl,
                                      s(:call, s(:lvar, :argl), :"-",
                                        s(:lit, 1)))),
                                  true)))

  add_tests("ivar",
            "Ruby"         => [Examples, :reader],
            "ParseTree"    => s(:defn, :reader, s(:args),
                                s(:ivar, :@reader)),
            "Ruby2Ruby"    => "attr_reader :reader")

  add_tests("lambda_args_anon_star",
            "Ruby"         => "lambda { |*| nil }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :*),
                                s(:nil)))

  add_tests("lambda_args_anon_star_block",
            "Ruby"         => "lambda { |*, &block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :*, :"&block"),
                                s(:lvar, :block)))

  add_tests("lambda_args_block",
            "Ruby"         => "lambda { |&block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :"&block"),
                                s(:lvar, :block)))

  add_tests("lambda_args_norm_anon_star",
            "Ruby"         => "lambda { |a, *| a }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :*),
                                s(:lvar, :a)))

  add_tests("lambda_args_norm_anon_star_block",
            "Ruby"         => "lambda { |a, *, &block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :*, :"&block"),
                                s(:lvar, :block)))

  add_tests("lambda_args_norm_block",
            "Ruby"         => "lambda { |a, &block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :"&block"),
                                s(:lvar, :block)))

  add_tests("lambda_args_norm_comma",
            "Ruby"         => "lambda { |a,| a }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, nil),
                                s(:lvar, :a)))

  add_tests("lambda_args_norm_comma2",
            "Ruby"         => "lambda { |a, b,| a }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :b, nil),
                                s(:lvar, :a)))

  add_tests("lambda_args_norm_star",
            "Ruby"         => "lambda { |a, *star| star }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :"*star"),
                                s(:lvar, :star)))

  add_tests("lambda_args_norm_star_block",
            "Ruby"         => "lambda { |a, *star, &block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :a, :"*star", :"&block"),
                                s(:lvar, :block)))

  add_tests("lambda_args_star",
            "Ruby"         => "lambda { |*star| star }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :"*star"),
                                s(:lvar, :star)))

  add_tests("lambda_args_star_block",
            "Ruby"         => "lambda { |*star, &block| block }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :lambda),
                                s(:args, :"*star", :"&block"),
                                s(:lvar, :block)))

  add_tests("lasgn_array",
            "Ruby"         => "var = [\"foo\", \"bar\"]",
            "ParseTree"    => s(:lasgn, :var,
                                s(:array,
                                  s(:str, "foo"),
                                  s(:str, "bar"))))

  add_tests("lasgn_call",
            "Ruby"         => "c = (2 + 3)",
            "ParseTree"    => s(:lasgn, :c,
                                s(:call, s(:lit, 2), :+, s(:lit, 3))))

  add_tests("lit_bool_false",
            "Ruby"         => "false",
            "ParseTree"    => s(:false))

  add_tests("lit_bool_true",
            "Ruby"         => "true",
            "ParseTree"    => s(:true))

  add_tests("lit_float",
            "Ruby"         => "1.1",
            "ParseTree"    => s(:lit, 1.1))

  add_tests("lit_long",
            "Ruby"         => "1",
            "ParseTree"    => s(:lit, 1))

  add_tests("lit_long_negative",
            "Ruby"         => "-1",
            "ParseTree"    => s(:lit, -1))

  add_tests("lit_range2",
            "Ruby"         => "(1..10)",
            "ParseTree"    => s(:lit, 1..10))

  add_tests("lit_range3",
            "Ruby"         => "(1...10)",
            "ParseTree"    => s(:lit, 1...10))

  add_tests("lit_regexp",
            "Ruby"         => "/x/",
            "ParseTree"    => s(:lit, /x/))

  add_tests("lit_regexp_i_wwtt",
            "Ruby"         => "str.split(//i)",
            "ParseTree"    => s(:call,
                                s(:call, nil, :str),
                                :split,
                                s(:lit, //i)))

  add_tests("lit_regexp_n",
            "Ruby"         => "/x/n", # HACK differs on 1.9 - this is easiest
            "ParseTree"    => s(:lit, /x/n),
            "Ruby2Ruby"    => /x/n.inspect)

  add_tests("lit_regexp_once",
            "Ruby"         => "/x/o",
            "ParseTree"    => s(:lit, /x/),
            "Ruby2Ruby"    => "/x/")

  add_tests("lit_sym",
            "Ruby"         => ":x",
            "ParseTree"    => s(:lit, :x))

  add_tests("lit_sym_splat",
            "Ruby"         => ":\"*args\"",
            "ParseTree"    => s(:lit, :"*args"))

  add_tests("lvar_def_boundary",
            "Ruby"         => "b = 42\ndef a\n  c do\n    begin\n      do_stuff\n    rescue RuntimeError => b\n      puts(b)\n    end\n  end\nend\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :b, s(:lit, 42)),
                                s(:defn, :a, s(:args),
                                  s(:iter,
                                    s(:call, nil, :c),
                                    0,
                                    s(:rescue,
                                      s(:call, nil, :do_stuff),
                                      s(:resbody,
                                        s(:array,
                                          s(:const, :RuntimeError),
                                          s(:lasgn, :b, s(:gvar, :$!))),
                                        s(:call, nil, :puts,
                                          s(:lvar, :b))))))))

  add_tests("masgn",
            "Ruby"         => "a, b = c, d",
            "ParseTree"    => s(:masgn,
                                s(:array, s(:lasgn, :a), s(:lasgn, :b)),
                                s(:array, s(:call, nil, :c),
                                  s(:call, nil, :d))))

  add_tests("masgn_argscat",
            "Ruby"         => "a, b, *c = 1, 2, *[3, 4]",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b),
                                  s(:splat, s(:lasgn, :c))),
                                s(:array,
                                  s(:lit, 1), s(:lit, 2),
                                  s(:splat,
                                    s(:array, s(:lit, 3), s(:lit, 4))))))

  add_tests("masgn_attrasgn",
            "Ruby"         => "a, b.c = d, e",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:attrasgn,
                                    s(:call, nil, :b),
                                    :c=)),
                                s(:array,
                                  s(:call, nil, :d),
                                  s(:call, nil, :e))))

  add_tests("masgn_attrasgn_array_rhs",
            "Ruby"         => "a.b, a.c, _ = q",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:attrasgn,
                                    s(:call, nil, :a),
                                    :b=),
                                  s(:attrasgn,
                                    s(:call, nil, :a),
                                    :c=),
                                  s(:lasgn, :_)),
                                s(:to_ary,
                                  s(:call, nil, :q))))

  add_tests("masgn_attrasgn_idx",
            "Ruby"         => "a, i, j = [], 1, 2\na[i], a[j] = a[j], a[i]\n",
            "ParseTree"    => s(:block,
                                s(:masgn,
                                  s(:array,
                                    s(:lasgn, :a),
                                    s(:lasgn, :i), s(:lasgn, :j)),
                                  s(:array, s(:array), s(:lit, 1), s(:lit, 2))),
                                s(:masgn,
                                  s(:array,
                                    s(:attrasgn,
                                      s(:lvar, :a), :[]=, s(:lvar, :i)),
                                    s(:attrasgn,
                                      s(:lvar, :a), :[]=, s(:lvar, :j))),
                                  s(:array,
                                    s(:call,
                                      s(:lvar, :a), :[], s(:lvar, :j)),
                                    s(:call,
                                      s(:lvar, :a), :[], s(:lvar, :i))))))

  add_tests("masgn_cdecl",
            "Ruby"         => "A, B, C = 1, 2, 3",
            "ParseTree"    => s(:masgn,
                               s(:array, s(:cdecl, :A), s(:cdecl, :B),
                                s(:cdecl, :C)),
                               s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))))

  add_tests("masgn_iasgn",
            "Ruby"         => "a, @b = c, d",
            "ParseTree"    => s(:masgn,
                                s(:array, s(:lasgn, :a), s(:iasgn, :"@b")),
                                s(:array,
                                  s(:call, nil, :c),
                                  s(:call, nil, :d))))

  add_tests("masgn_masgn",
            "Ruby"         => "a, (b, c) = [1, [2, 3]]",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:masgn,
                                    s(:array,
                                      s(:lasgn, :b),
                                      s(:lasgn, :c)))),
                                s(:to_ary,
                                  s(:array,
                                    s(:lit, 1),
                                    s(:array,
                                      s(:lit, 2),
                                      s(:lit, 3))))))

  add_tests("masgn_splat_lhs",
            "Ruby"         => "a, b, *c = d, e, f, g",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b),
                                  s(:splat, s(:lasgn, :c))),
                                s(:array,
                                  s(:call, nil, :d),
                                  s(:call, nil, :e),
                                  s(:call, nil, :f),
                                  s(:call, nil, :g))))

  add_tests("masgn_splat_no_name_to_ary",
            "Ruby"         => "a, b, * = c",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b),
                                  s(:splat)),
                                s(:to_ary, s(:call, nil, :c))))

  add_tests("masgn_splat_no_name_trailing",
            "Ruby"         => "a, b, = c",
            "ParseTree"    => s(:masgn,
                                s(:array, s(:lasgn, :a), s(:lasgn, :b)),
                                s(:to_ary, s(:call, nil, :c))),
            "Ruby2Ruby"    => "a, b = c") # TODO: check this is right

  add_tests("masgn_splat_rhs_1",
            "Ruby"         => "a, b = *c",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b)),
                                s(:splat, s(:call, nil, :c))))

  add_tests("masgn_splat_rhs_n",
            "Ruby"         => "a, b = c, d, *e",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b)),
                                s(:array,
                                  s(:call, nil, :c),
                                  s(:call, nil, :d),
                                  s(:splat, s(:call, nil, :e)))))

  add_tests("masgn_splat_to_ary",
            "Ruby"         => "a, b, *c = d",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b),
                                  s(:splat, s(:lasgn, :c))),
                                s(:to_ary, s(:call, nil, :d))))

  add_tests("masgn_splat_to_ary2",
            "Ruby"         => "a, b, *c = d.e(\"f\")",
            "ParseTree"    => s(:masgn,
                                s(:array,
                                  s(:lasgn, :a),
                                  s(:lasgn, :b),
                                  s(:splat, s(:lasgn, :c))),
                                s(:to_ary,
                                  s(:call,
                                    s(:call, nil, :d),
                                    :e,
                                    s(:str, "f")))))

  add_tests("match",
            "Ruby"         => "1 if /x/",
            "ParseTree"    => s(:if, s(:match, s(:lit, /x/)), s(:lit, 1), nil))

  add_tests("match2",
            "Ruby"         => "/x/ =~ \"blah\"",
            "ParseTree"    => s(:match2, s(:lit, /x/), s(:str, "blah")))

  add_tests("match3",
            "Ruby"         => "\"blah\" =~ /x/",
            "ParseTree"    => s(:match3, s(:lit, /x/), s(:str, "blah")))

  add_tests("module",
            "Ruby"         => "module X\n  def y\n    # do nothing\n  end\nend",
            "ParseTree"    => s(:module, :X,
                                s(:defn, :y, s(:args), s(:nil))))

  add_tests("module2",
            "Ruby"         => "module X\n  def y\n    # do nothing\n  end\n  \n  def z\n    # do nothing\n  end\nend",
            "ParseTree"    => s(:module, :X,
                                s(:defn, :y, s(:args), s(:nil)),
                                s(:defn, :z, s(:args), s(:nil))))

  add_tests("module_scoped",
            "Ruby"         => "module X::Y\n  c\nend",
            "ParseTree"    => s(:module, s(:colon2, s(:const, :X), :Y),
                                s(:call, nil, :c)))

  add_tests("module_scoped3",
            "Ruby"         => "module ::Y\n  c\nend",
            "ParseTree"    => s(:module, s(:colon3, :Y),
                                s(:call, nil, :c)))

  add_tests("next",
            "Ruby"         => "loop { next if false }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :loop),
                                0,
                                s(:if, s(:false), s(:next), nil)))

  add_tests("next_arg",
            "Ruby"         => "loop { next 42 if false }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :loop),
                                0,
                                s(:if, s(:false), s(:next, s(:lit, 42)), nil)))

  add_tests("nth_ref",
            "Ruby"         => "$1",
            "ParseTree"    => s(:nth_ref, 1))

  add_tests("op_asgn1",
            "Ruby"         => "b = []\nb[1] ||= 10\nb[2] &&= 11\nb[3] += 12\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :b, s(:array)),
                                s(:op_asgn1, s(:lvar, :b),
                                  s(:arglist, s(:lit, 1)), :"||", s(:lit, 10)),
                                s(:op_asgn1, s(:lvar, :b),
                                  s(:arglist, s(:lit, 2)), :"&&", s(:lit, 11)),
                                s(:op_asgn1, s(:lvar, :b),
                                  s(:arglist, s(:lit, 3)), :+, s(:lit, 12))))

  add_tests("op_asgn1_ivar",
            "Ruby"         => "@b = []\n@b[1] ||= 10\n@b[2] &&= 11\n@b[3] += 12\n",
            "ParseTree"    => s(:block,
                                s(:iasgn, :@b, s(:array)),
                                s(:op_asgn1, s(:ivar, :@b),
                                  s(:arglist, s(:lit, 1)), :"||", s(:lit, 10)),
                                s(:op_asgn1, s(:ivar, :@b),
                                  s(:arglist, s(:lit, 2)), :"&&", s(:lit, 11)),
                                s(:op_asgn1, s(:ivar, :@b),
                                  s(:arglist, s(:lit, 3)), :+, s(:lit, 12))))

  add_tests("op_asgn2",
            "Ruby"         => "s = Struct.new(:var)\nc = s.new(nil)\nc.var ||= 20\nc.var &&= 21\nc.var += 22\nc.d.e.f ||= 42\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :s,
                                  s(:call,
                                    s(:const, :Struct),
                                    :new,
                                    s(:lit, :var))),
                                s(:lasgn, :c,
                                  s(:call, s(:lvar, :s), :new, s(:nil))),
                                s(:op_asgn2, s(:lvar, :c),
                                  :var=, :"||", s(:lit, 20)),
                                s(:op_asgn2, s(:lvar, :c),
                                  :var=, :"&&", s(:lit, 21)),
                                s(:op_asgn2, s(:lvar, :c),
                                  :var=, :+, s(:lit, 22)),
                                s(:op_asgn2,
                                  s(:call,
                                    s(:call, s(:lvar, :c), :d),
                                    :e),
                                  :f=, :"||", s(:lit, 42))))

  add_tests("op_asgn2_self",
            "Ruby"         => "self.Bag ||= Bag.new",
            "ParseTree"    => s(:op_asgn2, s(:self), :"Bag=", :"||",
                                s(:call, s(:const, :Bag), :new)))

  add_tests("op_asgn_and",
            "Ruby"         => "a = 0\na &&= 2\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :a, s(:lit, 0)),
                                s(:op_asgn_and,
                                  s(:lvar, :a), s(:lasgn, :a, s(:lit, 2)))))

  add_tests("op_asgn_and_ivar2",
            "Ruby"         => "@fetcher &&= new(Gem.configuration[:http_proxy])",
            "ParseTree"    => s(:op_asgn_and,
                                s(:ivar, :@fetcher),
                                s(:iasgn,
                                  :@fetcher,
                                  s(:call, nil,
                                    :new,
                                    s(:call,
                                      s(:call, s(:const, :Gem), :configuration),
                                      :[],
                                      s(:lit, :http_proxy))))))

  add_tests("op_asgn_or",
            "Ruby"         => "a = 0\na ||= 1\n",
            "ParseTree"    => s(:block,
                                s(:lasgn, :a, s(:lit, 0)),
                                s(:op_asgn_or,
                                  s(:lvar, :a), s(:lasgn, :a, s(:lit, 1)))))

  add_tests("op_asgn_or_block",
            "Ruby"         => "a ||= begin\n        b\n      rescue\n        c\n      end",
            "ParseTree"    => s(:op_asgn_or,
                                s(:lvar, :a),
                                s(:lasgn, :a,
                                  s(:rescue,
                                    s(:call, nil, :b),
                                    s(:resbody, s(:array),
                                      s(:call, nil, :c))))),
            "Ruby2Ruby"    => "a ||= b rescue c")

  add_tests("op_asgn_or_ivar",
            "Ruby"         => "@v ||= {}",
            "ParseTree"    => s(:op_asgn_or,
                                s(:ivar, :@v),
                                s(:iasgn, :@v, s(:hash))))

  add_tests("op_asgn_or_ivar2",
            "Ruby"         => "@fetcher ||= new(Gem.configuration[:http_proxy])",
            "ParseTree"    => s(:op_asgn_or,
                                s(:ivar, :@fetcher),
                                s(:iasgn,
                                  :@fetcher,
                                  s(:call, nil, :new,
                                    s(:call,
                                      s(:call, s(:const, :Gem), :configuration),
                                      :[],
                                      s(:lit, :http_proxy))))))

  add_tests("or",
            "Ruby"         => "(a or b)",
            "ParseTree"    => s(:or,
                                s(:call, nil, :a),
                                s(:call, nil, :b)))

  add_tests("or_big",
            "Ruby"         => "((a or b) or (c and d))",
            "ParseTree"    => s(:or,
                                s(:or,
                                  s(:call, nil, :a),
                                  s(:call, nil, :b)),
                                s(:and,
                                  s(:call, nil, :c),
                                  s(:call, nil, :d))))

  add_tests("or_big2",
            "Ruby"         => "((a || b) || (c && d))",
            "ParseTree"    => s(:or,
                                s(:or,
                                  s(:call, nil, :a),
                                  s(:call, nil, :b)),
                                s(:and,
                                  s(:call, nil, :c),
                                  s(:call, nil, :d))),
            "Ruby2Ruby"    => "((a or b) or (c and d))")

  add_tests("parse_floats_as_args",
            "Ruby"         => "def x(a=0.0,b=0.0)\n  a+b\nend",
            "ParseTree"    => s(:defn, :x,
                                s(:args,
                                  s(:lasgn, :a, s(:lit, 0.0)),
                                  s(:lasgn, :b, s(:lit, 0.0))),
                                s(:call, s(:lvar, :a), :+, s(:lvar, :b))),
            "Ruby2Ruby"    => "def x(a = 0.0, b = 0.0)\n  (a + b)\nend")

  add_tests("postexe",
            "Ruby"         => "END { 1 }",
            "ParseTree"    => s(:iter, s(:postexe), 0, s(:lit, 1)))

  add_tests("proc_args_0",
            "Ruby"         => "proc { || (x + 1) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :proc),
                                s(:args),
                                s(:call, s(:call, nil, :x), :+, s(:lit, 1))))

  add_tests("proc_args_1",
            "Ruby"         => "proc { |x| (x + 1) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :proc),
                                s(:args, :x),
                                s(:call, s(:lvar, :x), :+, s(:lit, 1))))

  add_tests("proc_args_2",
            "Ruby"         => "proc { |x, y| (x + y) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :proc),
                                s(:args, :x, :y),
                                s(:call, s(:lvar, :x), :+, s(:lvar, :y))))

  add_tests("proc_args_no",
            "Ruby"         => "proc { (x + 1) }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :proc),
                                0,
                                s(:call, s(:call, nil, :x), :+, s(:lit, 1))))

  add_tests("redo",
            "Ruby"         => "loop { redo if false }",
            "ParseTree"    => s(:iter,
                                s(:call, nil, :loop),
                                0,
                                s(:if, s(:false), s(:redo), nil)))

  add_tests("rescue",  # TODO: need a resbody w/ multiple classes and a splat
            "Ruby"         => "blah rescue nil",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :blah),
                                s(:resbody, s(:array), s(:nil))))

  add_tests("rescue_block_body",
            "Ruby"         => "begin\n  a\nrescue => e\n  c\n  d\nend",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :a),
                                s(:resbody,
                                  s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                                  s(:call, nil, :c),
                                  s(:call, nil, :d))))

  add_tests("rescue_block_body_3",
            "Ruby"         => "begin\n  a\nrescue A\n  b\nrescue B\n  c\nrescue C\n  d\nend",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :a),
                                s(:resbody, s(:array, s(:const, :A)),
                                  s(:call, nil, :b)),
                                s(:resbody, s(:array, s(:const, :B)),
                                  s(:call, nil, :c)),
                                s(:resbody, s(:array, s(:const, :C)),
                                  s(:call, nil, :d))))

  add_tests("rescue_block_body_ivar",
            "Ruby"         => "begin\n  a\nrescue => @e\n  c\n  d\nend",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :a),
                                s(:resbody,
                                  s(:array, s(:iasgn, :@e, s(:gvar, :$!))),
                                  s(:call, nil, :c),
                                  s(:call, nil, :d))))

  add_tests("rescue_block_nada",
            "Ruby"         => "begin\n  blah\nrescue\n  # do nothing\nend",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :blah),
                                s(:resbody, s(:array), nil)))

  add_tests("rescue_exceptions",
            "Ruby"         => "begin\n  blah\nrescue RuntimeError => r\n  # do nothing\nend",
            "ParseTree"    => s(:rescue,
                                s(:call, nil, :blah),
                                s(:resbody,
                                  s(:array,
                                    s(:const, :RuntimeError),
                                    s(:lasgn, :r, s(:gvar, :$!))),
                                  nil)))

  add_tests("rescue_iasgn_var_empty",
            "Ruby"         => "begin\n  1\nrescue => @e\n  # do nothing\nend",
            "ParseTree"    => s(:rescue,
                                s(:lit, 1),
                                s(:resbody,
                                  s(:array, s(:iasgn, :@e, s(:gvar, :$!))),
                                  nil)))

  add_tests("rescue_lasgn",
            "Ruby"         => "begin\n  1\nrescue\n  var = 2\nend",
            "ParseTree"    => s(:rescue,
                                s(:lit, 1),
                                s(:resbody,
                                  s(:array),
                                  s(:lasgn, :var, s(:lit, 2)))),
            "Ruby2Ruby"    => "1 rescue var = 2")

  add_tests("rescue_lasgn_var",
            "Ruby"         => "begin\n  1\nrescue => e\n  var = 2\nend",
            "ParseTree"    => s(:rescue,
                                s(:lit, 1),
                                s(:resbody,
                                  s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                                  s(:lasgn, :var, s(:lit, 2)))))

  add_tests("rescue_lasgn_var_empty",
            "Ruby"         => "begin\n  1\nrescue => e\n  # do nothing\nend",
            "ParseTree"    => s(:rescue,
                                s(:lit, 1),
                                s(:resbody,
                                  s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                                  nil)))

  add_tests("retry",
            "Ruby"         => "retry",
            "ParseTree"    => s(:retry))

  add_tests("return_0",
            "Ruby"         => "return",
            "ParseTree"    => s(:return))

  add_tests("return_1",
            "Ruby"         => "return 1",
            "ParseTree"    => s(:return, s(:lit, 1)))

  add_tests("return_1_splatted",
            "Ruby"         => "return *1",
            "ParseTree"    => s(:return, s(:svalue, s(:splat, s(:lit, 1)))))

  add_tests("return_n",
            "Ruby"         => "return 1, 2, 3",
            "ParseTree"    => s(:return, s(:array,
                                           s(:lit, 1), s(:lit, 2), s(:lit, 3))),
            "Ruby2Ruby"    => "return [1, 2, 3]")

  add_tests("sclass",
            "Ruby"         => "class << self\n  42\nend",
            "ParseTree"    => s(:sclass, s(:self), s(:lit, 42)))

  add_tests("sclass_multiple",
            "Ruby"         => "class << self\n  x\n  y\nend",
            "ParseTree"    => s(:sclass, s(:self),
                                s(:call, nil, :x), s(:call, nil, :y)))

  add_tests("sclass_trailing_class",
            "Ruby"         => "class A\n  class << self\n    a\n  end\n  \n  class B\n  end\nend",
            "ParseTree"    => s(:class, :A, nil,
                                s(:sclass, s(:self),
                                  s(:call, nil, :a)),
                                s(:class, :B, nil)))

  add_tests("splat",
            "Ruby"         => "def x(*b)\n  a(*b)\nend",
            "ParseTree"    => s(:defn, :x,
                                s(:args, :"*b"),
                                s(:call, nil, :a, s(:splat, s(:lvar, :b)))))

  add_tests("splat_array",
            "Ruby"         => "[*[1]]",
            "ParseTree"    => s(:array, s(:splat, s(:array, s(:lit, 1)))))

  add_tests("splat_break",
            "Ruby"         => "break *[1]",
            "ParseTree"    => s(:break, s(:svalue, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_break_array",
            "Ruby"         => "break [*[1]]",
            "ParseTree"    => s(:break, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_fcall",
            "Ruby"         => "meth(*[1])",
            "ParseTree"    => s(:call,
                                nil,
                                :meth,
                                s(:splat, s(:array, s(:lit, 1)))))

  add_tests("splat_fcall_array",
            "Ruby"         => "meth([*[1]])",
            "ParseTree"    => s(:call, nil, :meth,
                                s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_lasgn",
            "Ruby"         => "x = *[1]",
            "ParseTree"    => s(:lasgn, :x, s(:svalue, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_lasgn_array",
            "Ruby"         => "x = [*[1]]",
            "ParseTree"    => s(:lasgn, :x, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_lit_1",
            "Ruby"         => "[*1]",
# UGH - damn MRI
            "ParseTree"    => s(:array, s(:splat, s(:lit, 1))))

  add_tests("splat_lit_n",
            "Ruby"         => "[1, *2]",
            "ParseTree"    => s(:array, s(:lit, 1), s(:splat, s(:lit, 2))))

  add_tests("splat_next",
            "Ruby"         => "next *[1]",
            "ParseTree"    => s(:next, s(:svalue, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_next_array",
            "Ruby"         => "next [*[1]]",
            "ParseTree"    => s(:next, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_return",
            "Ruby"         => "return *[1]",
            "ParseTree"    => s(:return, s(:svalue, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_return_array",
            "Ruby"         => "return [*[1]]",
            "ParseTree"    => s(:return, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_super",
            "Ruby"         => "super(*[1])",
            "ParseTree"    => s(:super, s(:splat, s(:array, s(:lit, 1)))))

  add_tests("splat_super_array",
            "Ruby"         => "super([*[1]])",
            "ParseTree"    => s(:super, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("splat_yield",
            "Ruby"         => "yield(*[1])",
            "ParseTree"    => s(:yield, s(:splat, s(:array, s(:lit, 1)))))

  add_tests("splat_yield_array",
            "Ruby"         => "yield([*[1]])",
            "ParseTree"    => s(:yield, s(:array, s(:splat, s(:array, s(:lit, 1))))))

  add_tests("str",
            "Ruby"         => '"x"',
            "ParseTree"    => s(:str, "x"))

  add_tests("str_concat_newline", # FIX? make prettier? possible?
            "Ruby"         => '"before" \\
  " after"',
            "ParseTree"    => s(:str, "before after"),
            "Ruby2Ruby"    => '"before after"')

  add_tests("str_concat_space",
            "Ruby"         => '"before" " after"',
            "ParseTree"    => s(:str, "before after"),
            "Ruby2Ruby"    => '"before after"')

  add_tests("str_heredoc",
            "Ruby"         => "<<'EOM'\n  blah\nblah\nEOM",
            "ParseTree"    => s(:str, "  blah\nblah\n"),
            "Ruby2Ruby"    => "\"  blah\\nblah\\n\"")

  add_tests("str_heredoc_call",
            "Ruby"         => "<<'EOM'.strip\n  blah\nblah\nEOM",
            "ParseTree"    => s(:call, s(:str, "  blah\nblah\n"),
                                :strip),
            "Ruby2Ruby"    => "\"  blah\\nblah\\n\".strip")

  add_tests("str_heredoc_double",
            "Ruby"         => "a += <<-H1 + b + <<-H2\n  first\nH1\n  second\nH2",
            "ParseTree"    => s(:lasgn, :a,
                                s(:call,
                                  s(:lvar, :a),
                                  :+,
                                  s(:call,
                                    s(:call,
                                      s(:str, "  first\n"),
                                      :+,
                                      s(:call, nil, :b)),
                                    :+,
                                    s(:str, "  second\n")))),
            "Ruby2Ruby"    => "a = (a + ((\"  first\\n\" + b) + \"  second\\n\"))")

  add_tests("str_heredoc_empty", # yes... tarded
            "Ruby"         => "<<'EOM'\nEOM",
            "ParseTree"    => s(:str, ""),
            "Ruby2Ruby"    => '""')

  add_tests("str_heredoc_indent",
            "Ruby"         => "<<-EOM\n  blah\nblah\n\n  EOM",
            "ParseTree"    => s(:str, "  blah\nblah\n\n"),
            "Ruby2Ruby"    => "\"  blah\\nblah\\n\\n\"")

  add_tests("str_interp_file",
            "Ruby"         => '"file = #{__FILE__}\n"',
            "ParseTree"    => s(:str, "file = (string)\n"),
            "Ruby2Ruby"    => '"file = (string)\\n"')

  add_tests("structure_extra_block_for_dvar_scoping",
            "Ruby"         => "a.b do |c, d|\n  unless e.f(c) then\n    g = false\n    d.h { |x, i| g = true }\n  end\nend",
            "ParseTree"    => s(:iter,
                                s(:call, s(:call, nil, :a), :b),
                                s(:args, :c, :d),
                                s(:if,
                                  s(:call, s(:call, nil, :e), :f, s(:lvar, :c)),
                                  nil,
                                  s(:block,
                                    s(:lasgn, :g, s(:false)),
                                    s(:iter,
                                      s(:call, s(:lvar, :d), :h),
                                      s(:args, :x, :i),
                                      s(:lasgn, :g, s(:true)))))))

  add_tests("structure_remove_begin_1",
            "Ruby"         => "a << begin\n       b\n     rescue\n       c\n     end",
            "ParseTree"    => s(:call, s(:call, nil, :a), :<<,
                                s(:rescue,
                                  s(:call, nil, :b),
                                  s(:resbody, s(:array),
                                    s(:call, nil, :c)))),
            "Ruby2Ruby"    => "(a << (b rescue c))")

  add_tests("structure_remove_begin_2",
            "Ruby"         => "a = if c\n      begin\n        b\n      rescue\n        nil\n      end\n    end\na",
            "ParseTree"    => s(:block,
                                s(:lasgn,
                                  :a,
                                  s(:if, s(:call, nil, :c),
                                    s(:rescue, s(:call, nil, :b),
                                      s(:resbody,
                                        s(:array), s(:nil))),
                                    nil)),
                                s(:lvar, :a)),
            "Ruby2Ruby"    => "a = b rescue nil if c\na\n") # OMG that's awesome

  add_tests("super_0",
            "Ruby"         => "def x\n  super()\nend",
            "ParseTree"    => s(:defn, :x, s(:args), s(:super)))

  add_tests("super_1",
            "Ruby"         => "def x\n  super(4)\nend",
            "ParseTree"    => s(:defn, :x, s(:args),
                                s(:super, s(:lit, 4))))

  add_tests("super_1_array",
            "Ruby"         => "def x\n  super([24, 42])\nend",
            "ParseTree"    => s(:defn, :x, s(:args),
                                s(:super, s(:array, s(:lit, 24), s(:lit, 42)))))

  add_tests("super_block_pass",
            "Ruby"         => "super(a, &b)",
            "ParseTree"    => s(:super,
                                s(:call, nil, :a),
                                s(:block_pass,
                                  s(:call, nil, :b))))

  add_tests("super_block_splat",
            "Ruby"         => "super(a, *b)",
            "ParseTree"    => s(:super,
                                s(:call, nil, :a),
                                s(:splat, s(:call, nil, :b))))

  add_tests("super_n",
            "Ruby"         => "def x\n  super(24, 42)\nend",
            "ParseTree"    => s(:defn, :x, s(:args),
                                s(:super, s(:lit, 24), s(:lit, 42))))

  add_tests("svalue",
            "Ruby"         => "a = *b",
            "ParseTree"    => s(:lasgn, :a,
                                s(:svalue,
                                  s(:splat, s(:call, nil, :b)))))

  add_tests("ternary_nil_no_space",
            "Ruby"         => "1 ? nil: 1",
            "ParseTree"    => s(:if, s(:lit, 1), s(:nil), s(:lit, 1)),
            "Ruby2Ruby"    => "1 ? (nil) : (1)")

  add_tests("ternary_symbol_no_spaces",
            "Ruby"         => "1?:x:1",
            "ParseTree"    => s(:if, s(:lit, 1), s(:lit, :x), s(:lit, 1)),
            "Ruby2Ruby"    => "1 ? (:x) : (1)")

  add_tests("to_ary",
            "Ruby"         => "a, b = c",
            "ParseTree"    => s(:masgn,
                                s(:array, s(:lasgn, :a), s(:lasgn, :b)),
                                s(:to_ary, s(:call, nil, :c))))

  add_tests("true",
            "Ruby"         => "true",
            "ParseTree"    => s(:true))

  add_tests("undef",
            "Ruby"         => "undef :x",
            "ParseTree"    => s(:undef, s(:lit, :x)))

  add_tests("undef_2",
            "Ruby"         => "undef :x, :y",
            "ParseTree"    => s(:block,
                                s(:undef, s(:lit, :x)),
                                s(:undef, s(:lit, :y))),
            "Ruby2Ruby"    => "undef :x\nundef :y\n")

  add_tests("undef_3",
            "Ruby"         => "undef :x, :y, :z",
            "ParseTree"    => s(:block,
                                s(:undef, s(:lit, :x)),
                                s(:undef, s(:lit, :y)),
                                s(:undef, s(:lit, :z))),
            "Ruby2Ruby"    => "undef :x\nundef :y\nundef :z\n")

  add_tests("undef_block_1",
            "Ruby"         => "f1\nundef :x\n", # TODO: don't like the extra return
            "ParseTree"    => s(:block,
                                s(:call, nil, :f1),
                                s(:undef, s(:lit, :x))))

  add_tests("undef_block_2",
            "Ruby"         => "f1\nundef :x, :y",
            "ParseTree"    => s(:block,
                                s(:call, nil, :f1),
                                s(:block,
                                  s(:undef, s(:lit, :x)),
                                  s(:undef, s(:lit, :y)))),
            "Ruby2Ruby"    => "f1\n(undef :x\nundef :y)\n")

  add_tests("undef_block_3",
            "Ruby"         => "f1\nundef :x, :y, :z",
            "ParseTree"    => s(:block,
                                s(:call, nil, :f1),
                                s(:block,
                                  s(:undef, s(:lit, :x)),
                                  s(:undef, s(:lit, :y)),
                                  s(:undef, s(:lit, :z)))),
            "Ruby2Ruby"    => "f1\n(undef :x\nundef :y\nundef :z)\n")

  add_tests("undef_block_3_post",
            "Ruby"         => "undef :x, :y, :z\nf2",
            "ParseTree"    => s(:block,
                                s(:undef, s(:lit, :x)),
                                s(:undef, s(:lit, :y)),
                                s(:undef, s(:lit, :z)),
                                s(:call, nil, :f2)),
            "Ruby2Ruby"    => "undef :x\nundef :y\nundef :z\nf2\n")

  add_tests("undef_block_wtf",
            "Ruby"         => "f1\nundef :x, :y, :z\nf2",
            "ParseTree"    => s(:block,
                                s(:call, nil, :f1),
                                s(:block,
                                  s(:undef, s(:lit, :x)),
                                  s(:undef, s(:lit, :y)),
                                  s(:undef, s(:lit, :z))),
                                s(:call, nil, :f2)),
            "Ruby2Ruby"    => "f1\n(undef :x\nundef :y\nundef :z)\nf2\n")

  add_tests("unless_post",
            "Ruby"         => "a unless b",
            "ParseTree"    => s(:if, s(:call, nil, :b), nil,
                                s(:call, nil, :a)))

  add_tests("unless_pre",
            "Ruby"         => "unless b then a end",
            "ParseTree"    => s(:if, s(:call, nil, :b), nil,
                                s(:call, nil, :a)),
            "Ruby2Ruby"    => "a unless b")

  add_tests("until_post",
            "Ruby"         => "begin\n  (1 + 1)\nend until false",
            "ParseTree"    => s(:until, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), false))

  add_tests("until_pre",
            "Ruby"         => "until false do\n  (1 + 1)\nend",
            "ParseTree"    => s(:until, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), true))

  add_tests("until_pre_mod",
            "Ruby"         => "(1 + 1) until false",
            "ParseTree"    => s(:until, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
            "Ruby2Ruby"    => "until false do\n  (1 + 1)\nend")

  add_tests("valias",
            "Ruby"         => "alias $y $x",
            "ParseTree"    => s(:valias, :$y, :$x))

  add_tests("vcall",
            "Ruby"         => "method",
            "ParseTree"    => s(:call, nil, :method))

  add_tests("while_post",
            "Ruby"         => "begin\n  (1 + 1)\nend while false",
            "ParseTree"    => s(:while, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), false))

  add_tests("while_post2",
            "Ruby"         => "begin\n  (1 + 2)\n  (3 + 4)\nend while false",
            "ParseTree"    => s(:while, s(:false),
                                s(:block,
                                  s(:call, s(:lit, 1), :+, s(:lit, 2)),
                                  s(:call, s(:lit, 3), :+, s(:lit, 4))),
                                false))

  add_tests("while_pre",
            "Ruby"         => "while false do\n  (1 + 1)\nend",
            "ParseTree"    => s(:while, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), true))

  add_tests("while_pre_mod",
            "Ruby"         => "(1 + 1) while false",
            "ParseTree"    => s(:while, s(:false),
                                s(:call, s(:lit, 1), :+, s(:lit, 1)), true),
            "Ruby2Ruby"    => "while false do\n  (1 + 1)\nend") # FIX can be one liner

  add_tests("while_pre_nil",
            "Ruby"         => "while false do\nend",
            "ParseTree"    => s(:while, s(:false), nil, true))

  add_tests("xstr",
            "Ruby"         => "`touch 5`",
            "ParseTree"    => s(:xstr, "touch 5"))

  add_tests("yield_0",
            "Ruby"         => "yield",
            "ParseTree"    => s(:yield))

  add_tests("yield_1",
            "Ruby"         => "yield(42)",
            "ParseTree"    => s(:yield, s(:lit, 42)))

  add_tests("yield_array_0",
            "Ruby"         => "yield([])",
            "ParseTree"    => s(:yield, s(:array)))

  add_tests("yield_array_1",
            "Ruby"         => "yield([42])",
            "ParseTree"    => s(:yield, s(:array, s(:lit, 42))))

  add_tests("yield_array_n",
            "Ruby"         => "yield([42, 24])",
            "ParseTree"    => s(:yield, s(:array, s(:lit, 42), s(:lit, 24))))

  add_tests("yield_n",
            "Ruby"         => "yield(42, 24)",
            "ParseTree"    => s(:yield, s(:lit, 42), s(:lit, 24)))

  add_tests("zarray",
            "Ruby"         => "a = []",
            "ParseTree"    => s(:lasgn, :a, s(:array)))

  add_tests("zsuper",
            "Ruby"         => "def x\n  super\nend",
            "ParseTree"    => s(:defn, :x, s(:args), s(:zsuper)))

# TODO: discuss and decide which lit we like
#   it "converts a regexp to an sexp" do
#     "/blah/".to_sexp.should == s(:regex, "blah", 0)
#     "/blah/i".to_sexp.should == s(:regex, "blah", 1)
#     "/blah/u".to_sexp.should == s(:regex, "blah", 64)
#   end

end

# :startdoc:
