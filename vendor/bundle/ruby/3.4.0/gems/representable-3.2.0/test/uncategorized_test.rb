require "test_helper"

class StopWhenIncomingObjectFragmentIsNilTest < MiniTest::Spec
  Album = Struct.new(:id, :songs)
  Song  = Struct.new(:title)

  representer!(decorator: true) do
    property :id
    collection :songs, class: Song, parse_pipeline: ->(input, options) { # TODO: test if :doc is set for parsing. test if options are ok and contain :user_options!
                Representable::Pipeline[*parse_functions.insert(3, Representable::StopOnNil)]
                } do
      property :title
    end
  end

  it do
    album = Album.new
    _(representer.new(album).from_hash({"id"=>1, "songs"=>[{"title"=>"Walkie Talkie"}]}).songs).must_equal [Song.new("Walkie Talkie")]
  end

  it do
    album = Album.new(2, ["original"])
    _(representer.new(album).from_hash({"id"=>1, "songs"=>nil}).songs).must_equal ["original"]
  end

end

class RenderPipelineOptionTest < MiniTest::Spec
  Album   = Struct.new(:id, :songs)
  NilToNA = ->(input, options) { input.nil? ? "n/a" : input }

  representer!(decorator: true) do
    property :id, render_pipeline: ->(input, options) do
      Representable::Pipeline[*render_functions.insert(2, options[:options][:user_options][:function])]
    end
  end

  it { _(representer.new(Album.new).to_hash(user_options: {function: NilToNA})).must_equal({"id"=>"n/a"}) }
  it { _(representer.new(Album.new(1)).to_hash(user_options: {function: NilToNA})).must_equal({"id"=>1}) }

  it "is cached" do
    decorator = representer.new(Album.new)
    _(decorator.to_hash(user_options: {function: NilToNA})).must_equal({"id"=>"n/a"})
    _(decorator.to_hash(user_options: {function: nil})).must_equal({"id"=>"n/a"}) # non-sense function is not applied.
  end

end

class ParsePipelineOptionTest < MiniTest::Spec
  Album   = Struct.new(:id, :songs)
  NilToNA = ->(input, options) { input.nil? ? "n/a" : input }

  representer!(decorator: true) do
    property :id, parse_pipeline: ->(input, options) do
      Representable::Pipeline[*parse_functions.insert(3, options[:options][:user_options][:function])].extend(Representable::Pipeline::Debug)
    end
  end

  it { _(representer.new(Album.new).from_hash({"id"=>nil}, user_options: {function: NilToNA}).id).must_equal "n/a" }
  it { _(representer.new(Album.new(1)).to_hash(user_options: {function: NilToNA})).must_equal({"id"=>1}) }

  it "is cached" do
    decorator = representer.new(Album.new)
    _(decorator.from_hash({"id"=>nil}, user_options: {function: NilToNA}).id).must_equal "n/a"
    _(decorator.from_hash({"id"=>nil}, user_options: {function: "nonsense"}).id).must_equal "n/a" # non-sense function is not applied.
  end
end