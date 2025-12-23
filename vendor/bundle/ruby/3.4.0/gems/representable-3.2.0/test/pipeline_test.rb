require "test_helper"

class PipelineTest < MiniTest::Spec
  Song   = Struct.new(:title, :artist)
  Artist = Struct.new(:name)
  Album  = Struct.new(:ratings, :artists)

  R = Representable
  P = R::Pipeline

  Getter        = ->(input, options) { "Yo" }
  StopOnNil     = ->(input, options) { input }
  SkipRender    = ->(input, *) { input == "Yo" ? input : P::Stop }

  Prepare       = ->(input, options) { "Prepare(#{input})" }
  Deserialize   = ->(input, options) { "Deserialize(#{input}, #{options[:fragment]})" }

  SkipParse     = ->(input, options) { input }
  CreateObject  = ->(input, options) { OpenStruct.new }


  Setter        = ->(input, options) { "Setter(#{input})" }

  AssignFragment = ->(input, options) { options[:fragment] = input }

  it "linear" do
    _(P[SkipParse, Setter].("doc", {fragment: 1})).must_equal "Setter(doc)"


    # parse style.
    _(P[AssignFragment, SkipParse, CreateObject, Prepare].("Bla", {})).must_equal "Prepare(#<OpenStruct>)"


    # render style.
    _(P[Getter, StopOnNil, SkipRender, Prepare, Setter].(nil, {})).
      must_equal "Setter(Prepare(Yo))"

    # pipeline = Representable::Pipeline[SkipParse  , SetResult, ModifyResult]
    # pipeline.(fragment: "yo!").must_equal "modified object from yo!"
  end

  Stopping      = ->(input, options) { return P::Stop if options[:fragment] == "stop!"; input }


  it "stopping" do


    pipeline = Representable::Pipeline[SkipParse, Stopping, Prepare]
    _(pipeline.(nil, fragment: "oy!")).must_equal "Prepare()"
    _(pipeline.(nil, fragment: "stop!")).must_equal Representable::Pipeline::Stop
  end

  describe "Collect" do
    Reverse = ->(input, options) { input.reverse }
    Add = ->(input, options) { "#{input}+" }
    let(:pipeline) { R::Collect[Reverse, Add] }

    it { _(pipeline.(["yo!", "oy!"], {})).must_equal ["!oy+", "!yo+"] }

    describe "Pipeline with Collect" do
      let(:pipeline) { P[Reverse, R::Collect[Reverse, Add]] }
      it { _(pipeline.(["yo!", "oy!"], {})).must_equal ["!yo+", "!oy+"] }
    end
  end




  ######### scalar property

  let(:title) {
    dfn = R::Definition.new(:title)

    R::Hash::Binding.new(dfn)
  }

  it "rendering scalar property" do
    doc = {}
    _(P[
      R::GetValue,
      R::StopOnSkipable,
      R::AssignName,
      R::WriteFragment
    ].(nil, {represented: Song.new("Lime Green"), binding: title, doc: doc})).must_equal "Lime Green"

    _(doc).must_equal({"title"=>"Lime Green"})
  end

  it "parsing scalar property" do
    _(P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::SetValue,
    ].extend(P::Debug).(doc={"title"=>"Eruption"}, {represented: song=Song.new("Lime Green"), binding: title, doc: doc})).must_equal "Eruption"
    _(song.title).must_equal "Eruption"
  end



  module ArtistRepresenter
    include Representable::Hash
    property :name
  end

  let(:artist) {
    dfn = R::Definition.new(:artist, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding.new(dfn)
  }

  let(:song_model) { Song.new("Lime Green", Artist.new("Diesel Boy")) }

  it "rendering typed property" do
    doc = {}
    _(P[
      R::GetValue,
      R::StopOnSkipable,
      R::StopOnNil,
      R::Decorate,
      R::Serialize,
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: song_model, binding: artist, doc: doc, options: {}})).must_equal({"name" => "Diesel Boy"})

    _(doc).must_equal({"artist"=>{"name"=>"Diesel Boy"}})
  end

  it "parsing typed property" do
    _(P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      R::AssignFragment,
      R::CreateObject::Class,
      R::Decorate,
      R::Deserialize,
      R::SetValue,
    ].extend(P::Debug).(doc={"artist"=>{"name"=>"Doobie Brothers"}}, {represented: song_model, binding: artist, doc: doc, options: {}})).must_equal model=Artist.new("Doobie Brothers")
    _(song_model.artist).must_equal model
  end


  ######### collection :ratings

  let(:ratings) {
    dfn = R::Definition.new(:ratings, collection: true, skip_render: ->(*) { false })

    R::Hash::Binding::Collection.new(dfn)
  }
  it "render scalar collection" do
    doc = {}
    _(P[
      R::GetValue,
      R::StopOnSkipable,
      R::Collect[
        R::SkipRender,
      ],
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: Album.new([1,2,3]), binding: ratings, doc: doc, options: {}})).must_equal([1,2,3])

    _(doc).must_equal({"ratings"=>[1,2,3]})
  end

