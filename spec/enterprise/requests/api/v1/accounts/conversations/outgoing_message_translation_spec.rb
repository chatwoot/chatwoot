require 'rails_helper'

RSpec.describe 'Outgoing message translation API', type: :request do
  let(:account) { create(:account, settings: { auto_translate: true }) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { conversation_language: 'fr' }) }
  let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages" }
  let(:translator) { instance_double(Captain::Conversation::TranslatorService, language: 'en', translate: 'Réponse approuvée', provider: 'captain') }
  let(:delivery_service) { instance_double(Messages::SendEmailNotificationService, perform: nil) }

  before do
    account.enable_features!(:auto_translate, :captain_tasks)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Captain::Conversation::TranslatorService).to receive(:new).and_return(translator)
    allow(Messages::SendEmailNotificationService).to receive(:new).and_return(delivery_service)
  end

  it 'delivers an opted-out API reply as written without invoking the translator' do
    post url, params: { content: 'Approved reply', content_attributes: { skip_translation: true } },
              headers: { api_access_token: agent.access_token.token }, as: :json

    expect(response).to have_http_status(:success)
    reply = conversation.messages.find(response.parsed_body['id'])
    expect(reply.content_attributes).to eq('skip_translation' => true)
    expect(Messages::SendEmailNotificationService).to receive(:new) do |message:|
      expect(message.content).to eq('Approved reply')
      delivery_service
    end

    SendReplyJob.perform_now(reply.id)

    expect(Captain::Conversation::TranslatorService).not_to have_received(:new)
    expect(delivery_service).to have_received(:perform)
    expect(reply.reload.content).to eq('Approved reply')
  end

  [nil, false].each do |skip_translation|
    it "translates an API reply when skip_translation is #{skip_translation.inspect}" do
      attributes = skip_translation.nil? ? {} : { skip_translation: skip_translation }
      post url, params: { content: 'Approved reply', content_attributes: attributes },
                headers: { api_access_token: agent.access_token.token }, as: :json

      expect(response).to have_http_status(:success)
      reply = conversation.messages.find(response.parsed_body['id'])
      expect(reply.content_attributes['translation_pending']).to be true
      expect(Messages::SendEmailNotificationService).to receive(:new) do |message:|
        expect(message.content).to eq('Réponse approuvée')
        delivery_service
      end

      SendReplyJob.perform_now(reply.id)

      expect(translator).to have_received(:translate).with('Approved reply', 'fr')
      expect(delivery_service).to have_received(:perform)
      expect(reply.reload.content).to eq('Réponse approuvée')
    end
  end
end
