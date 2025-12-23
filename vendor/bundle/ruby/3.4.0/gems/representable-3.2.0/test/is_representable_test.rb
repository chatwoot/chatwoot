require 'test_helper'

class IsRepresentableTest < BaseTest
  describe "representable: false, extend:" do
    representer!(:inject => :song_representer) do
      property :song,
        :representable => false,
        :extend        => song_representer
    end

    it "does extend but doesn't call #to_hash" do
      _(Struct.new(:song).new(song = Object.new).extend(representer).
        to_hash).must_equal("song" => song)
      _(song).must_be_kind_of Representable::Hash
    end
  end


  describe "representable: true, no extend:" do
    representer!(:inject => :song_representer) do
      property :song,
        :representable => true
    end

    it "doesn't extend but calls #to_hash" do
      song = Object.new
      song.instance_eval do
        def to_hash(*)
          1
        end
      end

      _(Struct.new(:song).new(song).extend(representer).
        to_hash).must_equal("song" => 1)
      _(song).wont_be_kind_of Representable::Hash
    end
  end

  # TODO: TEST implement for from_hash.

  describe "representable: false, with class:" do
    representer!(:inject => :song_representer) do
      property :song,
        :representable => false, :class => OpenStruct, :extend => song_representer
    end

    it "does extend but doesn't call #from_hash" do
      hit = Struct.new(:song).new.extend(representer).
        from_hash("song" => 1)

      _(hit.song).must_equal OpenStruct.new
      _(hit.song).must_be_kind_of Representable::Hash
    end
  end


  describe "representable: true, without extend: but class:" do
    SongReader = Class.new do
      def from_hash(*)
        "Piano?"
      end
    end

    representer!(:inject => :song_representer) do
      property :song,
        :representable => true, :class => SongReader
    end

    it "doesn't extend but calls #from_hash" do
      hit = Struct.new(:song).new.extend(representer).
        from_hash("song" => "Sonata No.2")

      _(hit.song).must_equal "Piano?"
      _(hit.song).wont_be_kind_of Representable::Hash
    end
  end
end