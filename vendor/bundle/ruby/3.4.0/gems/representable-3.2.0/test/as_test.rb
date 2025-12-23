require 'test_helper'

class AsTest < MiniTest::Spec
  for_formats(
    :hash => [Representable::Hash, {"title" => "Wie Es Geht"}, {"title" => "Revolution"}],
    # :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    # :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  ) do |format, mod, input, output|

    let(:song) { representer.prepare(Song.new("Revolution")) }
    let(:format) { format }


    describe "as: with :symbol" do
      representer!(:module => mod) do
        property :name, :as => :title
      end

      it { render(song).must_equal_document output }
      it { _(parse(song, input).name).must_equal "Wie Es Geht" }
    end


    describe "as: with lambda" do
      representer!(:module => mod) do
        property :name, :as => lambda { |*| "#{self.class}" }
      end

      it { render(song).must_equal_document({"Song" => "Revolution"}) }
      it { _(parse(song, {"Song" => "Wie Es Geht"}).name).must_equal "Wie Es Geht" }
    end


    describe "lambda arguments" do
      representer! do
        property :name, :as => lambda { |options| options[:user_options].inspect }
      end

      it { render(song, user_options:{volume: 1}).must_equal_document({"{:volume=>1}" => "Revolution"}) }
      it { _(parse(song, {"{:volume=>1}" => "Wie Es Geht"}, user_options: {volume: 1}).name).must_equal "Wie Es Geht" }
    end
  end
end


# hash: to_hash(wrap: ) is representation_wrap

class AsXmlTest < MiniTest::Spec
  Band  = Struct.new(:name, :label)
  Album = Struct.new(:band)
  Label = Struct.new(:name)

  representer!(module: Representable::XML, decorator: true) do
    self.representation_wrap = :album
    property :band, as: :combo do
      self.representation_wrap = :band
      property :name
    end
  end

  it do
    skip
    _(representer.new(Album.new(Band.new("Offspring"))).to_xml).must_equal ""
  end
end
