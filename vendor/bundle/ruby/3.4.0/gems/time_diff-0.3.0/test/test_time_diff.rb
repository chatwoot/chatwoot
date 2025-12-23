require 'helper'
require 'time'

class TestTimeDiff < Test::Unit::TestCase
  should "return the time differnce in displayable format" do
    assert_test_scenarios(Time.parse('2011-03-06'), Time.parse('2011-03-07'), {:year => 0, :month => 0, :week => 0, :day => 1, :hour => 0, :minute => 0, :second => 0, :diff => '1 day and 00:00:00'})
    assert_test_scenarios(Time.parse('2011-03-06'), Time.parse('2011-04-08'), {:year => 0, :month => 1, :week => 0, :day => 3, :hour => 0, :minute => 0, :second => 0, :diff => '1 month, 3 days and 00:00:00'})
    assert_test_scenarios(Time.parse('2011-03-06 12:30:00'), Time.parse('2011-03-07 12:30:30'), {:year => 0, :month => 0, :week => 0, :day => 1, :hour => 0, :minute => 0, :second => 30, :diff => '1 day and 00:00:30'})
    assert_test_scenarios(Time.parse('2011-03-06'), Time.parse('2013-03-07'), {:year => 2, :month => 0, :week => 0, :day => 1, :hour => 12, :minute => 0, :second => 0, :diff => '2 years, 1 day and 12:00:00'})
    assert_test_scenarios(Time.parse('2011-03-06'), Time.parse('2011-03-14'), {:year => 0, :month => 0, :week => 1, :day => 1, :hour => 0, :minute => 0, :second => 0, :diff => '1 week, 1 day and 00:00:00'})
    assert_test_scenarios(Time.parse('2011-03-06 12:30:00'), Time.parse('2011-03-06 12:30:30'), {:year => 0, :month => 0, :week => 0, :day => 0, :hour => 0, :minute => 0, :second => 30, :diff => '00:00:30'})
  end

  should "return the time difference in a formatted text" do
    assert_test_scenarios_for_formatted_diff(Time.parse('2010-03-06 12:30:00'), Time.parse('2011-03-07 12:30:30'), '%y, %d and %h:%m:%s', '1 year and 18:00:30')
    assert_test_scenarios_for_formatted_diff(Time.parse('2010-03-06 12:30:00'), Time.parse('2011-03-07 12:30:30'), '%d %H %N %S', '366 days 0 hours 0 minutes 30 seconds')
    assert_test_scenarios_for_formatted_diff(Time.parse('2011-03-06 12:30:00'), Time.parse('2011-03-07 12:30:30'), '%H %N %S', '24 hours 0 minutes 30 seconds')
  end

  def assert_test_scenarios(start_date, end_date, expected_result)
    date_diff = Time.diff(start_date, end_date)
    assert_equal(date_diff, expected_result)
  end

  def assert_test_scenarios_for_formatted_diff(start_date, end_date, format_string, expected_result)
    date_diff = Time.diff(start_date, end_date, format_string)
    assert_equal(date_diff[:diff], expected_result)
  end
end
