require "spec_helper"

describe "spec helpers" do
  describe "#preserving_env" do
    after { ENV.delete "FOO" }

    it "should remove added environment vars" do
      old = ENV["FOO"]
      preserving_env { ENV["FOO"] = "baz" }
      expect(ENV["FOO"]).to eq(old)
    end

    it "should reset modified environment vars" do
      ENV["FOO"] = "bar"
      preserving_env { ENV["FOO"] = "baz"}
      expect(ENV["FOO"]).to eq("bar")
    end
  end
end
