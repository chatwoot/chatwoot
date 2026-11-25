require 'rails_helper'

RSpec.describe 'Internal chat access', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:private_channel) { create(:internal_chat_channel, :private_channel, account: account) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/internal_chat" }

  before do
    create(:internal_chat_channel_member, :admin, channel: private_channel, user: agent)
  end

  context 'when agents lack internal_chat.access' do
    before { stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } }) }

    it 'refuses every internal chat endpoint, including a private channel the agent administers' do
      headers = agent.create_new_auth_token
      requests = [
        -> { get "#{base_path}/channels", headers: headers, as: :json },
        -> { get "#{base_path}/channels/#{private_channel.id}", headers: headers, as: :json },
        -> { get "#{base_path}/drafts", headers: headers, as: :json },
        -> { get "#{base_path}/search", params: { q: 'hello' }, headers: headers },
        -> { post "#{base_path}/channels/#{private_channel.id}/messages", params: { content: 'hi' }, headers: headers, as: :json }
      ]

      requests.each do |request|
        request.call
        expect(response).to have_http_status(:unauthorized), "#{request.source_location} answered #{response.status}"
      end
      expect(InternalChat::Message.count).to eq(0)
    end

    it 'still serves administrators' do
      get "#{base_path}/channels/#{private_channel.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'reports the capability as not granted in the profile payload' do
      get '/api/v1/profile', headers: agent.create_new_auth_token, as: :json

      account_payload = response.parsed_body['accounts'].find { |entry| entry['id'] == account.id }
      expect(account_payload['feature_access']).not_to include('internal_chat.access')
      expect(account_payload['permissions']).to eq(['agent'])
    end
  end

  it 'grants the capability by default' do
    get '/api/v1/profile', headers: agent.create_new_auth_token, as: :json

    account_payload = response.parsed_body['accounts'].find { |entry| entry['id'] == account.id }
    expect(account_payload['feature_access']).to include('internal_chat.access')
  end

  it 'routes every internal chat endpoint through the controller that checks access' do
    controllers = Rails.application.routes.routes.filter_map do |route|
      route.defaults[:controller] if route.path.spec.to_s.include?('/internal_chat/')
    end.uniq

    expect(controllers).not_to be_empty
    controllers.each do |controller|
      expect("#{controller.camelize}Controller".constantize).to be < Api::V1::Accounts::InternalChat::BaseController
    end
  end
end
