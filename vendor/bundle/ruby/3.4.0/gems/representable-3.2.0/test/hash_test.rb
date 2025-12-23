require 'test_helper'

class HashPublicMethodsTest < Minitest::Spec
  #---
  # from_hash
  class BandRepresenter < Representable::Decorator
    include Representable::Hash
    property :id
    property :name
  end

  let(:data) { {"id"=>1,"name"=>"Rancid"} }

  it { _(BandRepresenter.new(Band.new).from_hash(data)[:id, :name]).must_equal [1, "Rancid"] }
  it { _(BandRepresenter.new(Band.new).parse(data)[:id, :name]).must_equal [1, "Rancid"] }

  #---
  # to_hash
  let(:band) { Band.new(1, "Rancid") }

  it { _(BandRepresenter.new(band).to_hash).must_equal data }
  it { _(BandRepresenter.new(band).render).must_equal data }
end

class HashWithScalarPropertyTest < MiniTest::Spec
  Album = Struct.new(:title)

  representer! do
    property :title
  end

  let(:album) { Album.new("Liar") }

  describe "#to_hash" do
    it "renders plain property" do
      _(album.extend(representer).to_hash).must_equal("title" => "Liar")
    end
  end


  describe "#from_hash" do
    it "parses plain property" do
      _(album.extend(representer).from_hash("title" => "This Song Is Recycled").title).must_equal "This Song Is Recycled"
    end

    # Fixes issue #115
    it "allows nil value in the incoming document and corresponding nil value for the represented" do
      album = Album.new
      _(album.title).must_be_nil
      album.extend(representer).from_hash("title" => nil)
    end
  end
end


class HashWithTypedPropertyTest < MiniTest::Spec
  Album = Struct.new(:best_song)

  representer! do
    property :best_song, :class => Song do
      property :name
    end
  end

  let(:album) { Album.new(Song.new("Liar")) }

  describe "#to_hash" do
    it "renders embedded typed property" do
      _(album.extend(representer).to_hash).must_equal("best_song" => {"name" => "Liar"})
    end
  end

  describe "#from_hash" do
    it "parses embedded typed property" do
      album.extend(representer).from_hash("best_song" => {"name" => "Go With Me"})
      _(album.best_song.name).must_equal "Go With Me"
    end

    # nested nil removes nested object.
    it do
      album = Album.new(Song.new("Pre-medicated Murder"))
      album.extend(representer).from_hash("best_song" => nil)
      _(album.best_song).must_be_nil
    end

    # nested blank hash creates blank object when not populated.
    it do
      album = Album.new#(Song.new("Pre-medicated Murder"))
      album.extend(representer).from_hash("best_song" => {})
      _(album.best_song.name).must_be_nil
    end

    # Fixes issue #115
    it "allows nil value in the incoming document and corresponding nil value for the represented" do
      album = Album.new
      album.extend(representer).from_hash("best_song" => nil)
      _(album.best_song).must_be_nil
    end
  end
end

# TODO: move to AsTest.
class HashWithTypedPropertyAndAs < MiniTest::Spec
  representer! do
    property :song, :class => Song, :as => :hit do
      property :name
    end
  end

  let(:album) { OpenStruct.new(:song => Song.new("Liar")).extend(representer) }

  it { _(album.to_hash).must_equal("hit" => {"name" => "Liar"}) }
  it { _(album.from_hash("hit" => {"name" => "Go With Me"})).must_equal OpenStruct.new(:song => Song.new("Go With Me")) }
end
  #   # describe "FIXME COMBINE WITH ABOVE with :extend and :as" do
  #   #   hash_song = Module.new do
  #   #     include Representable::XML
  #   #     self.representation_wrap = :song
  #   #     property :name
  #   #   end

  #   #   let(:hash_album) { Module.new do
  #   #     include Representable::XML
  #   #     self.representation_wrap = :album
  #   #     property :song, :extend => hash_song, :class => Song, :as => :hit
  #   #   end }

  #   #   let(:album) { OpenStruct.new(:song => Song.new("Liar")).extend(hash_album) }

  #   #   it { album.to_xml.must_equal_xml("<album><hit><name>Liar</name></hit></album>") }
  #   #   #it { album.from_hash("hit" => {"name" => "Go With Me"}).must_equal OpenStruct.new(:song => Song.new("Go With Me")) }
  #   # end
  # end



class HashWithTypedCollectionTest < MiniTest::Spec
  Album = Struct.new(:songs)

  representer! do
    collection :songs, class: Song do
      property :name
      property :track
    end
  end

  let(:album) { Album.new([Song.new("Liar", 1), Song.new("What I Know", 2)]) }

  describe "#to_hash" do
    it "renders collection of typed property" do
      _(album.extend(representer).to_hash).must_equal("songs" => [{"name" => "Liar", "track" => 1}, {"name" => "What I Know", "track" => 2}])
    end
  end

  describe "#from_hash" do
    it "parses collection of typed property" do
      _(album.extend(representer).from_hash("songs" => [{"name" => "One Shot Deal", "track" => 4},
        {"name" => "Three Way Dance", "track" => 5}])).must_equal Album.new([Song.new("One Shot Deal", 4), Song.new("Three Way Dance", 5)])
    end
  end
end

class HashWithScalarCollectionTest < MiniTest::Spec
  Album = Struct.new(:songs)
  representer! { collection :songs }

  let(:album) { Album.new(["Jackhammer", "Terrible Man"]) }


  describe "#to_hash" do
    it "renders a block style list per default" do
      _(album.extend(representer).to_hash).must_equal("songs" => ["Jackhammer", "Terrible Man"])
    end
  end


  describe "#from_hash" do
    it "parses a block style list" do
      _(album.extend(representer).from_hash("songs" => ["Off Key Melody", "Sinking"])).must_equal Album.new(["Off Key Melody", "Sinking"])
    end
  end
end
