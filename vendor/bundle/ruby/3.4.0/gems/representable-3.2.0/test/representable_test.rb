require 'test_helper'

class RepresentableTest < MiniTest::Spec
  class Band
    include Representable::Hash
    property :name
    attr_accessor :name
  end

  class PunkBand < Band
    property :street_cred
    attr_accessor :street_cred
  end

  module BandRepresentation
    include Representable

    property :name
  end

  module PunkBandRepresentation
    include Representable
    include BandRepresentation

    property :street_cred
  end


  describe "#representable_attrs" do
    describe "in module" do
      it "allows including the concrete representer module later" do
        vd = class VD
          attr_accessor :name, :street_cred
          include Representable::JSON
          include PunkBandRepresentation
        end.new
        vd.name        = "Vention Dention"
        vd.street_cred = 1
        assert_json "{\"name\":\"Vention Dention\",\"street_cred\":1}", vd.to_json
      end

      #it "allows including the concrete representer module only" do
      #  require 'representable/json'
      #  module RockBandRepresentation
      #    include Representable::JSON
      #    property :name
      #  end
      #  vd = class VH
      #    include RockBandRepresentation
      #  end.new
      #  vd.name        = "Van Halen"
      #  assert_equal "{\"name\":\"Van Halen\"}", vd.to_json
      #end
    end
  end


  describe "inheritance" do
    class CoverSong < OpenStruct
    end

    module SongRepresenter
      include Representable::Hash
      property :name
    end

    module CoverSongRepresenter
      include Representable::Hash
      include SongRepresenter
      property :by
    end

    it "merges properties from all ancestors" do
      props = {"name"=>"The Brews", "by"=>"Nofx"}
      assert_equal(props, CoverSong.new(props).extend(CoverSongRepresenter).to_hash)
    end

    it "allows mixing in multiple representers" do
      class Bodyjar
        include Representable::XML
        include Representable::JSON
        include PunkBandRepresentation

        self.representation_wrap = "band"
        attr_accessor :name, :street_cred
      end

      band = Bodyjar.new
      band.name = "Bodyjar"

      assert_json "{\"band\":{\"name\":\"Bodyjar\"}}", band.to_json
      assert_xml_equal "<band><name>Bodyjar</name></band>", band.to_xml
    end

    it "allows extending with different representers subsequentially" do
      module SongXmlRepresenter
        include Representable::XML
        property :name, :as => "name", :attribute => true
      end

      module SongJsonRepresenter
        include Representable::JSON
        property :name
      end

      @song = Song.new("Days Go By")
      assert_xml_equal "<song name=\"Days Go By\"/>", @song.extend(SongXmlRepresenter).to_xml
      assert_json "{\"name\":\"Days Go By\"}", @song.extend(SongJsonRepresenter).to_json
    end


    # test if we call super in
    #   ::inherited
    #   ::included
    #   ::extended
    module Representer
      include Representable # overrides ::inherited.
    end

    class BaseClass
      def self.inherited(subclass)
        super
        subclass.instance_eval { def other; end }
      end

      include Representable # overrides ::inherited.
      include Representer
    end

    class SubClass < BaseClass # triggers Representable::inherited, then OtherModule::inherited.
    end

    # test ::inherited.
    it do
      _(BaseClass.respond_to?(:other)).must_equal false
      _(SubClass.respond_to?(:other)).must_equal true
    end

    module DifferentIncluded
      def included(includer)
        includer.instance_eval { def different; end }
      end
    end

    module CombinedIncluded
      extend DifferentIncluded # defines ::included.
      include Representable    # overrides ::included.
    end

    class IncludingClass
      include Representable
      include CombinedIncluded
    end

    # test ::included.
    it do
      IncludingClass.respond_to?(:representable_attrs) # from Representable
      IncludingClass.respond_to?(:different)
    end
  end


  describe "#property" do
    it "doesn't modify options hash" do
      options = {}
      representer.property(:title, options)
      _(options).must_equal({})
    end

    representer! {}

    it "returns the Definition instance" do
      _(representer.property(:name)).must_be_kind_of Representable::Definition
    end
  end

  describe "#collection" do
    class RockBand < Band
      collection :albums
    end

    it "creates correct Definition" do
      assert_equal "albums", RockBand.representable_attrs.get(:albums).name
      assert RockBand.representable_attrs.get(:albums).array?
    end
  end

  describe "#hash" do
    it "also responds to the original method" do
      assert_kind_of Integer, BandRepresentation.hash
    end
  end

  class Hometown
    attr_accessor :name
  end

  module HometownRepresentable
    include Representable::JSON
    property :name
  end

  # DISCUSS: i don't like the JSON requirement here, what about some generic test module?
  class PopBand
    include Representable::JSON
    property :name
    property :groupies
    property :hometown, class: Hometown, extend: HometownRepresentable
    attr_accessor :name, :groupies, :hometown
  end

  describe "#update_properties_from" do
    before do
      @band = PopBand.new
    end

    it "copies values from document to object" do
      @band.from_hash({"name"=>"No One's Choice", "groupies"=>2})
      assert_equal "No One's Choice", @band.name
      assert_equal 2, @band.groupies
    end

    it "ignores non-writeable properties" do
      @band = Class.new(Band) { property :name; collection :founders, :writeable => false; attr_accessor :founders }.new
      @band.from_hash("name" => "Iron Maiden", "groupies" => 2, "founders" => ["Steve Harris"])
      assert_equal "Iron Maiden", @band.name
      assert_nil @band.founders
    end

    it "always returns the represented" do
      assert_equal @band, @band.from_hash({"name"=>"Nofx"})
    end

    it "includes false attributes" do
      @band.from_hash({"groupies"=>false})
      refute @band.groupies
    end

    it "ignores properties not present in the incoming document" do
      @band.instance_eval do
        def name=(*); raise "I should never be called!"; end
      end
      @band.from_hash({})
    end


    # FIXME: do we need this test with XML _and_ JSON?
    it "ignores (no-default) properties not present in the incoming document" do
      { Representable::Hash => [:from_hash, {}],
        Representable::XML  => [:from_xml,  xml(%{<band/>}).to_s]
      }.each do |format, config|
        nested_repr = Module.new do # this module is never applied. # FIXME: can we make that a simpler test?
          include format
          property :created_at
        end

        repr = Module.new do
          include format
          property :name, :class => Object, :extend => nested_repr
        end

        @band = Band.new.extend(repr)
        @band.send(config.first, config.last)
        assert_nil @band.name, "Failed in #{format}"
      end
    end

    describe "passing options" do
      module TrackRepresenter
        include Representable::Hash

      end

      representer! do
        property :track, class: OpenStruct do
          property :nr

          property :length, class: OpenStruct do
            def to_hash(options)
              {seconds: options[:user_options][:nr]}
            end

            def from_hash(hash, options)
              super.tap do
                self.seconds = options[:user_options][:nr]
              end
            end
          end

          def to_hash(options)
            super.merge({"nr" => options[:user_options][:nr]})
          end

          def from_hash(data, options)
            super.tap do
              self.nr = options[:user_options][:nr]
            end
          end
        end
      end

      it "#to_hash propagates to nested objects" do
        _(OpenStruct.new(track: OpenStruct.new(nr: 1, length: OpenStruct.new(seconds: nil))).extend(representer).extend(Representable::Debug).
          to_hash(user_options: {nr: 9})).must_equal({"track"=>{"nr"=>9, "length"=>{seconds: 9}}})
      end

      it "#from_hash propagates to nested objects" do
        song = OpenStruct.new.extend(representer).from_hash({"track"=>{"nr" => "replace me", "length"=>{"seconds"=>"replacing"}}}, user_options: {nr: 9})
        _(song.track.nr).must_equal 9
        _(song.track.length.seconds).must_equal 9
      end
    end
  end

  describe "#create_representation_with" do
    before do
      @band = PopBand.new
      @band.name = "No One's Choice"
      @band.groupies = 2
    end

    it "compiles document from properties in object" do
      assert_equal({"name"=>"No One's Choice", "groupies"=>2}, @band.to_hash)
    end

    it "ignores non-readable properties" do
      @band = Class.new(Band) { property :name; collection :founder_ids, :readable => false; attr_accessor :founder_ids }.new
      @band.name = "Iron Maiden"
      @band.founder_ids = [1,2,3]

      hash = @band.to_hash
      assert_equal({"name" => "Iron Maiden"}, hash)
    end

    it "does not write nil attributes" do
      @band.groupies = nil
      assert_equal({"name"=>"No One's Choice"}, @band.to_hash)
    end

    it "writes false attributes" do
      @band.groupies = false
      assert_equal({"name"=>"No One's Choice","groupies"=>false}, @band.to_hash)
    end
  end


  describe ":extend and :class" do
    module UpcaseRepresenter
      include Representable
      def to_hash(*); upcase; end
      def from_hash(hsh, *args); replace hsh.upcase; end   # DISCUSS: from_hash must return self.
    end
    module DowncaseRepresenter
      include Representable
      def to_hash(*); downcase; end
      def from_hash(hsh, *args); replace hsh.downcase; end
    end
    class UpcaseString < String; end


    describe "lambda blocks" do
      representer! do
        property :name, :extend => lambda { |name, *| compute_representer(name) }
      end

      it "executes lambda in represented instance context" do
        _(Song.new("Carnage").instance_eval do
          def compute_representer(name)
            UpcaseRepresenter
          end
          self
        end.extend(representer).to_hash).must_equal({"name" => "CARNAGE"})
      end
    end

    describe ":instance" do
      obj = String.new("Fate")
      mod = Module.new { include Representable; def from_hash(*); self; end }
      representer! do
        property :name, :extend => mod, :instance => lambda { |*| obj }
      end

      it "uses object from :instance but still extends it" do
        song = Song.new.extend(representer).from_hash("name" => "Eric's Had A Bad Day")
        _(song.name).must_equal obj
        _(song.name).must_be_kind_of mod
      end
    end

    describe "property with :extend" do
      representer! do
        property :name, :extend => lambda { |options| options[:input].is_a?(UpcaseString) ? UpcaseRepresenter : DowncaseRepresenter }, :class => String
      end

      it "uses lambda when rendering" do
        assert_equal({"name" => "you make me thick"}, Song.new("You Make Me Thick").extend(representer).to_hash )
        assert_equal({"name" => "STEPSTRANGER"}, Song.new(UpcaseString.new "Stepstranger").extend(representer).to_hash )
      end

      it "uses lambda when parsing" do
        _(Song.new.extend(representer).from_hash({"name" => "You Make Me Thick"}).name).must_equal "you make me thick"
        _(Song.new.extend(representer).from_hash({"name" => "Stepstranger"}).name).must_equal "stepstranger" # DISCUSS: we compare "".is_a?(UpcaseString)
      end

      describe "with :class lambda" do
        representer! do
          property :name, :extend => lambda { |options| options[:input].is_a?(UpcaseString) ? UpcaseRepresenter : DowncaseRepresenter },
                          :class  => lambda { |options| options[:fragment] == "Still Failing?" ? String : UpcaseString }
        end

        it "creates instance from :class lambda when parsing" do
          song = OpenStruct.new.extend(representer).from_hash({"name" => "Quitters Never Win"})
          _(song.name).must_be_kind_of UpcaseString
          _(song.name).must_equal "QUITTERS NEVER WIN"

          song = OpenStruct.new.extend(representer).from_hash({"name" => "Still Failing?"})
          _(song.name).must_be_kind_of String
          _(song.name).must_equal "still failing?"
        end
      end
    end


    describe "collection with :extend" do
      representer! do
        collection :songs, :extend => lambda { |options| options[:input].is_a?(UpcaseString) ? UpcaseRepresenter : DowncaseRepresenter }, :class => String
      end

      it "uses lambda for each item when rendering" do
        _(Album.new([UpcaseString.new("Dean Martin"), "Charlie Still Smirks"]).extend(representer).to_hash).must_equal("songs"=>["DEAN MARTIN", "charlie still smirks"])
      end

      it "uses lambda for each item when parsing" do
        album = Album.new.extend(representer).from_hash("songs"=>["DEAN MARTIN", "charlie still smirks"])
        _(album.songs).must_equal ["dean martin", "charlie still smirks"] # DISCUSS: we compare "".is_a?(UpcaseString)
      end

      describe "with :class lambda" do
        representer! do
          collection :songs,  :extend => lambda { |options| options[:input].is_a?(UpcaseString) ? UpcaseRepresenter : DowncaseRepresenter },
                              :class  => lambda { |options| options[:input] == "Still Failing?" ? String : UpcaseString }
        end

        it "creates instance from :class lambda for each item when parsing" do
          album = Album.new.extend(representer).from_hash("songs"=>["Still Failing?", "charlie still smirks"])
          _(album.songs).must_equal ["still failing?", "CHARLIE STILL SMIRKS"]
        end
      end
    end

    describe ":decorator" do
      let(:extend_rpr) { Module.new { include Representable::Hash; collection :songs, :extend => SongRepresenter } }
      let(:decorator_rpr) { Module.new { include Representable::Hash; collection :songs, :decorator => SongRepresenter } }
      let(:songs) { [Song.new("Bloody Mary")] }

      it "is aliased to :extend" do
        _(Album.new(songs).extend(extend_rpr).to_hash).must_equal Album.new(songs).extend(decorator_rpr).to_hash
      end
    end

    # TODO: Move to global place since it's used twice.
    class SongRepresentation < Representable::Decorator
      include Representable::JSON
      property :name
    end
    class AlbumRepresentation < Representable::Decorator
      include Representable::JSON

      collection :songs, :class => Song, :extend => SongRepresentation
    end

    describe "::prepare" do
      let(:song) { Song.new("Still Friends In The End") }
      let(:album) { Album.new([song]) }

      describe "module including Representable" do
        it "uses :extend strategy" do
          album_rpr = Module.new { include Representable::Hash; collection :songs, :class => Song, :extend => SongRepresenter}

          _(album_rpr.prepare(album).to_hash).must_equal({"songs"=>[{"name"=>"Still Friends In The End"}]})
          _(album).must_respond_to :to_hash
        end
      end

      describe "Decorator subclass" do
        it "uses :decorate strategy" do
          _(AlbumRepresentation.prepare(album).to_hash).must_equal({"songs"=>[{"name"=>"Still Friends In The End"}]})
          _(album).wont_respond_to :to_hash
        end
      end
    end
  end
end
