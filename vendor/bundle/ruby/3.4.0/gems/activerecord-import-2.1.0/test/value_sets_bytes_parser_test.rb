# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/test_helper")

require 'activerecord-import/value_sets_parser'

describe ActiveRecord::Import::ValueSetsBytesParser do
  context "#parse - computing insert value sets" do
    let(:parser) { ActiveRecord::Import::ValueSetsBytesParser }
    let(:base_sql) { "INSERT INTO atable (a,b,c)" }
    let(:values) { ["(1,2,3)", "(2,3,4)", "(3,4,5)"] }

    context "when the max allowed bytes is 30 and the base SQL is 26 bytes" do
      it "should raise ActiveRecord::Import::ValueSetTooLargeError" do
        error = assert_raises ActiveRecord::Import::ValueSetTooLargeError do
          parser.parse values, reserved_bytes: base_sql.size, max_bytes: 30
        end
        assert_match(/33 bytes exceeds the max allowed for an insert \[30\]/, error.message)
      end
    end

    context "when the max allowed bytes is 33 and the base SQL is 26 bytes" do
      it "should return 3 value sets when given 3 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 33
        assert_equal 3, value_sets.size
      end
    end

    context "when the max allowed bytes is 40 and the base SQL is 26 bytes" do
      it "should return 3 value sets when given 3 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 40
        assert_equal 3, value_sets.size
      end
    end

    context "when the max allowed bytes is 41 and the base SQL is 26 bytes" do
      it "should return 2 value sets when given 2 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 41
        assert_equal 2, value_sets.size
      end
    end

    context "when the max allowed bytes is 48 and the base SQL is 26 bytes" do
      it "should return 2 value sets when given 2 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 48
        assert_equal 2, value_sets.size
      end
    end

    context "when the max allowed bytes is 49 and the base SQL is 26 bytes" do
      it "should return 1 value sets when given 1 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 49
        assert_equal 1, value_sets.size
      end
    end

    context "when the max allowed bytes is 999999 and the base SQL is 26 bytes" do
      it "should return 1 value sets when given 1 value sets of 7 bytes a piece" do
        value_sets = parser.parse values, reserved_bytes: base_sql.size, max_bytes: 999_999
        assert_equal 1, value_sets.size
      end
    end

    it "should properly build insert value set based on max packet allowed" do
      values = [
        "('1','2','3')",
        "('4','5','6')",
        "('7','8','9')"
      ]

      base_sql_size_in_bytes = 15
      max_bytes = 30

      value_sets = parser.parse values, reserved_bytes: base_sql_size_in_bytes, max_bytes: max_bytes
      assert_equal 3, value_sets.size, 'Three value sets were expected!'

      # Each element in the value_sets array must be an array
      value_sets.each_with_index do |e, i|
        assert_kind_of Array, e, "Element #{i} was expected to be an Array!"
      end

      # Each element in the values array should have a 1:1 correlation to the elements
      # in the returned value_sets arrays
      assert_equal values[0], value_sets[0].first
      assert_equal values[1], value_sets[1].first
      assert_equal values[2], value_sets[2].first
    end

    context "data contains multi-byte chars" do
      it "should properly build insert value set based on max packet allowed" do
        # each accented e should be 2 bytes, so each entry is 6 bytes instead of 5
        values = [
          "('é')",
          "('é')"
        ]

        base_sql_size_in_bytes = 15
        max_bytes = 26

        value_sets = parser.parse values, reserved_bytes: base_sql_size_in_bytes, max_bytes: max_bytes

        assert_equal 2, value_sets.size, 'Two value sets were expected!'
      end
    end
  end
end
