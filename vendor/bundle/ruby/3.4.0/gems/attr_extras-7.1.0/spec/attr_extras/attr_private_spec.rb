require "spec_helper"

describe Object, ".attr_private" do
  let(:klass) do
    Class.new do
      attr_private :foo, :bar
    end
  end

  it "creates private readers" do
    example = klass.new
    example.instance_variable_set("@foo", "Foo")
    example.instance_variable_set("@bar", "Bar")
    _(example.send(:foo)).must_equal "Foo"
    _(example.send(:bar)).must_equal "Bar"
    _(lambda { example.foo }).must_raise NoMethodError
  end
end
