require "test_helper"

class IncludeExcludeTest < Minitest::Spec
  Song   = Struct.new(:title, :artist, :id)
  Artist = Struct.new(:name, :id, :songs)

  representer!(decorator: true) do
    property :title
    property :artist, class: Artist do
      property :name
      property :id

      collection :songs, class: Song do
        property :title
        property :id
      end
    end
  end

  let(:song) { Song.new("Listless", Artist.new("7yearsbadluck", 1  )) }
  let(:decorator) { representer.new(song) }

  describe "#from_hash" do
    it "accepts :exclude option" do
      decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"id"=>2}}, exclude: [:title])

      _(song.title).must_equal "Listless"
      _(song.artist).must_equal Artist.new(nil, 2)
    end

    it "accepts :include option" do
      decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"id"=>2}}, include: [:title])

      _(song.title).must_equal "Don't Smile In Trouble"
      _(song.artist).must_equal Artist.new("7yearsbadluck", 1)
    end

    it "accepts nested :exclude/:include option" do
      decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"name"=>"Foo", "id"=>2, "songs"=>[{"id"=>1, "title"=>"Listless"}]}},
        exclude: [:title],
        artist: {
          exclude: [:id],
          songs: { include: [:title] }
        }
      )

      _(song.title).must_equal "Listless"
      _(song.artist).must_equal Artist.new("Foo", nil, [Song.new("Listless", nil, nil)])
    end
  end

  describe "#to_hash" do
    it "accepts :exclude option" do
      _(decorator.to_hash(exclude: [:title])).must_equal({"artist"=>{"name"=>"7yearsbadluck", "id"=>1}})
    end

    it "accepts :include option" do
      _(decorator.to_hash(include: [:title])).must_equal({"title"=>"Listless"})
    end

    it "accepts nested :exclude/:include option" do
      decorator = representer.new(Song.new("Listless", Artist.new("7yearsbadluck", 1, [Song.new("C.O.A.B.I.E.T.L.")])))

      _(decorator.to_hash(
        exclude: [:title],
        artist: {
          exclude: [:id],
          songs: { include: [:title] }
        }
      )).must_equal({"artist"=>{"name"=>"7yearsbadluck", "songs"=>[{"title"=>"C.O.A.B.I.E.T.L."}]}})
    end
  end

  it "xdoes not propagate private options to nested objects" do
    Cover = Struct.new(:title, :original)

    cover_rpr = Module.new do
      include Representable::Hash
      property :title
      property :original, extend: self
    end

    # FIXME: we should test all representable-options (:include, :exclude, ?)

    _(Cover.new("Roxanne", Cover.new("Roxanne (Don't Put On The Red Light)")).extend(cover_rpr).
      to_hash(:include => [:original])).must_equal({"original"=>{"title"=>"Roxanne (Don't Put On The Red Light)"}})
  end
end
