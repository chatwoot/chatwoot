$TESTING = true

require "minitest/autorun"
require "sexp_processor"

class TestEnvironment < Minitest::Test

  def setup
    @env = SexpProcessor::Environment.new
  end

  def test_all
    @env.scope do
      @env[:x] = 42

      @env.scope do
        @env[:y] = 3
        @env[:x] = Math::PI

        expected = { :x => Math::PI, :y => 3 }
        assert_equal expected, @env.all
      end

      expected = { :x => Math::PI }
      assert_equal expected, @env.all
    end
  end

  def test_depth
    assert_equal 1, @env.depth

    @env.scope do
      assert_equal 2, @env.depth
    end

    assert_equal 1, @env.depth
  end

  def test_index
    test_index_equals
  end

  def test_index_unknown
    assert_nil @env[:unknown]
  end

  def test_index_out_of_scope
    @env.scope do
      @env[:var] = 42
      assert_equal 42, @env[:var]
    end

    assert_nil @env[:var]
  end

  def test_index_equals
    @env[:var] = 42

    assert_equal 42, @env[:var]
  end

  def test_lookup_scope
    @env[:var] = 42
    assert_equal 42, @env[:var]

    @env.scope do
      assert_equal 42, @env[:var]
    end
  end

  def test_scope
    @env[:var] = 42
    assert_equal 42, @env[:var]

    @env.scope do
      @env[:var] = Math::PI
      assert_in_epsilon Math::PI, @env[:var]
    end

    assert_in_epsilon Math::PI, @env[:var]
  end

  def test_current_shadow
    @env[:var] = 42
    assert_equal 42, @env[:var]

    @env.scope do
      @env.current[:var] = 23
      assert_equal 23, @env[:var]
    end

    assert_equal 42, @env[:var]
  end
end
