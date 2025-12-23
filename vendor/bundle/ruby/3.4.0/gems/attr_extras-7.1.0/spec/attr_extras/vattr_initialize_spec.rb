require "spec_helper"

describe Object, ".vattr_initialize" do
  it "creates initializer, value readers and value object identity" do
    klass = Class.new do
      vattr_initialize :foo, :bar
    end

    example1 = klass.new("Foo", "Bar")
    example2 = klass.new("Foo", "Bar")

    _(example1.foo).must_equal "Foo"
    _(example1).must_equal example2
  end

  it "works with hash ivars" do
    klass = Class.new do
      vattr_initialize :foo, [ :bar, :baz! ]
    end

    example1 = klass.new("Foo", bar: "Bar", baz: "Baz")
    example2 = klass.new("Foo", bar: "Bar", baz: "Baz")
    _(example1.baz).must_equal "Baz"
    _(example1).must_equal example2
  end

  it "works with hash ivars and default values" do
    klass = Class.new do
      vattr_initialize :foo, [ bar: "Bar", baz!: "Baz" ]
    end

    example1 = klass.new("Foo")
    example2 = klass.new("Foo")
    _(example1.baz).must_equal "Baz"
    _(example1).must_equal example2
  end

  it "can accept an initializer block" do
    called = false
    klass = Class.new do
      vattr_initialize :value do
        called = true
      end
    end

    klass.new("expected")

    _(called).must_equal true
  end

  it "accepts the alias attr_value_initialize" do
    klass = Class.new do
      attr_value_initialize :foo, :bar
    end

    example1 = klass.new("Foo", "Bar")
    example2 = klass.new("Foo", "Bar")

    _(example1.foo).must_equal "Foo"
    _(example1).must_equal example2
  end
end
