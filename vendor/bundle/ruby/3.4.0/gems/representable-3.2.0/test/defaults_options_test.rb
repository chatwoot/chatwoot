require 'test_helper'

class DefaultsOptionsTest < BaseTest
  let(:format) { :hash }
  let(:song) { Struct.new(:title, :author_name, :song_volume, :description).new("Revolution", "Some author", 20, nil) }
  let(:prepared) { representer.prepare song }

  describe "hash options combined with dynamic options" do
    representer! do
      defaults render_nil: true do |name|
        { as: name.to_s.upcase }
      end

      property :title
      property :author_name
      property :description
      property :song_volume
    end

    it { render(prepared).must_equal_document({"TITLE" => "Revolution", "AUTHOR_NAME" => "Some author", "DESCRIPTION" => nil, "SONG_VOLUME" => 20}) }
  end

  describe "with only dynamic property options" do
    representer! do
      defaults do |name|
        { as: name.to_s.upcase }
      end

      property :title
      property :author_name
      property :description
      property :song_volume
    end

    it { render(prepared).must_equal_document({"TITLE" => "Revolution", "AUTHOR_NAME" => "Some author", "SONG_VOLUME" => 20}) }
  end

  describe "with only hashes" do
    representer! do
      defaults render_nil: true

      property :title
      property :author_name
      property :description
      property :song_volume
    end

    it { render(prepared).must_equal_document({"title" => "Revolution", "author_name" => "Some author", "description" => nil, "song_volume" => 20}) }
  end

  describe "direct defaults hash" do
    representer! do
      defaults render_nil: true

      property :title
      property :author_name
      property :description
      property :song_volume
    end

    it { render(prepared).must_equal_document({"title" => "Revolution", "author_name" => "Some author", "description" => nil, "song_volume" => 20}) }
  end

  describe "direct defaults hash with dynamic options" do
    representer! do
      defaults render_nil: true do |name|
        { as: name.to_s.upcase }
      end

      property :title
      property :author_name
      property :description
      property :song_volume
    end

    it { render(prepared).must_equal_document({"TITLE" => "Revolution", "AUTHOR_NAME" => "Some author", "DESCRIPTION" => nil, "SONG_VOLUME" => 20}) }
  end

  describe "prioritizes specific options" do
    representer! do
      defaults render_nil: true do |name|
        { as: name.to_s.upcase }
      end

      property :title
      property :author_name
      property :description, render_nil: false
      property :song_volume, as: :volume
    end

    it { render(prepared).must_equal_document({"TITLE" => "Revolution", "AUTHOR_NAME" => "Some author", "volume" => 20}) }
  end
end
