require 'rails_helper'

RSpec.describe 'Captain API premium feature guard', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, message_type: :outgoing, sender: assistant) }

  describe 'when neither captain feature is enabled' do
    before { account.disable_features!('captain_integration', 'captain_integration_v2') }

    it 'blocks captain preferences' do
      get "/api/v1/accounts/#{account.id}/captain/preferences", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks captain tasks' do
      post "/api/v1/accounts/#{account.id}/captain/tasks/summarize",
           params: { conversation_display_id: conversation.display_id },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks captain agent sessions' do
      get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{message.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks captain message reports' do
      post "/api/v1/accounts/#{account.id}/captain/message_reports",
           params: { message_id: message.id, report_reason: 'incorrect_information' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks captain faq suggestions' do
      get "/api/v1/accounts/#{account.id}/captain/faq_suggestions", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks captain custom tools' do
      account.enable_features!('custom_tools')

      get "/api/v1/accounts/#{account.id}/captain/custom_tools", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'when the captain feature is enabled' do
    before { account.enable_features!('captain_integration') }

    it 'allows captain preferences' do
      get "/api/v1/accounts/#{account.id}/captain/preferences", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end
  end
end
