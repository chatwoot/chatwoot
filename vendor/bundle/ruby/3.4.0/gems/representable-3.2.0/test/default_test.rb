require "test_helper"

class DefaultTest < MiniTest::Spec
  Song = Struct.new(:id, :title)

  representer! do
    property :id
    property :title, default: "Huber Breeze" #->(options) { options[:default] }
  end

  describe "#from_hash" do
    let(:song) { Song.new.extend(representer) }

    it { _(song.from_hash({})).must_equal Song.new(nil, "Huber Breeze") }
    # default doesn't apply when empty string.
    it { _(song.from_hash({"title"=>""})).must_equal Song.new(nil, "") }
    it { _(song.from_hash({"title"=>nil})).must_equal Song.new(nil, nil) }
    it { _(song.from_hash({"title"=>"Blindfold"})).must_equal Song.new(nil, "Blindfold") }
  end

  describe "#to_json" do
    it "uses :default when not available from object" do
      _(Song.new.extend(representer).to_hash).must_equal({"title"=>"Huber Breeze"})
    end

    it "uses value from represented object when present" do
      _(Song.new(nil, "After The War").extend(representer).to_hash).must_equal({"title"=>"After The War"})
    end

    it "uses value from represented object when emtpy string" do
      _(Song.new(nil, "").extend(representer).to_hash).must_equal({"title"=>""})
    end
  end
end