require "spec_helper"

describe Object, ".aattr_initialize" do
  it "creates an initializer and public readers" do
    klass = Class.new do
      aattr_initialize :foo, :bar
    end

    example = klass.new("Foo", "Bar")

    _(example.foo).must_equal "Foo"
  end

  it "creates public writers" do
    klass = Class.new do
      aattr_initialize :foo, :bar
    end

    example = klass.new("Foo", "Bar")
    example.foo = "Baz"

    _(example.foo).must_equal "Baz"
  end

  it "works with hash ivars" do
    klass = Class.new do
      aattr_initialize :foo, [ :bar, :baz! ]
    end

    example = klass.new("Foo", bar: "Bar", baz: "Baz")

    _(example.baz).must_equal "Baz"
  end

  it "works with hash ivars and default values" do
    klass = Class.new do
      aattr_initialize :foo, [ bar: "Bar", baz!: "Baz" ]
    end

    example = klass.new("Foo")

    _(example.baz).must_equal "Baz"
  end

  it "accepts a block for initialization" do
    klass = Class.new do
      aattr_initialize :value do
        @copy = @value
      end

      attr_reader :copy
    end

    example = klass.new("expected")

    _(example.copy).must_equal "expected"
  end

  it "accepts the alias attr_accessor_initialize" do
    klass = Class.new do
      attr_accessor_initialize :foo, :bar
    end

    example = klass.new("Foo", "Bar")

    _(example.foo).must_equal "Foo"
  end

  it "does not use the same default value object across class instances" do
    klass = Class.new do
      aattr_initialize [:name, items: []]
    end

    data = [
      { name: "One", items: [1, 2, 3] },
      { name: "Two", items: [4, 5, 6] },
    ]

    results = data.each_with_object([]) do |datum, results|
      name, items = datum.values_at(:name, :items)
      foo = klass.new(name: name)

      items.each do |n|
        foo.items << n
      end

      results << foo
    end

    _(results.first.items).must_equal [1, 2, 3]
    _(results.last.items).must_equal [4, 5, 6]
  end
end