######### collection :songs, extend: SongRepresenter
  let(:artists) {
    dfn = R::Definition.new(:artists, collection: true, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding::Collection.new(dfn)
  }
  it "render typed collection" do
    doc = {}
    _(P[
      R::GetValue,
      R::StopOnSkipable,
      R::Collect[
        R::Decorate,
        R::Serialize,
      ],
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: Album.new(nil, [Artist.new("Diesel Boy"), Artist.new("Van Halen")]), binding: artists, doc: doc, options: {}})).must_equal([{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}])

    _(doc).must_equal({"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]})
  end

let(:album_model) { Album.new(nil, [Artist.new("Diesel Boy"), Artist.new("Van Halen")]) }

  it "parse typed collection" do
    doc = {"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]}
    _(P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::Collect[
        R::AssignFragment,
        R::CreateObject::Class,
        R::Decorate,
        R::Deserialize,
      ],
      R::SetValue,
    ].extend(P::Debug).(doc, {represented: album_model, binding: artists, doc: doc, options: {}})).must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])

    _(album_model.artists).must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])
  end

  # TODO: test with arrays, too, not "only" Pipeline instances.
  describe "#Insert Pipeline[], Function, replace: OldFunction" do
    let(:pipeline) { P[R::GetValue, R::StopOnSkipable, R::StopOnNil] }

    it "returns Pipeline instance when passing in Pipeline instance" do
      _(P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable)).must_be_instance_of(R::Pipeline)
    end

    it "replaces if exists" do
      # pipeline.insert!(R::Default, replace: R::StopOnSkipable)
      _(P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable)).must_equal P[R::GetValue, R::Default, R::StopOnNil]
      _(pipeline).must_equal P[R::GetValue, R::StopOnSkipable, R::StopOnNil]
    end

    it "replaces Function instance" do
      pipeline = P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
      _(P::Insert.(pipeline, R::Default, replace: R::Prepare)).must_equal P[R::Default, R::StopOnSkipable, R::StopOnNil]
      _(pipeline).must_equal P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
    end

    it "does not replace when not existing" do
      P::Insert.(pipeline, R::Default, replace: R::Prepare)
      _(pipeline).must_equal P[R::GetValue, R::StopOnSkipable, R::StopOnNil]
    end

    it "applies on nested Collect" do
      pipeline = P[R::GetValue, R::Collect[R::GetValue, R::StopOnSkipable], R::StopOnNil]

      _(P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).extend(P::Debug).inspect).must_equal "Pipeline[GetValue, Collect[GetValue, Default], StopOnNil]"
      _(pipeline).must_equal P[R::GetValue, R::Collect[R::GetValue, R::StopOnSkipable], R::StopOnNil]


      _(P::Insert.(pipeline, R::Default, replace: R::StopOnNil).extend(P::Debug).inspect).must_equal "Pipeline[GetValue, Collect[GetValue, StopOnSkipable], Default]"
    end

    it "applies on nested Collect with Function::CreateObject" do
      pipeline = P[R::GetValue, R::Collect[R::GetValue, R::CreateObject], R::StopOnNil]

      _(P::Insert.(pipeline, R::Default, replace: R::CreateObject).extend(P::Debug).inspect).must_equal "Pipeline[GetValue, Collect[GetValue, Default], StopOnNil]"
      _(pipeline).must_equal P[R::GetValue, R::Collect[R::GetValue, R::CreateObject], R::StopOnNil]
    end
  end

  describe "Insert.(delete: true)" do
    let(:pipeline) { P[R::GetValue, R::StopOnNil] }

    it do
      _(P::Insert.(pipeline, R::GetValue, delete: true).extend(P::Debug).inspect).must_equal "Pipeline[StopOnNil]"
      _(pipeline.extend(P::Debug).inspect).must_equal "Pipeline[GetValue, StopOnNil]"
    end
  end

  describe "Insert.(delete: true) with Collect" do
    let(:pipeline) { P[R::GetValue, R::Collect[R::GetValue, R::StopOnSkipable], R::StopOnNil] }

    it do
      _(P::Insert.(pipeline, R::GetValue, delete: true).extend(P::Debug).inspect).must_equal "Pipeline[Collect[StopOnSkipable], StopOnNil]"
      _(pipeline.extend(P::Debug).inspect).must_equal "Pipeline[GetValue, Collect[GetValue, StopOnSkipable], StopOnNil]"
    end
  end
end