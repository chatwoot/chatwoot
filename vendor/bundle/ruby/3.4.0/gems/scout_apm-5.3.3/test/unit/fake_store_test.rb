require 'test_helper'

class FakeStoreTest < Minitest::Test
  def test_responds_to_same_instance_methods_as_store
    fs = ScoutApm::FakeStore.new
    s = ScoutApm::Store.new(ScoutApm::AgentContext.new)

    assert_equal [], s.methods - fs.methods
  end
end
