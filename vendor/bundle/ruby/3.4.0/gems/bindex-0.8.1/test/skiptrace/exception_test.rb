require 'test_helper'

module Skiptrace
  class ExceptionTest < Test
    test 'bindings returns all the bindings of where the error originated' do
      exc = FlatFixture.()

      assert_equal 4, exc.bindings.first.source_location.last
    end

    test 'bindings returns all the bindings of where a custom error originate' do
      exc = CustomErrorFixture.()

      assert_equal 6, exc.bindings.first.source_location.last
    end

    test 'bindings goes down the stack' do
      exc = BasicNestedFixture.()

      assert_equal 14, exc.bindings.first.source_location.last
    end

    test 'bindings inside of an eval' do
      exc = EvalNestedFixture.()

      assert_equal 14, exc.bindings.first.source_location.last
    end

    test "re-raising doesn't lose bindings information" do
      exc = ReraisedFixture.()

      assert_equal 6, exc.bindings.first.source_location.last
    end

    test 'bindings is empty when exception is still not raised' do
      exc = RuntimeError.new

      assert_equal [], exc.bindings
    end

    test 'bindings is empty when set backtrace is badly called' do
      exc = RuntimeError.new

      # Exception#set_backtrace expects a string or array of strings. If the
      # input isn't like this it will raise a TypeError.
      assert_raises(TypeError) do
        exc.set_backtrace([nil])
      end

      assert_equal [], exc.bindings
    end

    test 'binding_locations maps closely to backtrace_locations' do
      exc = FlatFixture.()

      exc.binding_locations.first.tap do |location|
        assert_equal 4, location.lineno
        assert_equal exc, location.binding.eval('exc')
      end

      exc.binding_locations[1].tap do |location|
        assert_equal 54, location.lineno
        assert_equal exc, location.binding.eval('exc')
      end
    end
  end
end
