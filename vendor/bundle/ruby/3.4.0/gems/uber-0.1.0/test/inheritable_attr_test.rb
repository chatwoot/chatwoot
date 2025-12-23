require 'test_helper'
require "uber/inheritable_attr"

class InheritableAttrTest < MiniTest::Spec
  describe "::inheritable_attr" do
    subject {
      Class.new(Object) do
        extend Uber::InheritableAttribute
        inheritable_attr :drinks
        inheritable_attr :glass
        inheritable_attr :guests, clone: false
      end
    }

    def assert_nothing_raised(*)
      yield
    end

    it "provides a reader with empty inherited attributes, already" do
      assert_equal nil, subject.drinks
    end

    it "provides a reader with empty inherited attributes in a derived class" do
      assert_equal nil, Class.new(subject).drinks
      #subject.drinks = true
      #Class.new(subject).drinks # TODO: crashes.
    end

    it "provides an attribute copy in subclasses" do
      subject.drinks = []
      assert subject.drinks.object_id != Class.new(subject).drinks.object_id
    end

    it "provides a writer" do
      subject.drinks = [:cabernet]
      assert_equal [:cabernet], subject.drinks
    end

    it "inherits attributes" do
      subject.drinks = [:cabernet]

      subklass_a = Class.new(subject)
      subklass_a.drinks << :becks

      subklass_b = Class.new(subject)

      assert_equal [:cabernet],         subject.drinks
      assert_equal [:cabernet, :becks], subklass_a.drinks
      assert_equal [:cabernet],         subklass_b.drinks
    end

    it "does not inherit attributes if we set explicitely" do
      subject.drinks = [:cabernet]
      subklass = Class.new(subject)

      subklass.drinks = [:merlot] # we only want merlot explicitely.
      assert_equal [:merlot], subklass.drinks # no :cabernet, here
    end

    it "respects clone: false" do
      subject.guests = 2
      subklass_a = Class.new(subject)
      subklass_b = Class.new(subject)
      subklass_a.guests = 13

      assert_equal 2,  subklass_b.guests
      assert_equal 13, subklass_a.guests
    end

    it "does not attempt to clone symbols" do
      subject.glass = :highball
      subklass = Class.new(subject)

      subklass.glass.must_equal :highball
    end

    it "does not attempt to clone true" do
      subject.glass = true
      subklass = Class.new(subject)

      subklass.glass.must_equal true
    end

    it "does not attempt to clone false" do
      subject.glass = false
      subklass = Class.new(subject)

      subklass.glass.must_equal false
    end
  end
end
