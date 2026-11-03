require 'rails_helper'

RSpec.describe 'Conversation filter recommendations API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/filter_recommendations" }
  let(:recommendations) { [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'] }] }
  let(:service) { instance_double(Captain::ConversationFilterRecommendationService, perform: recommendations) }

  before do
    allow(Captain::ConversationFilterRecommendationService).to receive(:new).and_return(service)
  end

  it 'returns unauthorized for an unauthenticated user' do
    post url, params: { query: 'open chats' }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  context 'when the account is on a paid Cloud plan' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'Hacker' }, { 'name' => 'Startups' }])
      account.update!(custom_attributes: { 'plan_name' => 'Startups' })
    end

    it 'returns the recommended conditions' do
      post url, params: { query: '  open chats  ' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to eq([{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }])
      expect(Captain::ConversationFilterRecommendationService).to have_received(:new).with(account: account, user: agent, query: 'open chats')
    end

    it 'rejects a query that is too short' do
      post url, params: { query: 'ab' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Captain::ConversationFilterRecommendationService).not_to have_received(:new)
    end
  end

  it 'rejects a Cloud account on the free plan' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'Hacker' }])
    account.update!(custom_attributes: { 'plan_name' => 'Hacker' })

    post url, params: { query: 'open chats' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows a self-hosted install on a paid plan' do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')

    post url, params: { query: 'open chats' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'rejects a self-hosted install on the community plan' do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('community')

    post url, params: { query: 'open chats' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
