require 'rails_helper'

RSpec.describe "Api::V2::Accounts::Shopify::Orders", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/api/v2/accounts/shopify/orders/show"
      expect(response).to have_http_status(:success)
    end
  end

end
