require 'rails_helper'

RSpec.describe 'Super Admin agent-bots API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/agent_bots' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/agent_bots'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:agent_bot) { create(:agent_bot) }

      it 'shows the list of users' do
        sign_in super_admin
        get '/super_admin/agent_bots'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
      end
    end
  end
end
