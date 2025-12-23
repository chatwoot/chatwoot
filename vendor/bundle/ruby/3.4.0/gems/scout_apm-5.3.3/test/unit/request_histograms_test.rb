require 'test_helper'

require 'scout_apm/request_histograms'

class RequestHistogramsTest < Minitest::Test
  def test_as_json_without_activesupport
    rh = ScoutApm::RequestHistograms.new

    rh.add("foo", 1)
    rh.add("foo", 2)
    rh.add("bar", 3)

    j = rh.as_json
    assert_equal 2, j.size
    assert_equal ["bar", "foo"], j.keys.sort
  end
end
