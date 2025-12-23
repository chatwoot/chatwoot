require "spec_helper"

describe Object, ".attr_query" do
  it "creates attribute query methods" do
    klass = Class.new do
      attr_query :flurp?
      attr_accessor :flurp
    end

    example = klass.new
    refute example.flurp?
    example.flurp = "!"
    assert example.flurp?
  end

  it "requires a trailing questionmark" do
    _(lambda { Object.attr_query(:foo) }).must_raise ArgumentError
  end
end
