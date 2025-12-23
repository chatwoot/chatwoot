require 'test_helper'

class NestedTest < MiniTest::Spec
	Album = Struct.new(:label, :owner, :amount)

	for_formats(
    :hash => [Representable::Hash, {"label" => {"label"=>"Epitaph", "owner"=>"Brett Gurewitz", "releases"=>{"amount"=>19}}}],
    # :xml  => [Representable::XML, "<open_struct></open_struct>"],
    :yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n  releases:\n    amount: 19\n"]
  ) do |format, mod, output, input|

    [false, true].each do |is_decorator|
      describe "::nested with (inline representer|decorator): #{is_decorator}" do
        let(:format) { format }

        representer!(:module => mod, :decorator => is_decorator) do
          nested :label do
            property :label
            property :owner

            # self.representation_wrap = nil if format == :xml
            nested :releases do
              property :amount
            end
          end

          # self.representation_wrap = :album if format == :xml
        end

        let(:album) { Album.new("Epitaph", "Brett Gurewitz", 19) }
        let(:decorator) { representer.prepare(album) }

        it "renders nested Album-properties in separate section" do
          render(decorator).must_equal_document output

          # do not use extend on the nested object. # FIXME: make this a proper test with two describes instead of this pseudo-meta stuff.
          if is_decorator==true
            _(album).wont_be_kind_of(Representable::Hash)
          end
        end

        it "parses nested properties to Album instance" do
          album = parse(representer.prepare(Album.new), output)
          _(album.label).must_equal "Epitaph"
          _(album.owner).must_equal "Brett Gurewitz"
        end
      end
    end


    describe "Decorator ::nested with extend:" do
      let(:format) { format }

      representer!(:name => :label_rpr) do
      	include mod
      	property :label
        property :owner

        nested :releases do # DISCUSS: do we need to test this?
          property :amount
        end
      end

      representer!(:module => mod, :decorator => true, :inject => :label_rpr) do
        nested :label, :extend => label_rpr

        self.representation_wrap = :album if format == :xml
      end

      let(:album) { representer.prepare(Album.new("Epitaph", "Brett Gurewitz", 19)) }

      # TODO: shared example with above.
      it "renders nested Album-properties in separate section" do
        render(album).must_equal_document output
      end

      it "parses nested properties to Album instance" do
      	album = parse(representer.prepare(Album.new), output)
      	_(album.label).must_equal "Epitaph"
      	_(album.owner).must_equal "Brett Gurewitz"
        _(album.amount).must_equal 19
      end
    end
  end


  describe "::nested without block but with inherit:" do

    representer!(:name => :parent) do
      include Representable::Hash

      nested :label do
        property :owner
      end
    end

    representer!(:module => Representable::Hash, :inject => :parent) do
      include parent
      nested :label, :inherit => true, :as => "Label"
    end

    let(:album) { representer.prepare(Album.new("Epitaph", "Brett Gurewitz", 19)) }

    it "renders nested Album-properties in separate section" do
      _(representer.prepare(album).to_hash).must_equal({"Label"=>{"owner"=>"Brett Gurewitz"}})
    end

    # it "parses nested properties to Album instance" do
    #   album = parse(representer.prepare(Album.new), output)
    #   album.label.must_equal "Epitaph"
    #   album.owner.must_equal "Brett Gurewitz"
    #   album.amount.must_equal 19
    # end
  end
end