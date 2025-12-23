require 'test_helper'

class InheritTest < MiniTest::Spec
  module SongRepresenter # it's important to have a global module so we can test if stuff gets overridden in the original module.
    include Representable::Hash
    property :name, :as => :title do
      property :string, :as => :str
    end

    property :track, :as => :no
  end

  let(:song) { Song.new(Struct.new(:string).new("Roxanne"), 1) }

  describe ":inherit plain property" do
    representer! do
      include SongRepresenter

      property :track, :inherit => true, :getter => lambda { |*| "n/a" }
    end

    it { _(SongRepresenter.prepare(song).to_hash).must_equal({"title"=>{"str"=>"Roxanne"}, "no"=>1}) }
    it { _(representer.prepare(song).to_hash).must_equal({"title"=>{"str"=>"Roxanne"}, "no"=>"n/a"}) } # as: inherited.
  end

  describe ":inherit with empty inline representer" do
    representer! do
      include SongRepresenter

      property :name, :inherit => true do # inherit as: title
        # that doesn't make sense.
      end
    end

    it { _(SongRepresenter.prepare(Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
    # the block doesn't override the inline representer.
    it { _(representer.prepare( Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
  end

  describe ":inherit with overriding inline representer" do
    representer! do
      include SongRepresenter

      # passing block
      property :name, :inherit => true do # inherit as: title
        property :string, :as => :s
        property :length
      end
    end

    it { _(representer.prepare( Song.new(Struct.new(:string, :length).new("Believe It", 10), 1)).to_hash).must_equal({"title"=>{"s"=>"Believe It","length"=>10}, "no"=>1}) }
  end

  describe ":inherit with empty inline and options" do
    representer! do
      include SongRepresenter

      property :name, inherit: true, as: :name do # inherit module, only.
        # that doesn't make sense. but it should simply inherit the old nested properties.
      end
    end

    it { _(SongRepresenter.prepare(Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
    it { _(representer.prepare( Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"name"=>{"str"=>"Believe It"}, "no"=>1}) }
  end

  describe ":inherit with inline without block but options" do
    representer! do
      include SongRepresenter

      property :name, :inherit => true, :as => :name # FIXME: add :getter or something else dynamic since this is double-wrapped.
    end

    it { _(SongRepresenter.prepare(Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
    it { _(representer.prepare( Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash).must_equal({"name"=>{"str"=>"Believe It"}, "no"=>1}) }
  end



  # no :inherit
  describe "overwriting without :inherit" do
    representer! do
      include SongRepresenter

      property :track, :representable => true
    end

    it "replaces inherited property" do
      _(representer.representable_attrs.size).must_equal 2

      definition = representer.representable_attrs.get(:track) # TODO: find a better way to assert Definition identity.
      # definition.keys.size.must_equal 2
      _(definition[:representable]).   must_equal true
      _(definition.name).must_equal "track" # was "no".
    end
  end


  # decorator
  describe ":inherit with decorator" do
    representer!(:decorator => true) do
      property :hit do
        property :title, exec_context: :decorator

        def title
          "Cheap Transistor Radio"
        end
      end
    end

    let(:inheriting) {
      class InheritingDecorator < representer
        include Representable::Debug
        property :hit, :inherit => true do
          include Representable::Debug
          property :length
        end
        self
      end
    }

    it { _(representer.new(OpenStruct.new(hit: OpenStruct.new(title: "I WILL BE OVERRIDDEN", :length => "2:59"))).to_hash).must_equal(
      {"hit"=>{"title"=>"Cheap Transistor Radio"}}) }

    # inheriting decorator inherits inline representer class (InlineRepresenter#title).
    # inheriting decorator adds :length.
    it { _(inheriting.new(OpenStruct.new(:hit => OpenStruct.new(:title => "Hole In Your Soul", :length => "2:59"))).to_hash).must_equal(
      {"hit"=>{"title"=>"Cheap Transistor Radio", "length"=>"2:59"}}) }
  end


  # :inherit when property doesn't exist, yet.
  describe ":inherit without inheritable property" do
    representer! do
      property :name, :inherit => true
    end

    it { _(representer.prepare(Song.new("The Beginning")).to_hash).must_equal({"name"=>"The Beginning"})}
  end
end


# class InheritancingTest < MiniTest::Spec
#   class SongDecorator < Representable::Decorator
#     include Representable::Hash
#     property :album do
#       # does have Hash.
#       property :title
#     end
#   end

#   class JsonSongDecorator < SongDecorator
#     include Representable::XML
#   end

#   it do
#     puts JsonSongDecorator.new(OpenStruct.new(:album => OpenStruct.new(:title => "Erotic Cakes", :tracks => nil))).to_xml
#   end
# end
