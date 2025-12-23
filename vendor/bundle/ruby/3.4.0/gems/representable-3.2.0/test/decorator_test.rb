require 'test_helper'

class DecoratorTest < MiniTest::Spec
  class SongRepresentation < Representable::Decorator
    include Representable::JSON
    property :name
  end

  class AlbumRepresentation < Representable::Decorator
    include Representable::JSON

    collection :songs, :class => Song, :extend => SongRepresentation
  end

  class RatingRepresentation < Representable::Decorator
    include Representable::JSON

    property :system
    property :value
  end

  let(:song) { Song.new("Mama, I'm Coming Home") }
  let(:album) { Album.new([song]) }

  let(:rating) { OpenStruct.new(system: 'MPAA', value: 'R') }

  describe "inheritance" do
    let(:inherited_decorator) do
      Class.new(AlbumRepresentation) do
        property :best_song
      end.new(Album.new([song], "Stand Up"))
    end

    it { _(inherited_decorator.to_hash).must_equal({"songs"=>[{"name"=>"Mama, I'm Coming Home"}], "best_song"=>"Stand Up"}) }
  end

  let(:decorator) { AlbumRepresentation.new(album) }

  let(:rating_decorator) { RatingRepresentation.new(rating) }

  it "renders" do
    _(decorator.to_hash).must_equal({"songs"=>[{"name"=>"Mama, I'm Coming Home"}]})
    _(album).wont_respond_to :to_hash
    _(song).wont_respond_to :to_hash # DISCUSS: weak test, how to assert blank slate?
    # no @representable_attrs in decorated objects
    _(song).wont_be(:instance_variable_defined?, :@representable_attrs)

    _(rating_decorator.to_hash).must_equal({"system" => "MPAA", "value" => "R"})
  end

  describe "#from_hash" do
    it "returns represented" do
      _(decorator.from_hash({"songs"=>[{"name"=>"Mama, I'm Coming Home"}]})).must_equal album
    end

    it "parses" do
      decorator.from_hash({"songs"=>[{"name"=>"Atomic Garden"}]})
      _(album.songs.first).must_be_kind_of Song
      _(album.songs).must_equal [Song.new("Atomic Garden")]
      _(album).wont_respond_to :to_hash
      _(song).wont_respond_to :to_hash # DISCUSS: weak test, how to assert blank slate?
    end
  end

  describe "#decorated" do
    it "is aliased to #represented" do
      _(AlbumRepresentation.prepare(album).decorated).must_equal album
    end
  end


  describe "inline decorators" do
    representer!(decorator: true) do
      collection :songs, :class => Song do
        property :name
      end
    end

    it "does not pollute represented" do
      representer.new(album).from_hash({"songs"=>[{"name"=>"Atomic Garden"}]})

      # no @representable_attrs in decorated objects
      _(song).wont_be(:instance_variable_defined?, :@representable_attrs)
      _(album).wont_be(:instance_variable_defined?, :@representable_attrs)
    end
  end
end

require "uber/inheritable_attr"
class InheritanceWithDecoratorTest < MiniTest::Spec
  class Twin
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Representable::Decorator){ include Representable::Hash }
  end

  class Album < Twin
    representer_class.property :title # Twin.representer_class.clone
  end

  class Song < Twin # Twin.representer_class.clone
  end

  it do
    _(Twin.representer_class.definitions.size).must_equal 0
    _(Album.representer_class.definitions.size).must_equal 1
    _(Song.representer_class.definitions.size).must_equal 0
  end
end