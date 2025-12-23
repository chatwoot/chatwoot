require "test_helper"

class PrivateOptionsTest < MiniTest::Spec # TODO: move me to separate file.
  representer!(decorator: true) do
  end

  options = {exclude: "name"}

  it "render: doesn't modify options" do
    representer.new(nil).to_hash(options)
    _(options).must_equal({exclude: "name"})
  end

  it "parse: doesn't modify options" do
    representer.new(nil).from_hash(options)
    _(options).must_equal({exclude: "name"})
  end
end