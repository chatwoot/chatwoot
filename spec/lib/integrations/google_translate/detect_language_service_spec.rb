require 'rails_helper'
require 'google/cloud/translate/v3'

describe Integrations::GoogleTranslate::DetectLanguageService do
  let(:account) { create(:account) }
  let(:message) { create(:message, account: account, content: 'muchas muchas gracias') }
  let(:hook) { create(:integrations_hook, :google_translate, account: account) }
  let(:translate_client) { double }

  before do
    allow(Integrations::GoogleTranslate::CredentialsValidator).to receive(:valid?).and_return(true)
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

    # `client.detect_language` is a network call, and the conversation object was read before it.
    # Whatever another writer stored in the column during the call is in the row and not in that
    # copy, so writing the copy back erases it.
    it 'does not erase what another writer stored during the detection' do
      conversation = message.conversation
      allow(translate_client).to receive(:detect_language) do
        Conversation.find(conversation.id).update!(additional_attributes: { 'browser_language' => 'pt' })
        Google::Cloud::Translate::V3::DetectLanguageResponse.new({ languages: [{ language_code: 'es', confidence: 0.71875 }] })
      end

      described_class.new(hook: hook, message: message).perform

      expect(conversation.reload.additional_attributes)
        .to include('browser_language' => 'pt', 'conversation_language' => 'es')
    end

    # The service merges a symbol key into a column whose keys are strings. The JSON column
    # stringifies on the way in, so both spellings would arrive as the same key and the last one
    # would win silently; the guard against that is the key being written as a String from here.
    it 'writes the language under one key, not two' do
      described_class.new(hook: hook, message: message).perform

      stored = ActiveRecord::Base.connection.select_value(
        "SELECT additional_attributes::text FROM conversations WHERE id = #{message.conversation.id}"
      )

      expect(stored.scan('conversation_language').size).to eq(1)
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
