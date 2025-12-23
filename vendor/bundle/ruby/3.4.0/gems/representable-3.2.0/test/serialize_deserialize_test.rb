require 'test_helper'

class SerializeDeserializeTest < BaseTest
  subject { Struct.new(:song).new.extend(representer) }

  describe "deserialize" do
    representer! do
      property :song,
        :instance => lambda { |options| options[:input].to_s.upcase },
        :prepare  => lambda { |options| options[:input] },
        :deserialize => lambda { |options|
          "#{options[:input]} #{options[:fragment]} #{options[:user_options].inspect}"
        }
    end

    it { _(subject.from_hash({"song" => Object}, user_options: {volume: 9}).song).must_equal "OBJECT Object {:volume=>9}" }
  end

  describe "serialize" do
    representer! do
      property :song,
        :representable => true,
        :prepare  => lambda { |options| options[:fragment] },
        :serialize => lambda { |options|
          "#{options[:input]} #{options[:user_options].inspect}"
        }
    end

    before { subject.song = "Arrested In Shanghai" }

    it { _(subject.to_hash(user_options: {volume: 9})).must_equal({"song"=>"Arrested In Shanghai {:volume=>9}"}) }
  end
end