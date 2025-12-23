require 'minitest/autorun'
require 'hana'
require 'json'

module Hana
  class TestCase < Minitest::Test
    TESTDIR = File.dirname File.expand_path __FILE__

    def self.read_test_json_file file
      Module.new {
        tests = JSON.load File.read file
        tests.each_with_index do |test, i|
          next unless test['doc']

          method = "test_#{test['comment'] || i }"
          loop do
            if method_defined? method
              method = "test_#{test['comment'] || i } x"
            else
              break
            end
          end

          define_method(method) do
            skip "disabled" if test['disabled']

            doc   = test['doc']
            patch = test['patch']

            patch = Hana::Patch.new patch

            if test['error']
              assert_raises(*ex(test['error']), test['error']) do
                patch.apply doc
              end
            else
              assert_equal(test['expected'] || doc, patch.apply(doc))
            end
          end
        end
      }
    end

    def self.skip regexp, message
      instance_methods.grep(regexp).each do |method|
        define_method(method) { skip message }
      end
    end

    private

    def ex msg
      case msg
      when /Out of bounds/i then [Hana::Patch::OutOfBoundsException]
      when /index is greater than/i then [Hana::Patch::OutOfBoundsException]
      when /Object operation on array/ then
        [Hana::Patch::ObjectOperationOnArrayException]
      when /test op shouldn't get array element/ then
        [Hana::Patch::IndexError, Hana::Patch::ObjectOperationOnArrayException]
      when /bad number$/ then
        [Hana::Patch::IndexError, Hana::Patch::ObjectOperationOnArrayException]
      when /removing a nonexistent (field|index)/ then
        [Hana::Patch::MissingTargetException, Hana::Patch::OutOfBoundsException]
      when /test op should reject the array value, it has leading zeros/ then
        [Hana::Patch::IndexError]
      when /missing '(from|value)' parameter/ then
        [KeyError]
      when /Unrecognized op 'spam'/ then
        [Hana::Patch::Exception]
      when /missing 'path'|null is not valid value for 'path'/ then
        [Hana::Patch::InvalidPath]
      when /missing|non-existent/ then
        [Hana::Patch::MissingTargetException]
      when /JSON Pointer should start with a slash/ then
        [Hana::Pointer::FormatError]
      else
        [Hana::Patch::FailedTestException]
      end
    end
  end
end
