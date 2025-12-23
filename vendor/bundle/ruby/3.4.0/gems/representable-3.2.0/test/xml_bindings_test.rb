require 'test_helper'
require 'representable/xml/hash'

class XMLBindingTest < MiniTest::Spec
  module SongRepresenter
    include Representable::XML
    property :name
    self.representation_wrap = :song
  end

  class SongWithRepresenter < ::Song
    include Representable
    include SongRepresenter
    self.representation_wrap = :song
  end

  before do
    @doc  = Nokogiri::XML::Document.new
    @song = SongWithRepresenter.new("Thinning the Herd")
  end




  describe "AttributeBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::XML::Binding::Attribute.new(Representable::Definition.new(:name, :attribute => true))
      end

      it "extracts with #read" do
        assert_equal "The Gargoyle", @property.read(Nokogiri::XML("<song name=\"The Gargoyle\" />").root, "name")
      end

      it "inserts with #write" do
        parent = Nokogiri::XML::Node.new("song", @doc)
        @property.write(parent, "The Gargoyle", "name")
        assert_xml_equal("<song name=\"The Gargoyle\" />", parent.to_s)
      end
    end
  end

  describe "ContentBinding" do
    before do
      @property = Representable::XML::Binding::Content.new(Representable::Definition.new(:name, :content => true))
    end

    it "extracts with #read" do
      assert_equal "The Gargoyle", @property.read(Nokogiri::XML("<song>The Gargoyle</song>").root, "song")
    end

    it "inserts with #write" do
      parent = Nokogiri::XML::Node.new("song", @doc)
      @property.write(parent, "The Gargoyle", "song")
      assert_xml_equal("<song>The Gargoyle</song>", parent.to_s)
    end
  end
end
