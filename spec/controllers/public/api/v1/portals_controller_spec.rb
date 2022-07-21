require 'rails_helper'

RSpec.describe 'Public Portals API', type: :request do
  let!(:account) { create(:account) }
  let!(:portal) { create(:portal, slug: 'test-portal', account_id: account.id) }

  before do
    create(:portal, slug: 'test-portal-1', account_id: account.id)
    create(:portal, slug: 'test-portal-2', account_id: account.id)
  end

  describe 'GET /public/api/v1/portals/{portal_slug}' do
    it 'Show portal and categories belonging to the portal' do
      get "/public/api/v1/portals/#{portal.slug}"

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['slug']).to eql 'test-portal'
    end
  end
end
