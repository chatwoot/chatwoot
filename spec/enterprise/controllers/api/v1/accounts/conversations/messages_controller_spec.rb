require 'rails_helper'

RSpec.describe 'Auto translate messages API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                     content: 'Celui-ci met quatre secondes à charger.')
  end
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/auto_translate" }
  let(:llm_response) { { message: [{ 'id' => "#{message.id}:0", 'text' => 'This one takes four seconds to load.' }] } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    account.enable_features!(:auto_translate, :captain_tasks)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
  end

  it 'returns unauthorized without a login' do
    post url, params: { message_ids: [message.id], target_language: 'en' }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'translates the given messages and returns them' do
    post url, params: { message_ids: [message.id], target_language: 'en' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload'].first).to include(
      'id' => message.id,
      'content_attributes' => { 'translations' => { 'en' => 'This one takes four seconds to load.' }, 'source_language' => 'fr' }
    )
    expect(conversation.reload.language).to eq('fr')
  end

  it 'returns the Captain error when translation fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'Captain AI is disabled for this account.')

    post url, params: { message_ids: [message.id], target_language: 'en' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(422)
    expect(response.parsed_body['error']).to eq('Captain AI is disabled for this account.')
  end

  it 'refuses when auto translate is not enabled for the account' do
    account.disable_features(:auto_translate)
    account.save!

    post url, params: { message_ids: [message.id], target_language: 'en' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'rejects a language the dashboard does not support' do
    post url, params: { message_ids: [message.id], target_language: 'xx' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(422)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'rejects message ids that are not a list' do
    post url, params: { message_ids: message.id, target_language: 'en' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(422)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'rejects a request without a target language' do
    post url, params: { message_ids: [message.id] }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(422)
  end
end
