require "spec_helper"

describe AttrExtras::AttrInitialize::ParamsBuilder do
  subject { AttrExtras::AttrInitialize::ParamsBuilder.new(names) }

  describe "when positional and hash params are present" do
    let(:names) { [ :foo, :bar, [ :baz, :qux!, quux: "Quux" ] ] }

    it "properly devides params by the type" do
      _(subject.positional_args).must_equal [ :foo, :bar ]
      _(subject.hash_args).must_equal [ :baz, :qux!, :quux ]
      _(subject.hash_args_names).must_equal [ :baz, :qux, :quux ]
      _(subject.hash_args_required).must_equal [ :qux ]
      _(subject.default_values).must_equal({ quux: "Quux" })
    end
  end

  describe "when only positional params are present" do
    let(:names) { [ :foo, :bar ] }

    it "properly devides params by the type" do
      _(subject.positional_args).must_equal [ :foo, :bar ]
      _(subject.hash_args).must_be_empty
      _(subject.hash_args_names).must_be_empty
      _(subject.hash_args_required).must_be_empty
      _(subject.default_values).must_be_empty
    end
  end

  describe "when only hash params are present" do
    let(:names) { [ [ { baz: "Baz" }, :qux!, { quux: "Quux" } ] ] }

    it "properly devides params by the type" do
      _(subject.positional_args).must_be_empty
      _(subject.hash_args).must_equal [ :baz, :qux!, :quux ]
      _(subject.hash_args_names).must_equal [ :baz, :qux, :quux ]
      _(subject.hash_args_required).must_equal [ :qux ]
      _(subject.default_values).must_equal({ quux: "Quux", baz: "Baz" })
    end
  end

  describe "when params are empty" do
    let(:names) { [] }

    it "properly devides params by the type" do
      _(subject.positional_args).must_be_empty
      _(subject.hash_args).must_be_empty
      _(subject.hash_args_names).must_be_empty
      _(subject.hash_args_required).must_be_empty
      _(subject.default_values).must_be_empty
    end
  end
end
