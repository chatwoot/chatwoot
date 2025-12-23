$TESTING = true

if ENV["COV"]
  require "simplecov"
  SimpleCov.start do
    add_filter "lib/sexp.rb"
    add_filter "test"
  end
  warn "Running simplecov"
end

require "sexp_processor"
require "stringio"
require "minitest/autorun"
require "pp"

# Fake test classes:

class TestProcessor < SexpProcessor # ZenTest SKIP
  attr_accessor :auto_shift_type

  def initialize
    super
    self.require_empty = false
    self.auto_shift_type = false
  end

  def process_acc1 exp
    out = self.expected.new(:acc2, exp.thing_three, exp.thing_two, exp.thing_one)
    exp.clear
    out
  end

  def process_acc2 exp
    out = s()
    out << exp.thing_one
  end

  def process_specific exp
    _, *data = exp
    s(:blah, *data.map { |x| process x })
  end

  def process_strip exp
    exp.deep_clone
  end

  def process_nonempty exp
    s(*exp)
  end

  def process_broken exp
    result = [*exp]
    exp.clear
    result
  end

  def process_expected exp
    exp.clear
    {}
  end

  def process_string exp
    exp.sexp_type
  end

  def rewrite_rewritable exp # (a b c) => (a c b)
    a, b, c = exp
    s(a, c, b)
  end

  def process_rewritable exp
    _, *data = exp

    @n ||= 0
    result = s(:rewritten, *data.map { |x| process x }, @n)
    @n += 1

    result
  end

  def rewrite_major_rewrite exp
    exp.sexp_type = :rewritable
    exp
  end
end

class TestProcessorDefault < SexpProcessor # ZenTest SKIP
  def initialize
    super
    self.default_method = :def_method
  end

  def def_method exp
    exp.clear
    self.expected.new(42)
  end
end

# Real test classes:

class TestSexpProcessor < Minitest::Test

  def setup
    @processor = TestProcessor.new
  end

  def test_process_specific
    a = s(:specific, s(:x, 1), s(:y, 2), s(:z, 3))
    expected = s(:blah, s(:x, 1), s(:y, 2), s(:z, 3))
    assert_equal(expected, @processor.process(a))
  end

  def test_process_generic
    a = s(:blah, 1, 2, 3)
    expected = a.deep_clone
    assert_equal(expected, @processor.process(a))
  end

  def test_process_default
    @processor = TestProcessorDefault.new
    @processor.warn_on_default = false

    a = s(:blah, 1, 2, 3)
    assert_equal(@processor.expected.new(42), @processor.process(a))
  end

  def test_process_not_sexp
    @processor = TestProcessor.new
    @processor.warn_on_default = false

    assert_raises SexpTypeError do
      @processor.process(s(:broken, 1, 2, 3))
    end
  end

  def test_process_unsupported_wrong
    @processor = TestProcessor.new
    @processor.unsupported << :strip

    assert_raises UnsupportedNodeError do
      @processor.process(s(:whatever))
    end
  end

  def test_unsupported_equal
    @processor.strict = true
    @processor.unsupported = [ :unsupported ]
    assert_raises UnsupportedNodeError do
      @processor.process(s(:unsupported, 42))
    end
  end

  def test_strict
    @processor.strict = true
    assert_raises UnknownNodeError do
      @processor.process(s(:blah, 1, 2, 3))
    end
  end

  def test_strict=; skip; end # handled

  def test_require_empty_false
    @processor.require_empty = false

    assert_equal s(:nonempty, 1, 2, 3), @processor.process(s(:nonempty, 1, 2, 3))
  end

  def test_require_empty_true
    assert_raises NotEmptyError do
      @processor.require_empty = true
      @processor.process(s(:nonempty, 1, 2, 3))
    end
  end

  def test_require_empty=; skip; end # handled

  def test_process_strip
    @processor.auto_shift_type = true
    assert_equal([1, 2, 3], @processor.process(s(:strip, 1, 2, 3)))
  end

  def test_rewrite
    assert_equal(s(:rewritable, :b, :a),
                 @processor.rewrite(s(:rewritable, :a, :b)))
  end

  def test_rewrite_different_type
    assert_equal(s(:rewritable, :b, :a),
                 @processor.rewrite(s(:major_rewrite, :a, :b)))
  end

  def test_rewrite_deep
    assert_equal(s(:specific, s(:rewritable, :b, :a)),
                 @processor.rewrite(s(:specific, s(:rewritable, :a, :b))))
  end

  def test_rewrite_not_empty
    insert = s(:rewritable, 1, 2, 2)
    expect = s(:rewritable, 2, 1)
    result = @processor.rewrite(insert)
    assert_equal(expect, result)
  end

  def test_process_rewrite
    assert_equal(s(:rewritten, s(:y, 2), s(:x, 1), 0),
                 @processor.process(s(:rewritable, s(:x, 1), s(:y, 2))))
  end

  def test_process_rewrite_deep
    assert_equal(s(:blah, s(:rewritten, s(:b), s(:a), 0)),
                 @processor.process(s(:specific, s(:rewritable, s(:a), s(:b)))))
  end

  def test_rewrite_depth_first
    inn = s(:specific,
            s(:rewritable,
              s(:a),
              s(:rewritable,
                s(:rewritable, s(:b), s(:c)),
                s(:d))))
    out = s(:specific,
            s(:rewritable,
              s(:rewritable,
                s(:d),
                s(:rewritable, s(:c), s(:b))),
              s(:a)))

    assert_equal(out, @processor.rewrite(inn))
  end

  def test_process_rewrite_depth_first
    inn = s(:specific,
            s(:rewritable,
              s(:a),
              s(:rewritable,
                s(:rewritable, s(:b), s(:c)),
                s(:d))))
    out = s(:blah,
            s(:rewritten,
              s(:rewritten,
                s(:d),
                s(:rewritten, s(:c), s(:b), 0), 1),
              s(:a), 2))

    assert_equal(out, @processor.process(inn))
  end

  def test_assert_type_hit
    assert_nil @processor.assert_type(s(:blah, 1, 2, 3), :blah)
  end

  def test_assert_type_miss
    assert_raises SexpTypeError do
      @processor.assert_type(s(:thingy, 1, 2, 3), :blah)
    end
  end

  def test_generate
    skip "nothing to test at this time... soon."
  end

  def test_auto_shift_type
    @processor.auto_shift_type = false
    assert_equal(false, @processor.auto_shift_type)
    @processor.auto_shift_type = true
    assert_equal(true, @processor.auto_shift_type)
  end

  def test_auto_shift_type_equal; skip; end # handled

  def test_default_method
    # default functionality tested in process_default
    assert_nil @processor.default_method
    @processor.default_method = :something
    assert_equal :something, @processor.default_method
  end

  def test_default_method=; skip; end # handled

  def test_expected
    assert_equal Sexp, @processor.expected
    assert_raises SexpTypeError do
      @processor.process(s(:expected))           # should raise
    end

    @processor.process(s(:str, "string"))       # shouldn't raise

    @processor.expected = Hash
    assert_equal Hash, @processor.expected
    assert !(Hash === s()), "Hash === s() should not be true"

    assert_raises SexpTypeError do
      @processor.process(s(:string, "string"))     # should raise
    end

    @processor.process(s(:expected))        # shouldn't raise
  end

  def test_expected=; skip; end # handled

  # Not Testing:
  def test_debug; skip; end
  def test_debug=; skip; end
  def test_warn_on_default; skip; end
  def test_warn_on_default=; skip; end

