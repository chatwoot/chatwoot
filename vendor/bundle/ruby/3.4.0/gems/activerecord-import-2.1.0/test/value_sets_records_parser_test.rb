# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/test_helper")

require 'activerecord-import/value_sets_parser'

describe "ActiveRecord::Import::ValueSetsRecordsParser" do
  context "#parse - computing insert value sets" do
    let(:parser) { ActiveRecord::Import::ValueSetsRecordsParser }
    let(:base_sql) { "INSERT INTO atable (a,b,c)" }
    let(:values) { ["(1,2,3)", "(2,3,4)", "(3,4,5)"] }

    context "when the max number of records is 1" do
      it "should return 3 value sets when given 3 values sets" do
        value_sets = parser.parse values, max_records: 1
        assert_equal 3, value_sets.size
      end
    end

    context "when the max number of records is 2" do
      it "should return 2 value sets when given 3 values sets" do
        value_sets = parser.parse values, max_records: 2
        assert_equal 2, value_sets.size
      end
    end

    context "when the max number of records is 3" do
      it "should return 1 value sets when given 3 values sets" do
        value_sets = parser.parse values, max_records: 3
        assert_equal 1, value_sets.size
      end
    end
  end
end
