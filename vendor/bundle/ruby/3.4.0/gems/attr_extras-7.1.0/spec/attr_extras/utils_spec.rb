require "spec_helper"

describe AttrExtras::Utils do
  describe ".flat_names" do
    subject { AttrExtras::Utils.flat_names(names) }

    it "strips any bangs from a flat list of arguments" do
      _(AttrExtras::Utils.flat_names([ :foo, :bar! ])).must_equal [ "foo", "bar" ]
    end

    it "flattens hash arguments and strips any bangs" do
      _(AttrExtras::Utils.flat_names([ :foo, [ :bar, :baz! ] ])).must_equal [ "foo", "bar", "baz" ]
    end

    it "flattens hash arguments with defaults and strips any bangs" do
      _(AttrExtras::Utils.flat_names([ :foo, [ bar: "Bar", baz!: "Baz" ] ])).must_equal [ "foo", "bar", "baz" ]
    end
  end
end
