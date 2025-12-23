require "test_helper"

class RenderNilTest < MiniTest::Spec
  Song = Struct.new(:title)

  describe "render_nil: true" do
    representer! do
      property :title, render_nil: true
    end

    it { _(Song.new.extend(representer).to_hash).must_equal({"title"=>nil}) }
  end

  describe "with :extend it shouldn't extend nil" do
    representer! do
      property :title, render_nil: true, extend: Class
    end

    it { _(Song.new.extend(representer).to_hash).must_equal({"title"=>nil}) }
  end
end
