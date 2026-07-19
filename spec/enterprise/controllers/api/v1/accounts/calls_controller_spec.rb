require 'rails_helper'

RSpec.describe 'Calls API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let!(:agent_call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: contact,
                  accepted_by_agent: agent, status: 'completed', transcript: 'hello world')
  end
  let!(:other_call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: contact, accepted_by_agent: admin)
  end

  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe 'GET /api/v1/accounts/:account_id/calls' do
    it 'returns 401 when unauthenticated' do
      get "/api/v1/accounts/#{account.id}/calls"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the whole account with sensitive fields for an administrator' do
      get "/api/v1/accounts/#{account.id}/calls", headers: admin.create_new_auth_token

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['payload'].map { |c| c['id'] }).to contain_exactly(agent_call.id, other_call.id)
      item = body['payload'].find { |c| c['id'] == agent_call.id }
      expect(item['transcript']).to eq('hello world')
      expect(item['contact']['phone_number']).to eq(contact.phone_number)
    end

    it 'scopes the list to calls the agent accepted' do
      get "/api/v1/accounts/#{account.id}/calls", headers: agent.create_new_auth_token

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['meta']['count']).to eq(1)
      expect(body['payload'].map { |c| c['id'] }).to contain_exactly(agent_call.id)
    end
  end
end
