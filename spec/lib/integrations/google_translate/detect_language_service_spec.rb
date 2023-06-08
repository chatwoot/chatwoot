require 'rails_helper'
require 'google/cloud/translate/v3'

describe Integrations::GoogleTranslate::DetectLanguageService do
  let(:account) { create(:account) }
  let(:message) { create(:message, account: account, content: 'muchas muchas gracias') }
  let(:hook) { create(:integrations_hook, :google_translate, account: account) }
  let(:translate_client) { double }

  before do
    allow(Google::Cloud::Translate::V3::TranslationService::Client).to receive(:new).and_return(translate_client)
    allow(translate_client).to receive(:detect_language).and_return(Google::Cloud::Translate::V3::DetectLanguageResponse
      .new({ languages: [{ language_code: 'es', confidence: 0.71875 }] }))
  end

  describe '#perform' do
    it 'detects and updates the conversation language' do
      described_class.new(hook: hook, message: message).perform
      expect(translate_client).to have_received(:detect_language)
      expect(message.conversation.reload.additional_attributes['conversation_language']).to eq('es')
    end

    it 'will not update the conversation language if it is already present' do
      message.conversation.update!(additional_attributes: { conversation_language: 'en' })
      described_class.new(hook: hook, message: message).perform
      expect(translate_client).not_to have_received(:detect_language)
      expect(message.conversation.reload.additional_attributes['conversation_language']).to eq('en')
    end

    it 'will not update the conversation language if the message is not incoming' do
      message.update!(message_type: :outgoing)
      described_class.new(hook: hook, message: message).perform
      expect(translate_client).not_to have_received(:detect_language)
      expect(message.conversation.reload.additional_attributes['conversation_language']).to be_nil
    end

    it 'will not execute if the message content is blank' do
      message.update!(content: nil)
      described_class.new(hook: hook, message: message).perform
      expect(translate_client).not_to have_received(:detect_language)
      expect(message.conversation.reload.additional_attributes['conversation_language']).to be_nil
    end
  end
end
