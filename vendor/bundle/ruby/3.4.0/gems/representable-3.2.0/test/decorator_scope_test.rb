require 'test_helper'

# TODO: remove in 2.0.
class DecoratorScopeTest < MiniTest::Spec
  representer! do
    property :title, :getter => lambda { |*| title_from_representer }, :decorator_scope => true
  end

  let(:representer_with_method) {
    Module.new do
      include Representable::Hash
      property :title, :decorator_scope => true
      def title; "Crystal Planet"; end
    end
   }

  it "executes lambdas in represented context" do
    _(Class.new do
      def title_from_representer
        "Sounds Of Silence"
      end
    end.new.extend(representer).to_hash).must_equal({"title"=>"Sounds Of Silence"})
  end

  it "executes method in represented context" do
    _(Object.new.extend(representer_with_method).to_hash).must_equal({"title"=>"Crystal Planet"})
  end
end