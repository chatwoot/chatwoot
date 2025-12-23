require 'test_helper'

class BindingTest < MiniTest::Spec
  Binding = Representable::Binding
  let(:render_nil_definition) { Representable::Definition.new(:song, :render_nil => true) }

  describe "#skipable_empty_value?" do
    let(:binding) { Binding.new(render_nil_definition) }

    # don't skip when present.
    it { _(binding.skipable_empty_value?("Disconnect, Disconnect")).must_equal false }

    # don't skip when it's nil and render_nil: true
    it { _(binding.skipable_empty_value?(nil)).must_equal false }

    # skip when nil and :render_nil undefined.
    it { _(Binding.new(Representable::Definition.new(:song)).skipable_empty_value?(nil)).must_equal true }

    # don't skip when nil and :render_nil undefined.
    it { _(Binding.new(Representable::Definition.new(:song)).skipable_empty_value?("Fatal Flu")).must_equal false }
  end


  describe "#default_for" do
    let(:definition) { Representable::Definition.new(:song, :default => "Insider") }
    let(:binding) { Binding.new(definition) }

    # return value when value present.
    it { _(binding.default_for("Black And Blue")).must_equal "Black And Blue" }

    # return false when value false.
    it { _(binding.default_for(false)).must_equal false }

    # return default when value nil.
    it { _(binding.default_for(nil)).must_equal "Insider" }

    # return nil when value nil and render_nil: true.
    it { _(Binding.new(render_nil_definition).default_for(nil)).must_be_nil }

    # return nil when value nil and render_nil: true, even when :default is set" do
    it { _(Binding.new(Representable::Definition.new(:song, :render_nil => true, :default => "The Quest")).default_for(nil)).must_be_nil }

    # return nil if no :default
    it { _(Binding.new(Representable::Definition.new(:song)).default_for(nil)).must_be_nil }
  end
end