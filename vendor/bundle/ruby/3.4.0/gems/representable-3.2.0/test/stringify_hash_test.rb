require 'test_helper'

class StringifyHashTest < MiniTest::Spec
describe "#from_hash" do
  representer!(:name => :song_representer) do

    include Representable::Hash
    include Representable::Hash::AllowSymbols

    property :title
  end

  representer!(:inject => :song_representer) do
    include Representable::Hash::AllowSymbols

    property :song, :extend => song_representer, :class => OpenStruct
   end

   it "parses symbols, too" do
     _(OpenStruct.new.extend(representer).from_hash({:song => {:title => "Der Optimist"}}).song.title).must_equal "Der Optimist"
   end

   it "still parses strings" do
     _(OpenStruct.new.extend(representer).from_hash({"song" => {"title" => "Der Optimist"}}).song.title).must_equal "Der Optimist"
   end

   describe "with :wrap" do
    representer!(:inject => :song_representer) do
      include Representable::Hash::AllowSymbols

      self.representation_wrap = :album
      property :song, :extend => song_representer, :class => OpenStruct
    end

     it "parses symbols, too" do
       _(OpenStruct.new.extend(representer).from_hash({:album => {:song => {:title => "Der Optimist"}}}).song.title).must_equal "Der Optimist"
     end
   end
 end

end