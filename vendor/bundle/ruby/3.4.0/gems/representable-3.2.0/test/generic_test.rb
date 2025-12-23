require 'test_helper'

class GenericTest < MiniTest::Spec # TODO: rename/restructure to CollectionTest.
  let(:new_album)  { OpenStruct.new.extend(representer) }
  let(:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let(:song) { OpenStruct.new(:title => "Resist Stance") }
  let(:song_representer) { Module.new do include Representable::Hash; property :title end  }


  describe "::collection" do
    representer! do
      collection :songs
    end

    it "doesn't initialize property" do
      new_album.from_hash({})
      _(new_album.songs).must_be_nil
    end

    it "leaves properties untouched" do
      album.from_hash({})
      # TODO: test property.
      _(album.songs).must_equal ["Fuck Armageddon"] # when the collection is not present in the incoming hash, this propery stays untouched.
    end


    # when collection is nil, it doesn't get rendered:
    for_formats(
      :hash => [Representable::Hash, {}],
      :xml  => [Representable::XML, "<open_struct></open_struct>"],
      :yaml => [Representable::YAML, "--- {}\n"], # FIXME: this doesn't look right.
    ) do |format, mod, output, input|

      describe "nil collections" do
        let(:format) { format }

        representer!(:module => mod) do
          collection :songs
          self.representation_wrap = :album if format == :xml
        end

        let(:album) { Album.new.extend(representer) }

        it "doesn't render collection in #{format}" do
          render(album).must_equal_document output
        end
      end
    end

    # when collection is set but empty, render the empty collection.
    for_formats(
      :hash => [Representable::Hash, {"songs" => []}],
      #:xml  => [Representable::XML, "<open_struct><songs/></open_struct>"],
      :yaml => [Representable::YAML, "---\nsongs: []\n"],
    ) do |format, mod, output, input|

      describe "empty collections" do
        let(:format) { format }

        representer!(:module => mod) do
          collection :songs
          self.representation_wrap = :album if format == :xml
        end

        let(:album) { OpenStruct.new(:songs => []).extend(representer) }

        it "renders empty collection in #{format}" do
          render(album).must_equal_document output
        end
      end
    end


    # when collection is [], suppress rendering when render_empty: false.
    for_formats(
      :hash => [Representable::Hash, {}],
      #:xml  => [Representable::XML, "<open_struct><songs/></open_struct>"],
      :yaml => [Representable::YAML, "--- {}\n"],
    ) do |format, mod, output, input|

      describe "render_empty [#{format}]" do
        let(:format) { format }

        representer!(:module => mod) do
          collection :songs, :render_empty => false
          self.representation_wrap = :album if format == :xml
        end

        let(:album) { OpenStruct.new(:songs => []).extend(representer) }

        it { render(album).must_equal_document output }
      end
    end
  end


  # wrap_test
  for_formats(
    :hash => [Representable::Hash, {}],
    # :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    # :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  ) do |format, mod, input|

    describe "parsing [#{format}] with wrap where wrap is missing" do
      representer!(:module => mod) do
        self.representation_wrap = :song

        property :title
      end

      it "doesn't change represented object" do
        _(song.extend(representer).send("from_#{format}", input).title).must_equal "Resist Stance"
      end
    end
  end
end