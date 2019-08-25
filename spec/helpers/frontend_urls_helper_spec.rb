require "rails_helper"

describe FrontendUrlsHelper do
  describe "#frontend_url" do
    context "without query params" do
      it "creates path correctly" do
        describe(helper.frontend_url('dashboard')).to eq "/app/dashboard"
      end
    end
  end
end
