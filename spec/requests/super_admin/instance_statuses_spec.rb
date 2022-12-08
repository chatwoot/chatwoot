require 'rails_helper'

RSpec.describe "SuperAdmin::InstanceStatuses", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/super_admin/instance_status/show"
      expect(response).to have_http_status(:success)
    end
  end

end
