require "spec_helper"

describe Object, ".static_facade" do
  it "creates a class method that instantiates and runs that instance method" do
    klass = Class.new do
      static_facade :fooable?,
        :foo

      def fooable?
        foo
      end
    end

    assert klass.fooable?(true)
    refute klass.fooable?(false)
  end

  it "doesn't require attributes" do
    klass = Class.new do
      static_facade :fooable?

      def fooable?
        true
      end
    end

    assert klass.fooable?
  end

  it "accepts multiple method names" do
    klass = Class.new do
      static_facade [ :fooable?, :barable? ],
        :foo

      def fooable?
        foo
      end

      def barable?
        not foo
      end
    end

    assert klass.fooable?(true)
    assert klass.barable?(false)
  end

  it "accepts a block for initialization" do
    klass = Class.new do
      static_facade :foo, :value do
        @copy = @value
      end

      attr_reader :copy
    end

    example = klass.new("expected")

    _(example.copy).must_equal "expected"
  end

  it "passes along any block to the instance method" do
    klass = Class.new do
      static_facade :foo

      def foo
        yield
      end
    end

    assert klass.foo { :bar } == :bar
  end

  it "does not blow up when the class method is called with an empty hash" do
    klass = Class.new do
      static_facade :foo,
        :value

      def foo
      end
    end

    refute_raises_anything { klass.foo({}) }
  end

  it "does not emit warnings when the initializer is overridden with more keyword arguments" do
    superklass = Class.new do
      static_facade :something, [ :foo!, :bar! ]

      def something
      end
    end

    klass = Class.new(superklass) do
      def initialize(extra:, **rest)
        super(**rest)
        @extra = extra
      end
    end

    refute_warnings_emitted { klass.something(foo: 1, bar: 2, extra: "yay") }
  end
end
