require "test_helper"
require "representable/object"

class ObjectTest < MiniTest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: lambda { |options| options[:fragment].name.upcase!; options[:fragment] } do
      property :name

      collection :songs, instance: lambda { |options| options[:fragment].title.upcase!; options[:fragment] } do
        property :title
      end
    end
    # TODO: collection
  end

  let(:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let(:target) { Song.new }

  it do
    representer.prepare(target).from_object(source)

    _(target.title).must_equal "The King Is Dead"
    _(target.album.name).must_equal "RUINER"
    _(target.album.songs[0].title).must_equal "IN VINO VERITAS II"
  end

  # ignore nested object when nil
  it do
    representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)

    _(target.title).must_be_nil # scalar property gets overridden when nil.
    _(target.album).must_be_nil # nested property stays nil.
  end

  # to_object
  describe "#to_object" do
    representer!(module: Representable::Object) do
      property :title

      property :album, render_filter: lambda { |input, options|input.name = "Live";input } do
        property :name

        collection :songs, render_filter: lambda { |input, options|input[0].title = 1;input } do
          property :title
        end
      end
    end

    it do
      representer.prepare(source).to_object
      _(source.album.name).must_equal "Live"
      _(source.album.songs[0].title).must_equal 1
    end
  end
end