require 'test_helper'

class SkipParseTest < MiniTest::Spec
  representer! do
    property :title, skip_parse: lambda { |options| options[:user_options][:skip?] and options[:fragment] == "skip me" }
    property :band,
      skip_parse: lambda { |options| options[:user_options][:skip?] and options[:fragment]["name"].nil? }, class: OpenStruct do
        property :name
    end

    collection :airplays,
      skip_parse: lambda { |options| options[:user_options][:skip?] and options[:fragment]["station"].nil? }, class: OpenStruct do
        property :station
    end
  end

  let(:song) { OpenStruct.new.extend(representer) }

  # do parse.
  it do
    song.from_hash({
      "title"    => "Victim Of Fate",
      "band"     => {"name" => "Mute 98"},
      "airplays" => [{"station" => "JJJ"}]
    }, user_options: { skip?: true })

    _(song.title).must_equal "Victim Of Fate"
    _(song.band.name).must_equal "Mute 98"
    _(song.airplays[0].station).must_equal "JJJ"
  end

  # skip parsing.
  let(:airplay) { OpenStruct.new(station: "JJJ") }

  it do
    song.from_hash({
      "title"    => "skip me",
      "band"     => {},
      "airplays" => [{}, {"station" => "JJJ"}, {}],
    }, user_options: { skip?: true })

    _(song.title).must_be_nil
    _(song.band).must_be_nil
    _(song.airplays).must_equal [airplay]
  end
end

class SkipRenderTest < MiniTest::Spec
  representer! do
    property :title
    property :band,
      skip_render: lambda { |options| options[:user_options][:skip?] and options[:input].name == "Rancid" } do
        property :name
    end

    collection :airplays,
      skip_render: lambda { |options| options[:user_options][:skip?] and options[:input].station == "Radio Dreyeckland" } do
        property :station
    end
  end

  let(:song)      { OpenStruct.new(title: "Black Night", band: OpenStruct.new(name: "Time Again")).extend(representer) }
  let(:skip_song) { OpenStruct.new(title: "Time Bomb",   band: OpenStruct.new(name: "Rancid")).extend(representer) }

  # do render.
  it { _(song.to_hash(user_options: { skip?: true })).must_equal({"title"=>"Black Night", "band"=>{"name"=>"Time Again"}}) }
  # skip.
  it { _(skip_song.to_hash(user_options: { skip?: true })).must_equal({"title"=>"Time Bomb"}) }

  # do render all collection items.
  it do
    song = OpenStruct.new(airplays: [OpenStruct.new(station: "JJJ"), OpenStruct.new(station: "ABC")]).extend(representer)
    _(song.to_hash(user_options: { skip?: true })).must_equal({"airplays"=>[{"station"=>"JJJ"}, {"station"=>"ABC"}]})
  end

  # skip middle item.
  it do
    song = OpenStruct.new(airplays: [OpenStruct.new(station: "JJJ"), OpenStruct.new(station: "Radio Dreyeckland"), OpenStruct.new(station: "ABC")]).extend(representer)
    _(song.to_hash(user_options: { skip?: true })).must_equal({"airplays"=>[{"station"=>"JJJ"}, {"station"=>"ABC"}]})
  end
end