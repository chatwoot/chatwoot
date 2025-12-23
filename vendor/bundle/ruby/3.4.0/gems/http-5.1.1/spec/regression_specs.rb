# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Regression testing" do
  describe "#248" do
    it "does not fail with github" do
      github_uri = "http://github.com/"
      expect { HTTP.get(github_uri).to_s }.not_to raise_error
    end

    it "does not fail with googleapis" do
      google_uri = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
      expect { HTTP.get(google_uri).to_s }.not_to raise_error
    end
  end

  describe "#422" do
    it "reads body when 200 OK response contains Upgrade header" do
      res = HTTP.get("https://httpbin.org/response-headers?Upgrade=h2,h2c")
      expect(res.parse(:json)).to include("Upgrade" => "h2,h2c")
    end
  end
end
