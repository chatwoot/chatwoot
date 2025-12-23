require 'test_helper'

class ForCollectionTest < MiniTest::Spec
  module SongRepresenter
    include Representable::JSON

    property :name
  end

  let(:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
  let(:json)  { "[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]" }


  # Module.for_collection
  # Decorator.for_collection
  for_formats(
    :hash => [Representable::Hash, out=[{"name" => "Days Go By"}, {"name"=>"Can't Take Them All"}], out],
    :json => [Representable::JSON, out="[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    describe "Module::for_collection [#{format}]" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name#, :as => :title

          collection_representer :class => Song

          # self.representation_wrap = :songs if format == :xml
        end
      }

      it { render(songs.extend(representer.for_collection)).must_equal_document output }
      it { render(representer.for_collection.prepare(songs)).must_equal_document output }
      # parsing needs the class set, at least
      it { _(parse([].extend(representer.for_collection), input)).must_equal songs }
    end

    describe "Module::for_collection without configuration [#{format}]" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name
        end
      }

      # rendering works out of the box, no config necessary
      it { render(songs.extend(representer.for_collection)).must_equal_document output }
    end


    describe "Decorator::for_collection [#{format}]" do
      let(:format) { format }
      let(:representer) {
        Class.new(Representable::Decorator) do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.for_collection.new(songs)).must_equal_document output }
      it { _(parse(representer.for_collection.new([]), input)).must_equal songs }
    end
  end

  # with module including module
end