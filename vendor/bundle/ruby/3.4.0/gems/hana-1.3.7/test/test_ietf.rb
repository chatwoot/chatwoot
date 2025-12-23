require 'helper'

module Hana
  class TestIETF < TestCase
    filename = File.join TESTDIR, 'json-patch-tests', 'tests.json'
    include read_test_json_file filename
  end

  class TestSpec < TestCase
    filename = File.join TESTDIR, 'json-patch-tests', 'spec_tests.json'
    include read_test_json_file filename

    skip(/A\.13/, 'This test depends on the JSON parser')
  end

  class MyTests < TestCase
    filename = File.join TESTDIR, 'mine.json'
    include read_test_json_file filename
  end
end
