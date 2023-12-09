require 'rails_helper'

RSpec.describe 'Conversation Base API', type: :request do
  let!(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id/messages' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an authenticated user with out access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'will not show the conversation' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation team' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation.update(team: create(:team, account: account))
        create(:team_member, team: conversation.team, user: agent)
      end

      it 'will show the conversation' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:meta][:contact][:id]).to eq(conversation.contact_id)
      end
    end
  end
end