end

class TestMethodBasedSexpProcessor < Minitest::Test
  attr_accessor :processor

  def setup
    self.processor = MethodBasedSexpProcessor.new
  end

  def test_in_klass
    assert_empty processor.class_stack

    processor.in_method "method", "file", 42 do
      processor.in_klass "xxx::yyy" do
        assert_equal ["xxx::yyy"], processor.class_stack
        assert_empty processor.method_stack
      end
    end

    assert_empty processor.class_stack
  end

  def test_in_method
    assert_empty processor.method_stack

    processor.in_method "xxx", "file.rb", 42 do
      assert_equal ["xxx"], processor.method_stack
    end

    assert_empty processor.method_stack

    expected = { "main#xxx" => "file.rb:42" }
    assert_equal expected, processor.method_locations
  end

  def test_in_method_line_max
    assert_empty processor.method_stack

    processor.in_method "xxx", "file.rb", 42, 44 do
      assert_equal ["xxx"], processor.method_stack
    end

    assert_empty processor.method_stack

    expected = { "main#xxx" => "file.rb:42-44" }
    assert_equal expected, processor.method_locations
  end

  def test_klass_name
    assert_equal :main, processor.klass_name

    processor.class_stack << "whatevs" << "flog"
    assert_equal "flog::whatevs", processor.klass_name
  end

  def test_klass_name_sexp
    processor.in_klass s(:colon2, s(:const, :X), :Y) do
      assert_equal "X::Y", processor.klass_name
    end

    processor.in_klass s(:colon3, :Y) do
      assert_equal "Y", processor.klass_name
    end
  end

  def test_method_name
    assert_equal "#none", processor.method_name

    processor.method_stack << "whatevs"
    assert_equal "#whatevs", processor.method_name
  end

  def test_method_name_cls
    assert_equal "#none", processor.method_name

    processor.method_stack << "::whatevs"
    assert_equal "::whatevs", processor.method_name
  end

  def test_signature
    assert_equal "main#none", processor.signature

    processor.class_stack << "X"
    assert_equal "X#none", processor.signature

    processor.method_stack << "y"
    assert_equal "X#y", processor.signature

    processor.class_stack.shift
    assert_equal "main#y", processor.signature
  end
end
