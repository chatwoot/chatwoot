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
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/agent_bots'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
      end
    end
  end

  describe 'DELETE /super_admin/agent_bots/:id/destroy_avatar' do
    let!(:agent_bot) { create(:agent_bot, :with_avatar) }

    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        delete "/super_admin/agent_bots/#{agent_bot.id}/avatar", params: { attachment_id: agent_bot.avatar.id }
        expect(response).to have_http_status(:redirect)
        expect(agent_bot.reload.avatar).to be_attached
      end
    end

    context 'when it is an authenticated super admin' do
      it 'destroys the avatar' do
        sign_in(super_admin, scope: :super_admin)
        delete "/super_admin/agent_bots/#{agent_bot.id}/avatar", params: { attachment_id: agent_bot.avatar.id }
        expect(response).to have_http_status(:redirect)
        expect(agent_bot.reload.avatar).not_to be_attached
      end
    end
  end
end
