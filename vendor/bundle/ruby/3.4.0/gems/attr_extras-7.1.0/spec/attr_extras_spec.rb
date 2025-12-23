require "spec_helper"

describe AttrExtras do
  it "mixes helpers into all Modules (and thus all Classes)" do
    mod = Module.new do
      pattr_initialize :name
    end

    klass = Class.new do
      include mod
    end

    _(klass.new("Hello").send(:name)).must_equal "Hello"
  end
end
