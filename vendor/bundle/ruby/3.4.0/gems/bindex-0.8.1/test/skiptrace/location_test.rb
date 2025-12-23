require 'test_helper'

module Skiptrace
  class LocationTest < Test
    test 'behaves like Thread::Backtrace::Location' do
      native_location = caller_locations.first
      location = Skiptrace::Location.new(native_location, binding)

      assert_equal native_location.absolute_path, location.absolute_path
      assert_equal native_location.base_label, location.base_label
      assert_equal native_location.inspect, location.inspect
      assert_equal native_location.label, location.label
      assert_equal native_location.to_s, location.to_s

      assert_equal [__FILE__, __LINE__ - 8], location.binding.source_location
    end
  end
end
