require 'rails_helper'

RSpec.describe 'Company conversations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:company) { create(:company, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, company: company) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

  before do
    account.enable_features!(:companies)
    create(:inbox_member, user: agent, inbox: inbox)
    create(:conversation_participant, conversation: conversation, account: account, user: agent)
    create(:mention, conversation: conversation, account: account, user: agent)
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/{company.id}/conversations' do
    it 'returns the participant and mentioned user ids of each conversation' do
      get "/api/v1/accounts/#{account.id}/companies/#{company.id}/conversations",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].first).to include('participant_ids' => [agent.id], 'mentioned_user_ids' => [agent.id])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/companies/{company.id}/conversations/filter' do
    it 'returns the participant and mentioned user ids of each conversation' do
      post "/api/v1/accounts/#{account.id}/companies/#{company.id}/conversations/filter",
           headers: admin.create_new_auth_token,
           params: { payload: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'] }] },
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].first).to include('participant_ids' => [agent.id], 'mentioned_user_ids' => [agent.id])
    end
  end
end
