require 'rails_helper'

RSpec.describe 'Super Admin access tokens API', type: :request do
  let(:super_admin) { create(:super_admin) }
  let!(:platform_app) { create(:platform_app) }

  describe 'GET /super_admin/access_tokens' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'shows the list of access tokens' do
        sign_in super_admin
        get '/super_admin/access_tokens'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(platform_app.access_token.token)
      end
    end
  end
end
