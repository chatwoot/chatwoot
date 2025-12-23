require "test_helper"

class WrapTest < MiniTest::Spec
  class HardcoreBand
    include Representable::Hash
  end

  class SoftcoreBand < HardcoreBand
  end

  let(:band) { HardcoreBand.new }

  it "returns false per default" do
    assert_nil SoftcoreBand.new.send(:representation_wrap)
  end

  it "infers a printable class name if set to true" do
    HardcoreBand.representation_wrap = true
    assert_equal "hardcore_band", band.send(:representation_wrap)
  end

  it "can be set explicitely" do
    HardcoreBand.representation_wrap = "breach"
    assert_equal "breach", band.send(:representation_wrap)
  end

  for_formats(
    :hash => [Representable::Hash, {"Blink182"=>{"genre"=>"Pop"}}, {"Blink182"=>{"genre"=>"Poppunk"}}],
    :json => [Representable::JSON, "{\"Blink182\":{\"genre\":\"Pop\"}}", "{\"Blink182\":{\"genre\":\"Poppunk\"}}"],
    :xml  => [Representable::XML, "<Blink182><genre>Pop</genre></Blink182>", "<Blink182><genre>Poppunk</genre></Blink182>"],
    # :yaml => [Representable::YAML, "---\nBlink182:\n"], # TODO: fix YAML.
  ) do |format, mod, output, input|

    describe "[#{format}] dynamic wrap" do
      let(:band) { representer.prepare(Struct.new(:name, :genre).new("Blink", "Pop")) }
      let(:format) { format }

      representer!(:module => mod) do
        self.representation_wrap = lambda { |number:, **| "#{name}#{number}" }
        property :genre
      end

      it { render(band, {:number => 182}).must_equal_document(output) }

      it { _(parse(band, input, {:number => 182}).genre).must_equal "Poppunk" } # TODO: better test. also, xml parses _any_ wrap.
    end
  end
end


class HashDisableWrapTest < MiniTest::Spec
  Band  = Struct.new(:name, :label)
  Album = Struct.new(:band)
  Label = Struct.new(:name)

  class BandDecorator < Representable::Decorator
    include Representable::Hash

    self.representation_wrap = :bands
    property :name

    property :label do # this should have a wrap!
      self.representation_wrap = :important
      property :name
    end
  end

  let(:band) { BandDecorator.prepare(Band.new("Social Distortion")) }

  # direct, local api.
  it do
    _(band.to_hash).must_equal({"bands" => {"name"=>"Social Distortion"}})
    _(band.to_hash(wrap: false)).must_equal({"name"=>"Social Distortion"})
    _(band.to_hash(wrap: :band)).must_equal(:band=>{"name"=>"Social Distortion"})
  end

  it do
    _(band.from_hash({"bands" => {"name"=>"Social Distortion"}}).name).must_equal "Social Distortion"
    _(band.from_hash({"name"=>"Social Distortion"}, wrap: false).name).must_equal "Social Distortion"
    _(band.from_hash({band: {"name"=>"Social Distortion"}}, wrap: :band).name).must_equal "Social Distortion"
  end


  class AlbumDecorator < Representable::Decorator
    include Representable::Hash

    self.representation_wrap = :albums

    property :band, decorator: BandDecorator, wrap: false, class: Band
  end


  let(:album) { AlbumDecorator.prepare(Album.new(Band.new("Social Distortion", Label.new("Epitaph")))) }

  # band has wrap turned off per property definition, however, label still has wrap.
  it "renders" do
    _(album.to_hash).must_equal({"albums" => {"band" => {"name"=>"Social Distortion", "label"=>{"important"=>{"name"=>"Epitaph"}}}}})
  end

  it "parses" do
    _(album.from_hash({"albums" => {"band" => {"name"=>"Rvivr"}}}).band.name).must_equal "Rvivr"
  end
end


class XMLDisableWrapTest < MiniTest::Spec
  Band  = Struct.new(:name, :label)
  Album = Struct.new(:band)
  Label = Struct.new(:name)

  class BandDecorator < Representable::Decorator
    include Representable::XML

    self.representation_wrap = :bands # when nested, it uses this.
    property :name

    # property :label do # this should have a wrap!
    #   self.representation_wrap = :important
    #   property :name
    # end
  end

  let(:band) { BandDecorator.prepare(Band.new("Social Distortion")) }

  it do
    band.to_xml.must_equal_xml "<bands><name>Social Distortion</name></bands>"
    band.to_xml(wrap: "combo").must_equal_xml "<combo><name>Social Distortion</name></combo>"
  end


  class AlbumDecorator < Representable::Decorator
    include Representable::XML

    self.representation_wrap = :albums

    property :band, decorator: BandDecorator, wrap: "po", class: Band
  end


  let(:album) { AlbumDecorator.prepare(Album.new(Band.new("Social Distortion", Label.new("Epitaph")))) }

  # band has wrap turned of per property definition, however, label still has wrap.
  it "rendersxx" do
    skip
    _(album.to_xml).must_equal({"albums" => {"band" => {"name"=>"Social Distortion", "label"=>{"important"=>{"name"=>"Epitaph"}}}}})
  end

  # it "parses" do
  #   album.from_hash({"albums" => {"band" => {"name"=>"Rvivr"}}}).band.name.must_equal "Rvivr"
  # end
end

