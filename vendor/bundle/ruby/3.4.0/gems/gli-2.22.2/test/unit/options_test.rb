require_relative "test_helper"

class OptiosnTest < Minitest::Test
  include TestHelper

  def test_by_method
    o = GLI::Options.new
    o.name = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end

  def test_by_string
    o = GLI::Options.new
    o['name'] = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end

  def test_by_symbol
    o = GLI::Options.new
    o[:name] = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end

  def test_map_defers_to_underlying_map
    o = GLI::Options.new
    o[:foo] = 'bar'
    o[:blah] = 'crud'

    result = Hash[o.map { |k,v|
      [k,v.upcase]
    }]
    assert_equal 2,result.size
    assert_equal "BAR",result[:foo]
    assert_equal "CRUD",result[:blah]
  end

end
