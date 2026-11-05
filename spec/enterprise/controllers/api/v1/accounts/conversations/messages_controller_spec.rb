require 'rails_helper'

RSpec.describe 'Auto translate messages API', type: :request do
  let(:account) { create(:account, settings: { auto_translate: true }) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                     content: 'Celui-ci met quatre secondes à charger.')
  end
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/auto_translate" }
  let(:llm_response) { { message: 'This one takes four seconds to load.' } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }

  before do
    account.enable_features!(:auto_translate, :captain_tasks)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(instance_double(Captain::Llm::LanguageDetectionService, language: 'fr'))
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
  end

  it 'returns unauthorized without a login' do
    post url, params: { message_ids: [message.id] }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'queues the given messages for translation into the agent dashboard language' do
    agent.update!(ui_settings: { locale: 'pt_BR' })

    expect do
      post url, params: { message_ids: [message.id] }, headers: agent.create_new_auth_token, as: :json
    end.to have_enqueued_job(Captain::Conversation::ContactMessageTranslationJob).with(message, 'pt_BR')
  end

  it 'falls back to the account language for an agent without a dashboard language' do
    expect do
      post url, params: { message_ids: [message.id] }, headers: agent.create_new_auth_token, as: :json
    end.to have_enqueued_job(Captain::Conversation::ContactMessageTranslationJob).with(message, 'en')

    expect(response).to have_http_status(:accepted)
  end

  it 'refuses when auto translate is not enabled for the account' do
    account.disable_features(:auto_translate)
    account.save!

    post url, params: { message_ids: [message.id] }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'rejects message ids from another conversation' do
    other = create(:conversation, account: account, inbox: inbox)
    elsewhere = create(:message, account: account, inbox: inbox, conversation: other, message_type: :incoming, content: 'Salut')

    expect do
      post url, params: { message_ids: [message.id, elsewhere.id] }, headers: agent.create_new_auth_token, as: :json
    end.not_to have_enqueued_job(Captain::Conversation::ContactMessageTranslationJob)

    expect(response).to have_http_status(422)
    expect(response.parsed_body['error']).to eq('Invalid messages')
  end

  it 'rejects message ids that are not a list' do
    post url, params: { message_ids: message.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(422)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end
end
