require 'rails_helper'

RSpec.describe "Api::V2::Accounts::Shopify::Locations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v2/accounts/shopify/locations/index"
      expect(response).to have_http_status(:success)
    end
  end

end
