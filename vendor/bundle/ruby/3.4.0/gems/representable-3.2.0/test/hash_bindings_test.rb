require 'test_helper'

class HashBindingTest < MiniTest::Spec
  module SongRepresenter
    include Representable::JSON
    property :name
  end

  class SongWithRepresenter < ::Song
    include Representable
    include SongRepresenter
  end


  describe "PropertyBinding" do
    describe "#read" do
      before do
        @property = Representable::Hash::Binding.new(Representable::Definition.new(:song))
      end

      it "returns fragment if present" do
        assert_equal "Stick The Flag Up Your Goddamn Ass, You Sonofabitch", @property.read({"song" => "Stick The Flag Up Your Goddamn Ass, You Sonofabitch"}, "song")
        assert_equal "", @property.read({"song" => ""}, "song")
        assert_nil @property.read({"song" => nil}, "song")
      end

      it "returns FRAGMENT_NOT_FOUND if not in document" do
        assert_equal Representable::Binding::FragmentNotFound, @property.read({}, "song")
      end

    end
  end


  describe "CollectionBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::Hash::Binding::Collection.new(Representable::Definition.new(:songs, :collection => true))
      end

      it "extracts with #read" do
        assert_equal ["The Gargoyle", "Bronx"], @property.read({"songs" => ["The Gargoyle", "Bronx"]}, "songs")
      end

      it "inserts with #write" do
        doc = {}
        assert_equal(["The Gargoyle", "Bronx"], @property.write(doc, ["The Gargoyle", "Bronx"], "songs"))
        assert_equal({"songs"=>["The Gargoyle", "Bronx"]}, doc)
      end
    end
  end




  describe "HashBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::Hash::Binding.new(Representable::Definition.new(:songs, :hash => true))
      end

      it "extracts with #read" do
        assert_equal({"first" => "The Gargoyle", "second" => "Bronx"} , @property.read({"songs" => {"first" => "The Gargoyle", "second" => "Bronx"}}, "songs"))
      end

      it "inserts with #write" do
        doc = {}
        assert_equal({"first" => "The Gargoyle", "second" => "Bronx"}, @property.write(doc, {"first" => "The Gargoyle", "second" => "Bronx"}, "songs"))
        assert_equal({"songs"=>{"first" => "The Gargoyle", "second" => "Bronx"}}, doc)
      end
    end

    describe "with objects" do
      before do
        @property = Representable::Hash::Binding.new(Representable::Definition.new(:songs, :hash => true, :class => Song, :extend => SongRepresenter))
      end

      it "doesn't change the represented hash in #write" do
        song = Song.new("Better Than That")
        hash = {"first" => song}
        @property.write({}, hash, "song")
        assert_equal({"first" => song}, hash)
      end
    end

  end
end
