require "spec_helper_without_loading_attr_extras"
require "attr_extras/explicit"

# Sanity check.
if String.respond_to?(:pattr_initialize)
  raise "Expected this test suite not to have AttrExtras mixed in!"
end

describe AttrExtras, "explicit mode" do
  it "must have methods mixed in explicitly" do
    has_methods_before_mixin = nil
    has_methods_after_mixin = nil

    Class.new do
      has_methods_before_mixin = respond_to?(:pattr_initialize)
      extend AttrExtras.mixin
      has_methods_after_mixin = respond_to?(:pattr_initialize)
    end

    refute has_methods_before_mixin
    assert has_methods_after_mixin
  end
end
