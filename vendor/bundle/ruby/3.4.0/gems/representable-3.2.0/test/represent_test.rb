require 'test_helper'

class RepresentTest < MiniTest::Spec
  let(:songs) { [song, Song.new("Can't Take Them All")] }
  let(:song) { Song.new("Days Go By") }

  for_formats(
    :hash => [Representable::Hash, out=[{"name" => "Days Go By"}, {"name"=>"Can't Take Them All"}], out],
    # :json => [Representable::JSON, out="[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    # Representer.represents detects collection.
    describe "Module#to_/from_#{format}" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name

          collection_representer :class => Song # TODOOOOOOOOOOOO: test without Song and fix THIS FUCKINGNoMethodError: undefined method `name=' for {"name"=>"Days Go By"}:Hash ERROR!!!!!!!!!!!!!!!
        end
      }

      it { render(representer.represent(songs)).must_equal_document output }
      it { _(parse(representer.represent([]), input)).must_equal songs }
    end

    # Decorator.represents detects collection.
    describe "Decorator#to_/from_#{format}" do
      let(:format) { format }
      let(:representer) {
        Class.new(Representable::Decorator) do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.represent(songs)).must_equal_document output }
      it("ficken") { _(parse(representer.represent([]), input)).must_equal songs }
    end
  end


  for_formats(
    :hash => [Representable::Hash, out={"name" => "Days Go By"}, out],
    :json => [Representable::JSON, out="{\"name\":\"Days Go By\"}", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    # Representer.represents detects singular.
    describe "Module#to_/from_#{format}" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.represent(song)).must_equal_document output }
      it { _(parse(representer.represent(Song.new), input)).must_equal song }
    end


    # Decorator.represents detects singular.
    describe "Decorator#to_/from_#{format}" do
      let(:format) { format }
      let(:representer) {
        Class.new(Representable::Decorator) do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.represent(song)).must_equal_document output }
      it { _(parse(representer.represent(Song.new), input)).must_equal song }
    end
  end
end