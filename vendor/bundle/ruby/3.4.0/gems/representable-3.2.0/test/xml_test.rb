require 'test_helper'


class XmlPublicMethodsTest < Minitest::Spec
  #---
  # from_hash
  class BandRepresenter < Representable::Decorator
    include Representable::XML
    property :id
    property :name
  end

  let(:data) { %{<data><id>1</id><name>Rancid</name></data>} }

  it { _(BandRepresenter.new(Band.new).from_xml(data)[:id, :name]).must_equal ["1", "Rancid"] }
  it { _(BandRepresenter.new(Band.new).parse(data)[:id, :name]).must_equal ["1", "Rancid"] }

  #---
  # to_hash
  let(:band) { Band.new("1", "Rancid") }

  it { BandRepresenter.new(band).to_xml.must_equal_xml data }
  it { BandRepresenter.new(band).render.must_equal_xml data }
end

class XmlTest < MiniTest::Spec

  class Band
    include Representable::XML
    property :name
    attr_accessor :name

    def initialize(name=nil)
      name and self.name = name
    end
  end


  XML = Representable::XML
  Def = Representable::Definition

  describe "Xml module" do
    before do
      @Band = Class.new do
        include Representable::XML
        self.representation_wrap = :band
        property :name
        property :label
        attr_accessor :name, :label
      end

      @band = @Band.new
    end


    describe "#from_xml" do
      before do
        @band = @Band.new
        @xml  = %{<band><name>Nofx</name><label>NOFX</label></band>}
      end

      it "parses XML and assigns properties" do
        @band.from_xml(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
    end

    describe "#from_xml with remove_namespaces! and xmlns present" do
      before do
        @Band.remove_namespaces!
        @band = @Band.new
        @xml = %{<band xmlns="exists"><name>Nofx</name><label>NOFX</label></band>}
      end

      it "parses with xmlns present" do
        @band.from_xml(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
    end

    describe "#from_node" do
      before do
        @band = @Band.new
        @xml  = Nokogiri::XML(%{<band><name>Nofx</name><label>NOFX</label></band>}).root
      end

      it "receives Nokogiri node and assigns properties" do
        @band.from_node(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
    end


    describe "#to_xml" do
      it "delegates to #to_node and returns string" do
        assert_xml_equal "<band><name>Rise Against</name></band>", Band.new("Rise Against").to_xml
      end
    end


    describe "#to_node" do
      it "returns Nokogiri node" do
        node = Band.new("Rise Against").to_node
        assert_kind_of Nokogiri::XML::Element, node
      end

      it "wraps with infered class name per default" do
        node = Band.new("Rise Against").to_node
        assert_xml_equal "<band><name>Rise Against</name></band>", node.to_s
      end

      it "respects #representation_wrap=" do
        klass = Class.new(Band) do
          include Representable
          property :name
        end

        klass.representation_wrap = :group
        assert_xml_equal "<group><name>Rise Against</name></group>", klass.new("Rise Against").to_node.to_s
      end
    end


    describe "XML::Binding#build_for" do
      it "returns AttributeBinding" do
        assert_kind_of XML::Binding::Attribute, XML::Binding.build_for(Def.new(:band, :as => "band", :attribute => true))
      end

      it "returns Binding" do
        assert_kind_of XML::Binding, XML::Binding.build_for(Def.new(:band, :class => Hash))
        assert_kind_of XML::Binding, XML::Binding.build_for(Def.new(:band, :as => :content))
      end

      it "returns CollectionBinding" do
        assert_kind_of XML::Binding::Collection, XML::Binding.build_for(Def.new(:band, :collection => :true))
      end

      it "returns HashBinding" do
        assert_kind_of XML::Binding::Hash, XML::Binding.build_for(Def.new(:band, :hash => :true))
      end
    end


    describe "DCI" do
      module SongRepresenter
        include Representable::XML
        property :name
      end

      module AlbumRepresenter
        include Representable::XML
        property :best_song, :class => Song, :extend => SongRepresenter
        collection :songs, :class => Song, :as => :song, :extend => SongRepresenter
      end


      it "allows adding the representer by using #extend" do
        module BandRepresenter
          include Representable::XML
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
        assert_xml_equal "<object><name>CIV</name></object>", civ.to_xml
      end

      it "extends contained models when serializing" do
        @album = Album.new(
          [Song.new("I Hate My Brain"), mr=Song.new("Mr. Charisma")], mr)
        @album.extend(AlbumRepresenter)

        @album.to_xml.must_equal_xml "<album>
  <song><name>Mr. Charisma</name></song>
  <song><name>I Hate My Brain</name></song>
  <song><name>Mr. Charisma</name></song>
</album>"
      end

      it "extends contained models when deserializing" do
        @album = Album.new
        @album.extend(AlbumRepresenter)

        @album.from_xml("<album><best_song><name>Mr. Charisma</name></best_song><song><name>I Hate My Brain</name></song><song><name>Mr. Charisma</name></song></album>")
        assert_equal "Mr. Charisma", @album.best_song.name
      end
    end
  end
end


class AttributesTest < MiniTest::Spec
  describe ":as => rel, :attribute => true" do
    class Link
      include Representable::XML
      property :href,   :as => "href",  :attribute => true
      property :title,  :as => "title", :attribute => true
      attr_accessor :href, :title
    end

    it "#from_xml creates correct accessors" do
      link = Link.new.from_xml(%{
        <a href="http://apotomo.de" title="Home, sweet home" />
      })
      assert_equal "http://apotomo.de", link.href
      assert_equal "Home, sweet home",  link.title
    end

    it "#to_xml serializes correctly" do
      link = Link.new
      link.href = "http://apotomo.de/"

      assert_xml_equal %{<link href="http://apotomo.de/">}, link.to_xml
    end
  end
end


class CDataBand
  class CData < Representable::XML::Binding
    def serialize_node(parent, value)
      parent << Nokogiri::XML::CDATA.new(parent, represented.name)
    end
  end

  include Representable::XML
  property :name, :binding => lambda { |*args| CData.new(*args) }#getter: lambda { |opt| Nokogiri::XML::CDATA.new(opt[:doc], name) }
  attr_accessor :name

  def initialize(name=nil)
    name and self.name = name
  end
end

class TypedPropertyTest < MiniTest::Spec
  class Band
    include Representable::XML
    property :name
    attr_accessor :name

    def initialize(name=nil)
      name and self.name = name
    end
  end

  module AlbumRepresenter
    include Representable::XML
    property :band, :class => Band
  end

  class Album
    attr_accessor :band
    def initialize(band=nil)
      @band = band
    end
  end

  # TODO:property :group, :class => Band
  # :class
  # where to mixin DCI?
  describe ":class => Item" do
    it "#from_xml creates one Item instance" do
      album = Album.new.extend(AlbumRepresenter).from_xml(%{
        <album>
          <band><name>Bad Religion</name></band>
        </album>
      })
      assert_equal "Bad Religion", album.band.name
    end

    describe "#to_xml" do
      it "doesn't escape xml from Band#to_xml" do
        band = Band.new("Bad Religion")
        album = Album.new(band).extend(AlbumRepresenter)

        assert_xml_equal %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}, album.to_xml
      end

      it "doesn't escape and wrap string from Band#to_node" do
        band = Band.new("Bad Religion")
        band.instance_eval do
          def to_node(*)
            "<band>Baaaad Religion</band>"
          end
        end

        assert_xml_equal %{<album><band>Baaaad Religion</band></album>}, Album.new(band).extend(AlbumRepresenter).to_xml
      end
    end

    describe "#to_xml with CDATA" do
      it "wraps Band name in CDATA#to_xml" do
        band = CDataBand.new("Bad Religion")
        album = Album.new(band).extend(AlbumRepresenter)

        assert_xml_equal %{<album>
         <c_data_band>
           <name><![CDATA[Bad Religion]]></name>
         </c_data_band>
       </album>}, album.to_xml
      end
    end
  end
end

# TODO: add parsing tests.
class XMLPropertyTest < Minitest::Spec
  Band = Struct.new(:name, :genre)
  Manager = Struct.new(:managed)

  #---
  #- :as with scalar
  class BandRepresenter < Representable::Decorator
    include Representable::XML
    property :name, as: :theyCallUs
    property :genre, attribute: true
  end

  it { BandRepresenter.new(Band.new("Mute")).to_xml.must_equal_xml %{<band><theyCallUs>Mute</theyCallUs></band>} }

  class ManagerRepresenter < Representable::Decorator
    include Representable::XML
    property :managed, as: :band, decorator: BandRepresenter
  end

  #- :as with nested property
  it { ManagerRepresenter.new(Manager.new(Band.new("Mute", "Punkrock"))).to_xml.must_equal_xml %{<manager><band genre="Punkrock"><theyCallUs>Mute</theyCallUs></band></manager>} }
end


class XMLCollectionTest < MiniTest::Spec
  Band        = Struct.new(:name)
  Compilation = Struct.new(:bands)

  class BandRepresenter < Representable::Decorator
    include Representable::XML
    property :name
  end

  #---
  #- :as, :decorator, :class
  describe ":class => Band, :as => :band, :collection => true" do
    class CompilationRepresenter < Representable::Decorator
      include Representable::XML
      collection :bands, class: Band, as: :group, decorator: BandRepresenter
    end

    describe "#from_xml" do
      it "pushes collection items to array" do
        cd = CompilationRepresenter.new(Compilation.new).from_xml(%{
          <compilation>
            <group><name>Diesel Boy</name></group>
            <group><name>Cobra Skulls</name></group>
          </compilation>
        })
        assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
      end
    end

    it "responds to #to_xml" do
      cd = Compilation.new([Band.new("Diesel Boy"), Band.new("Bad Religion")])

      CompilationRepresenter.new(cd).to_xml.must_equal_xml %{<compilation>
        <group><name>Diesel Boy</name></group>
        <group><name>Bad Religion</name></group>
      </compilation>}
    end
  end


  describe ":as" do
    let(:xml_doc) {
      Module.new do
        include Representable::XML
        collection :songs, :as => :song
      end }

    it "collects untyped items" do
      album = Album.new.extend(xml_doc).from_xml(%{
        <album>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
          <song>Laundry Basket</song>
        </album>
      })
      assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
    end
  end


  describe ":wrap" do
    let(:album) { Album.new.extend(xml_doc) }
    let(:xml_doc) {
      Module.new do
        include Representable::XML
        collection :songs, :as => :song, :wrap => :songs
      end }

    describe "#from_xml" do
      it "finds items in wrapped collection" do
        album.from_xml(%{
          <album>
            <songs>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
              <song>Laundry Basket</song>
            </songs>
          </album>
        })
        assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
      end
    end

    describe "#to_xml" do
      it "wraps items" do
        album.songs = ["Laundry Basket", "Two Kevins", "Wright and Rong"]
        assert_xml_equal %{
          <album>
            <songs>
              <song>Laundry Basket</song>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
            </songs>
          </album>
        }, album.to_xml
      end
    end
  end

  require 'representable/xml/hash'
  class LonelyRepresenterTest < MiniTest::Spec
    # TODO: where is the XML::Hash test?
    module SongRepresenter
      include Representable::XML
      property :name
      self.representation_wrap = :song
    end

    let(:decorator) { rpr = representer; Class.new(Representable::Decorator) { include Representable::XML; include rpr } }

    describe "XML::Collection" do
      describe "with contained objects" do
        representer!(:module => Representable::XML::Collection)  do
          items :class => Song, :extend => SongRepresenter
          self.representation_wrap= :songs
        end

        let(:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
        let(:xml_doc)   { "<songs><song><name>Days Go By</name></song><song><name>Can't Take Them All</name></song></songs>" }

        it "renders array" do
          songs.extend(representer).to_xml.must_equal_xml xml_doc
        end

        it "renders array with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml_doc
        end

        it "parses array" do
          _([].extend(representer).from_xml(xml_doc)).must_equal songs
        end

        it "parses array with decorator" do
          _(decorator.new([]).from_xml(xml_doc)).must_equal songs
        end
      end
    end

    describe "XML::AttributeHash" do  # TODO: move to HashTest.
      representer!(:module => Representable::XML::AttributeHash) do
        self.representation_wrap= :songs
      end

      let(:songs) { {"one" => "Graveyards", "two" => "Can't Take Them All"} }
      let(:xml_doc)   { "<favs one=\"Graveyards\" two=\"Can't Take Them All\" />" }

      describe "#to_xml" do
        it "renders hash" do
          songs.extend(representer).to_xml.must_equal_xml xml_doc
        end

        it "respects :exclude" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:exclude => [:one])
        end

        it "respects :include" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:include => [:two])
        end

        it "renders hash with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml_doc
        end
      end

      describe "#from_json" do
        it "returns hash" do
          _({}.extend(representer).from_xml(xml_doc)).must_equal songs
        end

        it "respects :exclude" do
          assert_equal({"two" => "Can't Take Them All"}, {}.extend(representer).from_xml(xml_doc, :exclude => [:one]))
        end

        it "respects :include" do
          assert_equal({"one" => "Graveyards"}, {}.extend(representer).from_xml(xml_doc, :include => [:one]))
        end

        it "parses hash with decorator" do
          _(decorator.new({}).from_xml(xml_doc)).must_equal songs
        end
      end
    end
  end
end

class XmlHashTest < MiniTest::Spec
  # scalar, no object
  describe "plain text" do
    representer!(module: Representable::XML) do
      hash :songs
    end

    let(:doc) { "<open_struct><first>The Gargoyle</first><second>Bronx</second></open_struct>" }

    # to_xml
    it { OpenStruct.new(songs: {"first" => "The Gargoyle", "second" => "Bronx"}).extend(representer).to_xml.must_equal_xml(doc) }
    # FIXME: this NEVER worked!
    # it { OpenStruct.new.extend(representer).from_xml(doc).songs.must_equal({"first" => "The Gargoyle", "second" => "Bronx"}) }
  end

  describe "with objects" do
    representer!(module: Representable::XML) do
      hash :songs, class: OpenStruct do
        property :title
      end
    end

    let(:doc) { "<open_struct>
  <open_struct>
    <title>The Gargoyle</title>
  </open_struct>
  <open_struct>
    <title>Bronx</title>
  </open_struct>
</open_struct>" }

    # to_xml
    it { OpenStruct.new(songs: {"first" => OpenStruct.new(title: "The Gargoyle"), "second" => OpenStruct.new(title: "Bronx")}).extend(representer).to_xml.must_equal_xml(doc) }
    # FIXME: this NEVER worked!
    # it { OpenStruct.new.extend(representer).from_xml(doc).songs.must_equal({"first" => "The Gargoyle", "second" => "Bronx"}) }
  end
end
