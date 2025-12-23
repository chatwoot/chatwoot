require 'test_helper'

class InlineTest < MiniTest::Spec
  let(:song)    { Song.new("Alive") }
  let(:request) { representer.prepare(OpenStruct.new(:song => song)) }

  {
    :hash => [Representable::Hash, {"song"=>{"name"=>"Alive"}}, {"song"=>{"name"=>"You've Taken Everything"}}],
    :json => [Representable::JSON, "{\"song\":{\"name\":\"Alive\"}}", "{\"song\":{\"name\":\"You've Taken Everything\"}}"],
    :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  }.each do |format, cfg|
    mod, output, input = cfg

    describe "[#{format}] with :class" do
      representer!(:module => mod) do
        property :song, :class => Song do
          property :name
        end
      end

      let(:format) { format }

      it { render(request).must_equal_document output }
      it { _(parse(request, input).song.name).must_equal "You've Taken Everything"}
    end
  end

  {
    :hash => [Representable::Hash, {"songs"=>[{"name"=>"Alive"}]}, {"songs"=>[{"name"=>"You've Taken Everything"}]}],
    :json => [Representable::JSON, "{\"songs\":[{\"name\":\"Alive\"}]}", "{\"songs\":[{\"name\":\"You've Taken Everything\"}]}"],
    :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song></open_struct>", { :as => :song }],
    :yaml => [Representable::YAML, "---\nsongs:\n- name: Alive\n", "---\nsongs:\n- name: You've Taken Everything\n"],
  }.each do |format, cfg|
    mod, output, input, collection_options = cfg
    collection_options ||= {}

    describe "[#{format}] collection with :class" do
      let(:request) { representer.prepare(OpenStruct.new(:songs => [song])) }

      representer!(:module => mod) do
        collection :songs, collection_options.merge(:class => Song) do
          property :name
        end
      end

      let(:format) { format } # FIXME: why do we have to define this?

      it { render(request).must_equal_document output }
      it { _(parse(request, input).songs.first.name).must_equal "You've Taken Everything"}
    end
  end

  describe "without :class" do
    representer! do
      property :song do
        property :name
      end
    end

    it { _(request.to_hash).must_equal({"song"=>{"name"=>"Alive"}}) }
  end


  for_formats(
    :hash => [Representable::Hash, {}],
    # :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    # :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  ) do |format, mod, input|

    describe "parsing [#{format}] where nested property missing" do
      representer!(:module => mod) do
        property :song do
          property :name
        end
      end

      it "doesn't change represented object" do
        _(request.send("from_#{format}", input).song).must_equal song
      end
    end
  end


  describe "inheriting from outer representer" do
    let(:request) { Struct.new(:song, :requester).new(song, "Josephine") }

    [false, true].each do |is_decorator| # test for module and decorator.
      representer!(:decorator => is_decorator) do
        property :requester

        property :song, :class => Song do
          property :name
        end
      end

      let(:decorator) { representer.prepare(request) }

      it { _(decorator.to_hash).must_equal({"requester"=>"Josephine", "song"=>{"name"=>"Alive"}}) }
      it { _(decorator.from_hash({"song"=>{"name"=>"You've Taken Everything"}}).song.name).must_equal "You've Taken Everything"}
    end
  end

  describe "object pollution" do
    representer!(:decorator => true) do
      property :song do
        property :name
      end
    end

    it "uses an inline decorator and doesn't alter represented" do
      representer.prepare(Struct.new(:song).new(song)).to_hash
      _(song).wont_be_kind_of Representable
    end
  end

  # TODO: should be in extend:/decorator: test.
  # FIXME: this tests :getter{represented}+:extend - represented gets extended twice and the inline decorator overrides original config.
  # for_formats(
  #   :hash => [Representable::Hash, {"album" => {"artist" => {"label"=>"Epitaph"}}}],
  #   # :xml  => [Representable::XML, "<open_struct></open_struct>"],
  #   #:yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n"]
  # ) do |format, mod, output, input|

  #   module ArtistRepresenter
  #     include Representable::JSON
  #     property :label
  #   end

  #   describe ":getter with inline representer" do
  #     let(:format) { format }

  #     representer!(:module => mod) do
  #       self.representation_wrap = :album

  #       property :artist, :getter => lambda { |args| represented }, :extend => ArtistRepresenter
  #     end

  #     let(:album) { OpenStruct.new(:label => "Epitaph").extend(representer) }

  #     it "renders nested Album-properties in separate section" do
  #       render(album).must_equal_document output
  #     end
  #   end
  # end


  for_formats({
      :hash => [Representable::Hash, {"album" => {"artist" => {"label"=>"Epitaph"}}}],
      # :xml  => [Representable::XML, "<open_struct></open_struct>"],
      #:yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n"]
    }) do |format, mod, output, input|

    class ArtistDecorator < Representable::Decorator
      include Representable::JSON
      property :label
    end

    describe ":getter with :decorator" do
      let(:format) { format }

      representer!(:module => mod) do
        self.representation_wrap = "album"

        property :artist, :getter => lambda { |args| represented }, :decorator => ArtistDecorator
      end

      let(:album) { OpenStruct.new(:label => "Epitaph").extend(representer) }

      it "renders nested Album-properties in separate section" do
        render(album).must_equal_document output
      end
    end
  end


  # test helper methods within inline representer
  for_formats({
    :hash => [Representable::Hash, {"song"=>{"name"=>"ALIVE"}}],
    :xml  => [Representable::XML, "<request>\n  <song>\n    <name>ALIVE</name>\n  </song>\n</request>"],
    :yaml => [Representable::YAML, "---\nsong:\n  name: ALIVE\n"],
  }) do |format, mod, output|

    describe "helper method within inline representer [#{format}]" do
      let(:format) { format }

      representer!(:module => mod, :decorator => true) do
        self.representation_wrap = :request if format == :xml

        property :requester
        property :song do
          property :name, :exec_context => :decorator

          define_method :name do
            represented.name.upcase
          end

          self.representation_wrap = :song if format == :xml
        end
      end

      let(:request) { representer.prepare(OpenStruct.new(:song => Song.new("Alive"))) }

      it do
        render(request).must_equal_document output
      end
    end
  end


  describe "include module in inline representers" do
    representer! do
      extension = Module.new do
        include Representable::Hash
        property :title
      end

      property :song do
        include extension
        property :artist
      end
    end

    it do _(OpenStruct.new(:song => OpenStruct.new(:title => "The Fever And The Sound", :artist => "Strung Out")).extend(representer).
      to_hash).
      must_equal({"song"=>{"artist"=>"Strung Out", "title"=>"The Fever And The Sound"}})
    end
  end


  # define method in inline representer
  describe "define method in inline representer" do
    Mod = Module.new do
      include Representable::Hash

      def song
        "Object.new"
      end

      property :song do
        property :duration

        def duration
          "6:53"
        end
      end
    end

    it { _(Object.new.extend(Mod).to_hash).must_equal("song"=>{"duration"=>"6:53"}) }
  end

  # define method inline with Decorator
  describe "define method inline with Decorator" do
    dec = Class.new(Representable::Decorator) do
      include Representable::Hash

      def song
        "Object.new"
      end

      property :song, :exec_context => :decorator do
        property :duration, :exec_context => :decorator

        def duration
          "6:53"
        end
      end
    end

    it { _(dec.new(Object.new).to_hash).must_equal("song"=>{"duration"=>"6:53"}) }
  end
end
