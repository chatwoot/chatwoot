require "test_helper"

class Profiler
  def self.profile(&block)
    case RUBY_ENGINE
    when "ruby"
      require 'ruby-prof'

      output = StringIO.new
      profile_result = RubyProf.profile(&block)
      printer = RubyProf::FlatPrinter.new(profile_result)
      printer.print(output)
      output.string
    when "jruby"
      require 'jruby/profiler'

      output_stream  = java.io.ByteArrayOutputStream.new
      print_stream   = java.io.PrintStream.new(output_stream)
      profile_result = JRuby::Profiler.profile(&block)
      printer = JRuby::Profiler::FlatProfilePrinter.new(profile_result)
      printer.printProfile(print_stream)
      output_stream.toString
    end
  end
end

class CachedTest < MiniTest::Spec
  # TODO: also test with feature(Cached)

  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name, :hidden_taste)
  end

  class SongRepresenter < Representable::Decorator
    include Representable::Hash
    feature Representable::Cached

    property :title, render_filter: lambda { |input, options| "#{input}:#{options[:options][:user_options]}" }
    property :composer, class: Model::Artist do
      property :name
    end
  end

  class AlbumRepresenter < Representable::Decorator
    include Representable::Hash
    include Representable::Cached

    property :name
    collection :songs, decorator: SongRepresenter, class: Model::Song
  end


  describe "serialization" do
    let(:album_hash) { {"name"=>"Louder And Even More Dangerous", "songs"=>[{"title"=>"Southbound:{:volume=>10}"}, {"title"=>"Jailbreak:{:volume=>10}"}]} }

    let(:song) { Model::Song.new("Jailbreak") }
    let(:song2) { Model::Song.new("Southbound") }
    let(:album) { Model::Album.new("Live And Dangerous", [song, song2, Model::Song.new("Emerald")]) }
    let(:representer) { AlbumRepresenter.new(album) }

    it do
      # album2 = Model::Album.new("Louder And Even More Dangerous", [song2, song])

      # makes sure options are passed correctly.
      _(representer.to_hash(user_options: {volume: 9})).must_equal({"name"=>"Live And Dangerous",
        "songs"=>[{"title"=>"Jailbreak:{:volume=>9}"}, {"title"=>"Southbound:{:volume=>9}"}, {"title"=>"Emerald:{:volume=>9}"}]}) # called in Deserializer/Serializer

      # representer becomes reusable as it is stateless.
      # representer.update!(album2)

      # makes sure options are passed correctly.
      # representer.to_hash(volume:10).must_equal(album_hash)
    end

    # profiling
    it do
      representer.to_hash

      data = Profiler.profile { representer.to_hash }

      # 3 songs get decorated.
      _(data).must_match(/3\s*Representable::Function::Decorate#call/m)
      # These weird Regexp bellow are a quick workaround to accomodate
      # the different profiler result formats.
      #   - "3   <Class::Representable::Decorator>#prepare" -> At MRI Ruby
      #   - "3  Representable::Decorator.prepare"           -> At JRuby

      # 3 nested decorator is instantiated for 3 Songs, though.
      _(data).must_match(/3\s*(<Class::)?Representable::Decorator\>?[\#.]prepare/m)
      # no Binding is instantiated at runtime.
      _(data).wont_match "Representable::Binding#initialize"
      # 2 mappers for Album, Song
      # data.must_match "2   Representable::Mapper::Methods#initialize"
      # title, songs, 3x title, composer
      _(data).must_match(/8\s*Representable::Binding[#\.]render_pipeline/m)
      _(data).wont_match "render_functions"
      _(data).wont_match "Representable::Binding::Factories#render_functions"
    end
  end


  describe "deserialization" do
    let(:album_hash) {
      {
        "name"=>"Louder And Even More Dangerous",
        "songs"=>[
          {"title"=>"Southbound", "composer"=>{"name"=>"Lynott"}},
          {"title"=>"Jailbreak", "composer"=>{"name"=>"Phil Lynott"}},
          {"title"=>"Emerald"}
        ]
      }
    }

    it do
      album = Model::Album.new

      AlbumRepresenter.new(album).from_hash(album_hash)

      _(album.songs.size).must_equal 3
      _(album.name).must_equal "Louder And Even More Dangerous"
      _(album.songs[0].title).must_equal "Southbound"
      _(album.songs[0].composer.name).must_equal "Lynott"
      _(album.songs[1].title).must_equal "Jailbreak"
      _(album.songs[1].composer.name).must_equal "Phil Lynott"
      _(album.songs[2].title).must_equal "Emerald"
      _(album.songs[2].composer).must_be_nil

      # TODO: test options.
    end

    it "xxx" do
      representer = AlbumRepresenter.new(Model::Album.new)
      representer.from_hash(album_hash)

      data = Profiler.profile { representer.from_hash(album_hash) }

      # only 2 nested decorators are instantiated, Song, and Artist.
      # Didn't like the regexp?
      # MRI and JRuby has different output formats. See note above.
      _(data).must_match(/5\s*(<Class::)?Representable::Decorator>?[#\.]prepare/)
      # a total of 5 properties in the object graph.
      _(data).wont_match "Representable::Binding#initialize"

      _(data).wont_match "parse_functions" # no pipeline creation.
      _(data).must_match(/10\s*Representable::Binding[#\.]parse_pipeline/)
      # three mappers for Album, Song, composer
      # data.must_match "3   Representable::Mapper::Methods#initialize"
      # # 6 deserializers as the songs collection uses 2.
      # data.must_match "6   Representable::Deserializer#initialize"
      # # one populater for every property.
      # data.must_match "5   Representable::Populator#initialize"
      # printer.print(STDOUT)
    end
  end
end