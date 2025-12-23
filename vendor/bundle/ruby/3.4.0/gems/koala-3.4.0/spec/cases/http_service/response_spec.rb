require "spec_helper"

module Koala::HTTPService
  RSpec.describe Response do
    describe "#data" do
      it "returns nothing if the body is empty" do
        expect(Response.new(200, "", {}).data).to be_nil
      end

      it "parses the JSON if there's a body" do
        result = {"foo" => "bar"}
        expect(Response.new(200, result.to_json, {}).data).to eq(result)
      end

      it "allows raw values" do
        expect(Response.new(200, "true", {}).data).to be true
      end

      it "raises a ParserError if it's invalid JSON" do
        expect { Response.new(200, "{", {}).data }.to raise_exception(JSON::ParserError)
      end
    end
  end
end
