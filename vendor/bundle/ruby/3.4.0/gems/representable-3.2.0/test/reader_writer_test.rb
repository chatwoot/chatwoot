require 'test_helper'

class ReaderWriterTest < BaseTest
  representer! do
    property :name,
      :writer => lambda { |options| options[:doc]["title"] = "#{options[:user_options][:nr]}) #{options[:input]}" },
      :reader => lambda { |options| self.name = options[:doc]["title"].split(") ").last }
  end

  subject { OpenStruct.new(:name => "Disorder And Disarray").extend(representer) }

  it "uses :writer when rendering" do
    _(subject.to_hash(user_options: {nr: 14})).must_equal({"title" => "14) Disorder And Disarray"})
  end

  it "uses :reader when parsing" do
    _(subject.from_hash({"title" => "15) The Wars End"}).name).must_equal "The Wars End"
  end
end