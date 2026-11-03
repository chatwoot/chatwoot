require 'rails_helper'

RSpec.describe 'Conversation filter recommendations API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:url) { "/api/v1/accounts/#{account.id}/filter_recommendations" }
  let(:recommendations) { [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'] }] }
  let(:service) { instance_double(Captain::FilterRecommendationService, perform: recommendations) }

  before do
    allow(Captain::FilterRecommendationService).to receive(:new).and_return(service)
  end

  it 'returns unauthorized for an unauthenticated user' do
    post url, params: { query: 'open chats', filter_type: 'conversation' }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  context 'when the account is on a paid Cloud plan' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'Hacker' }, { 'name' => 'Startups' }])
      account.update!(custom_attributes: { 'plan_name' => 'Startups' })
    end

    it 'returns the recommended conditions' do
      post url, params: { query: '  open chats  ', filter_type: 'conversation' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to eq([{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }])
      expect(Captain::FilterRecommendationService).to have_received(:new)
        .with(account: account, field_set: an_instance_of(Captain::ConversationFilterFields), query: 'open chats')
    end

    it 'builds contact recommendations from the contact fields' do
      post url, params: { query: 'blocked contacts', filter_type: 'contact' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Captain::FilterRecommendationService).to have_received(:new)
        .with(account: account, field_set: an_instance_of(Captain::ContactFilterFields), query: 'blocked contacts')
    end

    it 'builds automation recommendations from the condition keys the event offers' do
      post url, params: { query: 'refund messages', filter_type: 'automation', attribute_keys: %w[content message_type] },
                headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Captain::FilterRecommendationService).to have_received(:new)
        .with(account: account, field_set: an_instance_of(Captain::AutomationFilterFields), query: 'refund messages')
    end

    it 'picks an event for a rule without one and recommends conditions from its keys' do
      event_recommendation = instance_double(Captain::AutomationEventRecommendation, perform: 'message_created')
      allow(Captain::AutomationEventRecommendation).to receive(:new).and_return(event_recommendation)
      allow(Captain::AutomationFilterFields).to receive(:new).and_call_original

      post url, params: { query: 'Tag refund requests', filter_type: 'automation',
                          events: { conversation_created: %w[status], message_created: %w[content message_type] } },
                headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['event_name']).to eq('message_created')
      expect(Captain::AutomationEventRecommendation).to have_received(:new)
        .with(account: account, query: 'Tag refund requests', events: %w[conversation_created message_created])
      expect(Captain::AutomationFilterFields).to have_received(:new).with(account: account, user: agent, attribute_keys: %w[content message_type])
    end

    it 'returns no conditions when no event is picked' do
      allow(Captain::AutomationEventRecommendation).to receive(:new).and_return(instance_double(Captain::AutomationEventRecommendation, perform: nil))

      post url, params: { query: 'Do something', filter_type: 'automation', events: { message_created: %w[content] } },
                headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body).to eq('payload' => nil, 'event_name' => nil, 'actions' => nil)
      expect(Captain::FilterRecommendationService).not_to have_received(:new)
    end

    it 'recommends actions from the ones the form offers' do
      allow(Captain::AutomationActionFields).to receive(:new).and_call_original

      post url, params: { query: 'Add bug label', filter_type: 'automation', attribute_keys: %w[content], action_names: %w[add_label] },
                headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Captain::AutomationActionFields).to have_received(:new).with(account: account, user: agent, action_names: %w[add_label])
      expect(Captain::FilterRecommendationService).to have_received(:new)
        .with(account: account, field_set: an_instance_of(Captain::AutomationActionFields), query: 'Add bug label')
    end

    it 'rejects events that do not map to condition keys' do
      post url, params: { query: 'Tag refund requests', filter_type: 'automation', events: { message_created: 'content' } },
                headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects an automation request without condition keys' do
      post url, params: { query: 'refund messages', filter_type: 'automation' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects an unknown filter type' do
      post url, params: { query: 'open chats', filter_type: 'report' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects a query that is too short' do
      post url, params: { query: 'ab', filter_type: 'conversation' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Captain::FilterRecommendationService).not_to have_received(:new)
    end
  end

  it 'rejects a Cloud account on the free plan' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'Hacker' }])
    account.update!(custom_attributes: { 'plan_name' => 'Hacker' })

    post url, params: { query: 'open chats', filter_type: 'conversation' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows a self-hosted install on a paid plan' do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')

    post url, params: { query: 'open chats', filter_type: 'conversation' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'rejects a self-hosted install on the community plan' do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('community')

    post url, params: { query: 'open chats', filter_type: 'conversation' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
