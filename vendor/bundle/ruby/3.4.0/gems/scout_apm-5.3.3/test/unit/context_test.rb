require 'test_helper'

require 'scout_apm/context'

class ContextText < Minitest::Test
  def test_ignore_nil_value
    context = ScoutApm::Context.new(ScoutApm::AgentContext.new)
    assert hash = context.add(:nil_key => nil, :org => 'org')
    assert_equal ({:org => 'org'}), hash
  end

  def test_ignore_nil_key
    context = ScoutApm::Context.new(ScoutApm::AgentContext.new)
    assert hash = context.add(nil => nil, :org => 'org')
    assert_equal ({:org => 'org'}), hash
  end

  def test_ignore_unsupported_value_type
    context = ScoutApm::Context.new(ScoutApm::AgentContext.new)
    assert hash = context.add(:array => [1,2,3,4], :org => 'org')
    assert_equal ({:org => 'org'}), hash
  end

  def test_ignore_unsupported_key_type
    context = ScoutApm::Context.new(ScoutApm::AgentContext.new)
    assert hash = context.add([1,2,3,4] => 'hey', :org => 'org')
    assert_equal ({:org => 'org'}), hash
  end
end

