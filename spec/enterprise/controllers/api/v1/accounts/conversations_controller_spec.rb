require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id' do
    it 'returns SLA data for the conversation if the feature is enabled' do
      account.enable_features!('sla')
      conversation = create(:conversation, account: account)
      applied_sla = create(:applied_sla, conversation: conversation)
      sla_event = create(:sla_event, conversation: conversation, applied_sla: applied_sla)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['applied_sla']['id']).to eq(applied_sla.id)
      expect(response.parsed_body['sla_events'].first['id']).to eq(sla_event.id)
    end

    it 'does not return SLA data for the conversation if the feature is disabled' do
      account.disable_features!('sla')
      conversation = create(:conversation, account: account)
      create(:applied_sla, conversation: conversation)
      create(:sla_event, conversation: conversation)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.keys).not_to include('applied_sla')
      expect(response.parsed_body.keys).not_to include('sla_events')
    end
  end
end
