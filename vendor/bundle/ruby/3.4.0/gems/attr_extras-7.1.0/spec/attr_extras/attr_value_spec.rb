require "spec_helper"
require "set"

describe Object, ".attr_value" do
  it "creates public readers" do
    klass = Class.new do
      attr_value :foo, :bar
    end

    example = klass.new
    example.instance_variable_set("@foo", "Foo")
    _(example.foo).must_equal "Foo"
  end

  it "does not create writers" do
    klass = Class.new do
      attr_value :foo
    end

    _(lambda { klass.new.foo = "new value" }).must_raise NoMethodError
  end

  describe "object equality" do
    it "is based on attribute values" do
      klass = Class.new do
        attr_initialize :foo, :bar
        attr_value :foo, :bar
      end

      example1 = klass.new("Foo", "Bar")
      example2 = klass.new("Foo", "Bar")
      example3 = klass.new("Foo", "Wat")

      assert example1 == example2, "Examples should be equal"
      refute example1 != example2, "Examples should be equal"

      refute example1 == example3, "Examples should not be equal"
      assert example1 != example3, "Examples should not be equal"
    end

    it "is based on class" do
      klass1 = Class.new do
        attr_initialize :foo
        attr_value :foo
      end
      klass2 = Class.new do
        attr_initialize :foo
        attr_value :foo
      end

      example1 = klass1.new("Foo")
      example2 = klass2.new("Foo")

      assert example1 != example2, "Examples should not be equal"
      refute example1 == example2, "Examples should not be equal"
    end

    it "considers an instance equal to itself" do
      klass = Class.new do
        attr_initialize :foo
        attr_value :foo
      end

      instance = klass.new("Foo")

      assert instance == instance, "Instance should be equal to itself"
    end

    it "can compare value objects to other kinds of objects" do
      klass = Class.new do
        attr_initialize :foo
        attr_value :foo
      end

      instance = klass.new("Foo")

      assert instance != "a string"
    end

    it "hashes objects the same if they have the same attributes" do
      klass1 = Class.new do
        attr_initialize :foo
        attr_value :foo
      end
      klass2 = Class.new do
        attr_initialize :foo
        attr_value :foo
      end

      klass1_foo = klass1.new("Foo")
      klass1_foo2 = klass1.new("Foo")
      klass1_bar = klass1.new("Bar")
      klass2_foo = klass2.new("Foo")

      _(klass1_foo.hash).must_equal klass1_foo2.hash
      _(klass1_foo.hash).wont_equal klass1_bar.hash
      _(klass1_foo.hash).wont_equal klass2_foo.hash

      assert klass1_foo.eql?(klass1_foo2), "Examples should be 'eql?'"
      refute klass1_foo.eql?(klass1_bar), "Examples should not be 'eql?'"
      refute klass1_foo.eql?(klass2_foo), "Examples should not be 'eql?'"

      _(Set[klass1_foo, klass1_foo2, klass1_bar, klass2_foo].length).must_equal 3

      hash = {}
      hash[klass1_foo] = :awyeah
      hash[klass1_bar] = :wat
      hash[klass2_foo] = :nooooo
      _(hash[klass1_foo2]).must_equal :awyeah
    end
  end
end
