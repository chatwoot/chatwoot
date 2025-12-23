require 'test_helper'

class IfTest < MiniTest::Spec
  let(:band_class) { Class.new do
    include Representable::Hash
    attr_accessor :fame
    self
  end }

  it "respects property when condition true" do
    band_class.class_eval { property :fame, :if => lambda { |*| true } }
    band = band_class.new
    band.from_hash({"fame"=>"oh yes"})
    assert_equal "oh yes", band.fame
  end

  it "ignores property when condition false" do
    band_class.class_eval { property :fame, :if => lambda { |*| false } }
    band = band_class.new
    band.from_hash({"fame"=>"oh yes"})
    assert_nil band.fame
  end

  it "ignores property when :exclude'ed even when condition is true" do
    band_class.class_eval { property :fame, :if => lambda { |*| true } }
    band = band_class.new
    band.from_hash({"fame"=>"oh yes"}, {:exclude => [:fame]})
    assert_nil band.fame
  end

  it "executes block in instance context" do
    band_class.class_eval { property :fame, :if => lambda { |*| groupies }; attr_accessor :groupies }
    band = band_class.new
    band.groupies = true
    band.from_hash({"fame"=>"oh yes"})
    assert_equal "oh yes", band.fame
  end

  describe "executing :if lambda in represented instance context" do
    representer! do
      property :label, :if => lambda { |*| signed_contract }
    end

    subject { OpenStruct.new(:signed_contract => false, :label => "Fat") }

    it "skips when false" do
      _(subject.extend(representer).to_hash).must_equal({})
    end

    it "represents when true" do
      subject.signed_contract= true
      _(subject.extend(representer).to_hash).must_equal({"label"=>"Fat"})
    end

    it "works with decorator" do
      rpr = representer
      _(Class.new(Representable::Decorator) do
        include Representable::Hash
        include rpr
      end.new(subject).to_hash).must_equal({})
    end
  end


  describe "propagating user options to the block" do
    representer! do
      property :name, :if => lambda { |opts| opts[:user_options][:include_name] }
    end
    subject { OpenStruct.new(:name => "Outbound").extend(representer) }

    it "works without specifying options" do
      _(subject.to_hash).must_equal({})
    end

    it "passes user options to block" do
      _(subject.to_hash(user_options: { include_name: true })).must_equal({"name" => "Outbound"})
    end
  end
end