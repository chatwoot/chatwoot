require 'test_helper'

class YamlPublicMethodsTest < Minitest::Spec
  #---
  # from_yaml
  class BandRepresenter < Representable::Decorator
    include Representable::YAML
    property :id
    property :name
  end

  let(:data) { %{---
id: 1
name: Rancid
} }

  it { _(BandRepresenter.new(Band.new).from_yaml(data)[:id, :name]).must_equal [1, "Rancid"] }
  it { _(BandRepresenter.new(Band.new).parse(data)[:id, :name]).must_equal [1, "Rancid"] }

  #---
  # to_yaml
  let(:band) { Band.new("1", "Rancid") }

  it { _(BandRepresenter.new(band).to_yaml).must_equal data }
  it { _(BandRepresenter.new(band).render).must_equal data }
end

class YamlTest < MiniTest::Spec
  def self.yaml_representer(&block)
    Module.new do
      include Representable::YAML
      instance_exec(&block)
    end
  end

  def yaml_representer(&block)
    self.class.yaml_representer(&block)
  end


  describe "property" do
    let(:yaml) { yaml_representer do property :best_song end }

    let(:album) { Album.new.tap do |album|
      album.best_song = "Liar"
    end }

    describe "#to_yaml" do
      it "renders plain property" do
        _(album.extend(yaml).to_yaml).must_equal(
"---
best_song: Liar
")
      end

      it "always renders values into strings" do
        _(Album.new.tap { |a| a.best_song = 8675309 }.extend(yaml).to_yaml).must_equal(
"---
best_song: 8675309
"
)
      end
    end


    describe "#from_yaml" do
      it "parses plain property" do
        _(album.extend(yaml).from_yaml(
"---
best_song: This Song Is Recycled
").best_song).must_equal "This Song Is Recycled"
      end
    end


    describe "with :class and :extend" do
      yaml_song = yaml_representer do property :name end
      let(:yaml_album) { Module.new do
        include Representable::YAML
        property :best_song, :extend => yaml_song, :class => Song
      end }

      let(:album) { Album.new.tap do |album|
        album.best_song = Song.new("Liar")
      end }


      describe "#to_yaml" do
        it "renders embedded typed property" do
          _(album.extend(yaml_album).to_yaml).must_equal "---
best_song:
  name: Liar
"
        end
      end

      describe "#from_yaml" do
        it "parses embedded typed property" do
          _(album.extend(yaml_album).from_yaml("---
best_song:
  name: Go With Me
")).must_equal Album.new(nil,Song.new("Go With Me"))
        end
      end
    end
  end


  describe "collection" do
    let(:yaml) { yaml_representer do collection :songs end }

    let(:album) { Album.new.tap do |album|
      album.songs = ["Jackhammer", "Terrible Man"]
    end }


    describe "#to_yaml" do
      it "renders a block style list per default" do
        _(album.extend(yaml).to_yaml).must_equal "---
songs:
- Jackhammer
- Terrible Man
"
      end

      it "renders a flow style list when :style => :flow set" do
        yaml = yaml_representer { collection :songs, :style => :flow }
        _(album.extend(yaml).to_yaml).must_equal "---
songs: [Jackhammer, Terrible Man]
"
      end
    end


    describe "#from_yaml" do
      it "parses a block style list" do
        _(album.extend(yaml).from_yaml("---
songs:
- Off Key Melody
- Sinking")).must_equal Album.new(["Off Key Melody", "Sinking"])

      end

      it "parses a flow style list" do
        _(album.extend(yaml).from_yaml("---
songs: [Off Key Melody, Sinking]")).must_equal Album.new(["Off Key Melody", "Sinking"])
      end
    end


    describe "with :class and :extend" do
      let(:yaml_album) { Module.new do
        include Representable::YAML
        collection :songs, :class => Song do
          property :name
          property :track
        end
      end }

      let(:album) { Album.new([Song.new("Liar", 1), Song.new("What I Know", 2)]) }


      describe "#to_yaml" do
        it "renders collection of typed property" do
          _(album.extend(yaml_album).to_yaml).must_equal "---
songs:
- name: Liar
  track: 1
- name: What I Know
  track: 2
"
        end
      end

      describe "#from_yaml" do
        it "parses collection of typed property" do
          _(album.extend(yaml_album).from_yaml("---
songs:
- name: One Shot Deal
  track: 4
- name: Three Way Dance
  track: 5")).must_equal Album.new([Song.new("One Shot Deal", 4), Song.new("Three Way Dance", 5)])
        end
      end
    end
  end
end
