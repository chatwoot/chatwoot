require "spec_helper"

describe Object, ".attr_id_query" do
  it "creates id query methods" do
    klass = Class.new do
      attr_id_query :baz?, :boink?
      attr_accessor :baz_id
    end

    example = klass.new
    refute example.baz?

    example.baz_id = 123
    assert example.baz?
  end

  it "requires a trailing questionmark" do
    _(lambda { Object.attr_id_query(:foo) }).must_raise ArgumentError
  end
end
