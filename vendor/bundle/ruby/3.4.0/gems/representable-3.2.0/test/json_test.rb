require 'test_helper'
require 'json'

module JsonTest
class JSONPublicMethodsTest < Minitest::Spec
  #---
  # from_json
  class BandRepresenter < Representable::Decorator
    include Representable::JSON
    property :id
    property :name
  end

  let(:json) { '{"id":1,"name":"Rancid"}' }

  it { _(BandRepresenter.new(Band.new).from_json(json)[:id, :name]).must_equal [1, "Rancid"] }
  it { _(BandRepresenter.new(Band.new).parse(json)[:id, :name]).must_equal [1, "Rancid"] }

  #---
  # to_json
  let(:band) { Band.new(1, "Rancid") }

  it { _(BandRepresenter.new(band).to_json).must_equal json }
  it { _(BandRepresenter.new(band).render).must_equal json }
end

  class APITest < MiniTest::Spec
    Json = Representable::JSON
    Def = Representable::Definition


    describe "JSON module" do
      before do
        @Band = Class.new do
          include Representable::JSON
          property :name
          property :label
          attr_accessor :name, :label

          def initialize(name=nil)
            self.name = name if name
          end
        end

        @band = @Band.new
      end


      describe "#from_json" do
        before do
          @band = @Band.new
          @json  = {:name => "Nofx", :label => "NOFX"}.to_json
        end

        it "parses JSON and assigns properties" do
          @band.from_json(@json)
          assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
        end
      end


      describe "#from_hash" do
        before do
          @band = @Band.new
          @hash  = {"name" => "Nofx", "label" => "NOFX"}
        end

        it "receives hash and assigns properties" do
          @band.from_hash(@hash)
          assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
        end

        it "respects :wrap option" do
          @band.from_hash({"band" => {"name" => "This Is A Standoff"}}, :wrap => :band)
          assert_equal "This Is A Standoff", @band.name
        end

        it "respects :wrap option over representation_wrap" do
          @Band.class_eval do
            self.representation_wrap = :group
          end
          @band.from_hash({"band" => {"name" => "This Is A Standoff"}}, :wrap => :band)
          assert_equal "This Is A Standoff", @band.name
        end
      end


      describe "#to_json" do
        it "delegates to #to_hash and returns string" do
          assert_json "{\"name\":\"Rise Against\"}", @Band.new("Rise Against").to_json
        end
      end


      describe "#to_hash" do
        it "returns unwrapped hash" do
          hash = @Band.new("Rise Against").to_hash
          assert_equal({"name"=>"Rise Against"}, hash)
        end

        it "respects :wrap option" do
          assert_equal({:band=>{"name"=>"NOFX"}}, @Band.new("NOFX").to_hash(:wrap => :band))
        end

        it "respects :wrap option over representation_wrap" do
          @Band.class_eval do
            self.representation_wrap = :group
          end
          assert_equal({:band=>{"name"=>"Rise Against"}}, @Band.new("Rise Against").to_hash(:wrap => :band))
        end
      end

      describe "#build_for" do
        it "returns TextBinding" do
          assert_kind_of Representable::Hash::Binding, Representable::Hash::Binding.build_for(Def.new(:band))
        end

        it "returns CollectionBinding" do
          assert_kind_of Representable::Hash::Binding::Collection, Representable::Hash::Binding.build_for(Def.new(:band, :collection => true))
        end
      end
    end


    describe "DCI" do
      module SongRepresenter
        include Representable::JSON
        property :name
      end

      module AlbumRepresenter
        include Representable::JSON
        property :best_song, :class => Song, :extend => SongRepresenter
        collection :songs, :class => Song, :extend => SongRepresenter
      end


      it "allows adding the representer by using #extend" do
        module BandRepresenter
          include Representable::JSON
          property :name
        end

        civ = Object.new
        civ.instance_eval do
          def name; "CIV"; end
          def name=(v)
            @name = v
          end
        end

        civ.extend(BandRepresenter)
        assert_json "{\"name\":\"CIV\"}", civ.to_json
      end

      it "extends contained models when serializing" do
        @album = Album.new([Song.new("I Hate My Brain"), mr=Song.new("Mr. Charisma")], mr)
        @album.extend(AlbumRepresenter)

        assert_json "{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}", @album.to_json
      end

      it "extends contained models when deserializing" do
        #@album = Album.new(Song.new("I Hate My Brain"), Song.new("Mr. Charisma"))
        @album = Album.new
        @album.extend(AlbumRepresenter)

        @album.from_json("{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}")
        assert_equal "Mr. Charisma", @album.best_song.name
      end
    end
  end


  class PropertyTest < MiniTest::Spec
    describe "property :name" do
      class Band
        include Representable::JSON
        property :name
        attr_accessor :name
      end

      it "#from_json creates correct accessors" do
        band = Band.new.from_json({:name => "Bombshell Rocks"}.to_json)
        assert_equal "Bombshell Rocks", band.name
      end

      it "#to_json serializes correctly" do
        band = Band.new
        band.name = "Cigar"

        assert_json '{"name":"Cigar"}', band.to_json
      end
    end

    describe ":class => Item" do
      class Label
        include Representable::JSON
        property :name
        attr_accessor :name
      end

      class Album
        include Representable::JSON
        property :label, :class => Label
        attr_accessor :label
      end

      it "#from_json creates one Item instance" do
        album = Album.new.from_json('{"label":{"name":"Fat Wreck"}}')
        assert_equal "Fat Wreck", album.label.name
      end

      it "#to_json serializes" do
        label = Label.new; label.name = "Fat Wreck"
        album = Album.new; album.label = label

        assert_json '{"label":{"name":"Fat Wreck"}}', album.to_json
      end

      describe ":different_name, :class => Label" do
        before do
          @Album = Class.new do
            include Representable::JSON
            property :seller, :class => Label
            attr_accessor :seller
          end
        end

        it "#to_xml respects the different name" do
          label = Label.new; label.name = "Fat Wreck"
          album = @Album.new; album.seller = label

          assert_json "{\"seller\":{\"name\":\"Fat Wreck\"}}", album.to_json(:wrap => false)
        end
      end
    end

    describe ":as => :songName" do
      class Song
        include Representable::JSON
        property :name, :as => :songName
        attr_accessor :name
      end

      it "respects :as in #from_json" do
        song = Song.new.from_json({:songName => "Run To The Hills"}.to_json)
        assert_equal "Run To The Hills", song.name
      end

      it "respects :as in #to_json" do
        song = Song.new; song.name = "22 Acacia Avenue"
        assert_json '{"songName":"22 Acacia Avenue"}', song.to_json
      end
    end
  end

  class CollectionTest < MiniTest::Spec
    describe "collection :name" do
      class CD
        include Representable::JSON
        collection :songs
        attr_accessor :songs
      end

      it "#from_json creates correct accessors" do
        cd = CD.new.from_json({:songs => ["Out in the cold", "Microphone"]}.to_json)
        assert_equal ["Out in the cold", "Microphone"], cd.songs
      end

      it "zzz#to_json serializes correctly" do
        cd = CD.new
        cd.songs = ["Out in the cold", "Microphone"]

        assert_json '{"songs":["Out in the cold","Microphone"]}', cd.to_json
      end
    end

    describe "collection :name, :class => Band" do
      class Band
        include Representable::JSON
        property :name
        attr_accessor :name

        def initialize(name="")
          self.name = name
        end
      end

      class Compilation
        include Representable::JSON
        collection :bands, :class => Band
        attr_accessor :bands
      end

      describe "#from_json" do
        it "pushes collection items to array" do
          cd = Compilation.new.from_json({:bands => [
            {:name => "Cobra Skulls"},
            {:name => "Diesel Boy"}]}.to_json)
          assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
        end
      end

      it "responds to #to_json" do
        cd = Compilation.new
        cd.bands = [Band.new("Diesel Boy"), Band.new("Bad Religion")]

        assert_json '{"bands":[{"name":"Diesel Boy"},{"name":"Bad Religion"}]}', cd.to_json
      end
    end


    describe ":as => :songList" do
      class Songs
        include Representable::JSON
        collection :tracks, :as => :songList
        attr_accessor :tracks
      end

      it "respects :as in #from_json" do
        songs = Songs.new.from_json({:songList => ["Out in the cold", "Microphone"]}.to_json)
        assert_equal ["Out in the cold", "Microphone"], songs.tracks
      end

      it "respects option in #to_json" do
        songs = Songs.new
        songs.tracks = ["Out in the cold", "Microphone"]

        assert_json '{"songList":["Out in the cold","Microphone"]}', songs.to_json
      end
    end
  end

  class HashTest < MiniTest::Spec
    describe "hash :songs" do
      representer!(:module => Representable::JSON) do
        hash :songs
      end

      subject { OpenStruct.new.extend(representer) }

      it "renders with #to_json" do
        subject.songs = {:one => "65", :two => "Emo Boy"}
        assert_json "{\"songs\":{\"one\":\"65\",\"two\":\"Emo Boy\"}}", subject.to_json
      end

      it "parses with #from_json" do
        assert_equal({"one" => "65", "two" => ["Emo Boy"]}, subject.from_json("{\"songs\":{\"one\":\"65\",\"two\":[\"Emo Boy\"]}}").songs)
      end
    end

    describe "hash :songs, :class => Song" do
      representer!(:module => Representable::JSON) do
        hash :songs, :extend => Module.new { include Representable::JSON; property :name }, :class => Song
      end

      it "renders" do
        _(OpenStruct.new(:songs => {"7" => Song.new("Contemplation")}).extend(representer).to_hash).must_equal("songs"=>{"7"=>{"name"=>"Contemplation"}})
      end

      describe "parsing" do
        subject { OpenStruct.new.extend(representer) }
        let(:hsh) { {"7"=>{"name"=>"Contemplation"}} }

        it "parses incoming hash" do
          _(subject.from_hash("songs"=>hsh).songs).must_equal({"7"=>Song.new("Contemplation")})
        end

        it "doesn't modify the incoming hash" do
          subject.from_hash("songs"=> incoming_hash = hsh.dup)
          _(hsh).must_equal incoming_hash
        end
      end
    end
  end
end
