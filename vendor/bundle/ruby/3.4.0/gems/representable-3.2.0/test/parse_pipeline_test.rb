require "test_helper"

class ParsePipelineTest < MiniTest::Spec
  Album  = Struct.new(:id, :artist, :songs)
  Artist = Struct.new(:email)
  Song   = Struct.new(:title)

  describe "transforming nil to [] when parsing" do
    representer!(decorator: true) do
      collection :songs,
          parse_pipeline: ->(*) {
            Representable::Pipeline.insert(
              parse_functions,                                # original function list from Binding#parse_functions.
              ->(input, options) { input.nil? ? [] : input }, # your new function (can be any callable object)..
              replace: Representable::OverwriteOnNil          # ..that replaces the original function.
            )
          },
          class: Song do
        property :title
      end
    end

    it do
      representer.new(album = Album.new).from_hash("songs"=>nil)
      _(album.songs).must_equal []
    end

    it do
      representer.new(album = Album.new).from_hash("songs"=>[{"title" => "Business Conduct"}])
      _(album.songs).must_equal [Song.new("Business Conduct")]
    end
  end


  # tests [Collect[Instance, Prepare, Deserialize], Setter]
  class Representer < Representable::Decorator
    include Representable::Hash

    # property :artist, populator: Uber::Options::Value.new(ArtistPopulator.new), pass_options:true do
    #   property :email
    # end
    # DISCUSS: rename to populator_pipeline ?
    collection :songs, parse_pipeline: ->(*) { [Collect[Instance, Prepare, Deserialize], Setter] }, instance: :instance!, exec_context: :decorator, pass_options: true do
      property :title
    end

    def instance!(*options)
      Song.new
    end

    def songs=(array)
      represented.songs=array
    end
  end

  it do
    skip "TODO: implement :parse_pipeline and :render_pipeline, and before/after/replace semantics"
    album = Album.new
    Representer.new(album).from_hash({"artist"=>{"email"=>"yo"}, "songs"=>[{"title"=>"Affliction"}, {"title"=>"Dream Beater"}]})
    _(album.songs).must_equal([Song.new("Affliction"), Song.new("Dream Beater")])
  end
end