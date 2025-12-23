require "spec_helper"

describe Object, ".attr_initialize" do
  let(:klass) do
    Class.new do
      attr_initialize :foo, :bar

      def self.name
        "ExampleClass"
      end
    end
  end

  it "creates an initializer setting those instance variables" do
    example = klass.new("Foo", "Bar")
    _(example.instance_variable_get("@foo")).must_equal "Foo"
    _(example.instance_variable_get("@bar")).must_equal "Bar"
  end

  it "requires all arguments" do
    exception = _(lambda { klass.new("Foo") }).must_raise ArgumentError
    _(exception.message).must_equal "wrong number of arguments (1 for 2) for ExampleClass initializer"
  end

  it "can set ivars from a hash" do
    klass = Class.new do
      attr_initialize :foo, [ :bar, :baz ]
    end

    example = klass.new("Foo", bar: "Bar", baz: "Baz")
    _(example.instance_variable_get("@foo")).must_equal "Foo"
    _(example.instance_variable_get("@bar")).must_equal "Bar"
    _(example.instance_variable_get("@baz")).must_equal "Baz"
  end

  it "can set default values for keyword arguments" do
    klass = Class.new do
      attr_initialize :foo, [ :bar, baz: "default baz" ]
    end

    example = klass.new("Foo", bar: "Bar")
    _(example.instance_variable_get("@foo")).must_equal "Foo"
    _(example.instance_variable_get("@bar")).must_equal "Bar"
    _(example.instance_variable_get("@baz")).must_equal "default baz"

    example = klass.new("Foo", bar: "Bar", baz: "Baz")
    _(example.instance_variable_get("@baz")).must_equal "Baz"
  end

  it "treats hash values as optional" do
    klass = Class.new do
      attr_initialize :foo, [ :bar, :baz ]
    end

    example = klass.new("Foo", bar: "Bar")
    _(example.instance_variable_defined?("@baz")).must_equal false

    example = klass.new("Foo")
    _(example.instance_variable_defined?("@bar")).must_equal false
  end

  it "can require hash values" do
    klass = Class.new do
      attr_initialize [ :optional, :required! ]
    end

    example = klass.new(required: "X")
    _(example.instance_variable_get("@required")).must_equal "X"

    _(lambda { klass.new(optional: "X") }).must_raise KeyError
  end

  it "complains about unknown hash values" do
    klass = Class.new do
      attr_initialize :foo, [ :bar, :baz! ]
    end

    # Should not raise.
    klass.new("Foo", bar: "Bar", baz: "Baz")

    exception = _(lambda { klass.new("Foo", bar: "Bar", baz: "Baz", hello: "Hello") }).must_raise ArgumentError
    _(exception.message).must_include "[:hello]"
  end

  # Regression.
  it "assigns hash values to positional arguments even when there's also hash arguments" do
    klass = Class.new do
      attr_initialize :foo, [ :bar ]
    end

    # Should not raise.
    klass.new({ inside_foo: 123 }, bar: 456)
  end

  # Regression.
  it "only looks at hash arguments when determining missing required keys" do
    klass = Class.new do
      attr_initialize :foo, [ :bar! ]
    end

    # Provides a hash to "foo" but does not provide "bar".
    exception = _(lambda { klass.new({ bar: 123 }) }).must_raise KeyError
    _(exception.message).must_include "[:bar]"
  end

  # Regression.
  it "doesn't store hash values to positional arguments as ivars" do
    klass = Class.new do
      attr_initialize :foo
      attr_reader :foo
    end

    # Should not raise.
    example = klass.new({ "invalid.ivar.name" => 123 })

    _(example.foo).must_equal({ "invalid.ivar.name" => 123 })
  end

  it "accepts a block for initialization" do
    klass = Class.new do
      attr_initialize :value do
        @copy = @value
      end

      attr_reader :copy
    end

    example = klass.new("expected")

    _(example.copy).must_equal "expected"
  end
end
