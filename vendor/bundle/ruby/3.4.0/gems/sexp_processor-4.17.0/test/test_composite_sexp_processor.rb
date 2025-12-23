$TESTING = true

require "composite_sexp_processor"
require "minitest/autorun"

class FakeProcessor1 < SexpProcessor # ZenTest SKIP

  def initialize
    super
    self.warn_on_default = false
    self.default_method = :default_processor
    self.require_empty = false
    self.expected = Array
  end

  def default_processor exp
    t, *rest = exp
    s(t, *rest.map { |s| "#{s} woot" })
  end
end

class TestCompositeSexpProcessor < Minitest::Test

  def setup
    @p = CompositeSexpProcessor.new
  end

  def test_process_default
    data = s(1, 2, 3)
    result = @p.process(data.dup)
    assert_equal(data.dup, result)
  end

  def test_process_fake1
    data = s(:x, 1, 2, 3)
    @p << FakeProcessor1.new
    result = @p.process(data.dup)
    assert_equal [:x, "1 woot", "2 woot", "3 woot"], result
  end

  def test_process_fake1_twice
    data = s(:x, 1, 2, 3)
    @p << FakeProcessor1.new
    @p << FakeProcessor1.new
    result = @p.process(data.dup)
    assert_equal [:x, "1 woot woot", "2 woot woot", "3 woot woot"], result
  end

  def test_processors
    # everything is tested by test_append
    skip
  end

  def test_append
    assert_equal([], @p.processors)

    assert_raises(ArgumentError) do
      @p << 42
    end

    fp1 = FakeProcessor1.new
    @p << fp1
    assert_equal([fp1], @p.processors)
  end

end
