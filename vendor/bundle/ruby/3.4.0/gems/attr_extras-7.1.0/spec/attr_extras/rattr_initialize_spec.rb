require "spec_helper"

describe Object, ".rattr_initialize" do
  it "creates both initializer and public readers" do
    klass = Class.new do
      rattr_initialize :foo, :bar
    end

    example = klass.new("Foo", "Bar")
    _(example.public_send(:foo)).must_equal "Foo"
  end

  it "works with hash ivars" do
    klass = Class.new do
      rattr_initialize :foo, [ :bar, :baz! ]
    end

    example = klass.new("Foo", bar: "Bar", baz: "Baz")
    _(example.public_send(:baz)).must_equal "Baz"
  end

  it "works with hash ivars and default values" do
    klass = Class.new do
      rattr_initialize :foo, [ bar: "Bar", baz!: "Baz" ]
    end

    example = klass.new("Foo")
    _(example.send(:baz)).must_equal "Baz"
  end

  it "accepts the alias attr_reader_initialize" do
    klass = Class.new do
      attr_reader_initialize :foo, :bar
    end

    example = klass.new("Foo", "Bar")
    _(example.public_send(:foo)).must_equal "Foo"
  end
end
