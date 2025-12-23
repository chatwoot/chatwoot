require 'test_helper'
require 'scout_apm/utils/numbers'

class NumbersTest < Minitest::Test
  Numbers = ScoutApm::Utils::Numbers

  def test_round
    assert_equal 12, Numbers.round(12.1234567, 0)
    assert_equal 12.1, Numbers.round(12.1234567, 1)
    assert_equal 12.12, Numbers.round(12.1234567, 2)
    assert_equal 12.123, Numbers.round(12.1234567, 3)

    assert_equal 12, Numbers.round(12.0000, 2)
  end
end
