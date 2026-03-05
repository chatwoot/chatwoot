require 'rails_helper'

describe Integrations::GoogleTranslate::AutoTranslateMessageService do
  describe '#perform' do
    let(:account) { create(:account, locale: 'en') }
    let(:conversation) do
      create(:conversation, account: account, additional_attributes: { conversation_language: 'es' })
    end
    let(:hook) { create(:integrations_hook, :google_translate, account: account, settings: hook_settings) }
    let(:translated_text) { 'Hello there' }

    before do
      allow(Integrations::GoogleTranslate::ProcessorService).to receive(:new).and_return(
        instance_double(
          Integrations::GoogleTranslate::ProcessorService,
          perform: translated_text
        )
      )
    end

    context 'when message is incoming' do
      let(:message) { create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'Hola') }

      context 'when incoming auto translation is enabled' do
        let(:hook_settings) do
          {
            project_id: 'test',
            credentials: {},
            auto_translate_incoming: true,
            auto_translate_outgoing: false
          }
        end

        it 'stores translated content in message translations' do
          described_class.new(hook: hook, message: message).perform

          expect(Integrations::GoogleTranslate::ProcessorService).to have_received(:new).with(
            message: message,
            target_language: 'en',
            integration_hook: hook
          )
          expect(message.reload.translations).to include('en' => translated_text)
        end
      end

      context 'when incoming auto translation is disabled' do
        let(:hook_settings) do
          {
            project_id: 'test',
            credentials: {},
            auto_translate_incoming: false,
            auto_translate_outgoing: false
          }
        end

        it 'does not translate the message' do
          described_class.new(hook: hook, message: message).perform

          expect(Integrations::GoogleTranslate::ProcessorService).not_to have_received(:new)
          expect(message.reload.translations).to be_nil
        end
      end
    end

    context 'when message is outgoing' do
      let(:message) { create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'Hello') }

      context 'when outgoing auto translation is enabled' do
        let(:hook_settings) do
          {
            project_id: 'test',
            credentials: {},
            auto_translate_incoming: true,
            auto_translate_outgoing: true
          }
        end

        it 'stores translated content in conversation language' do
          described_class.new(hook: hook, message: message).perform

          expect(Integrations::GoogleTranslate::ProcessorService).to have_received(:new).with(
            message: message,
            target_language: 'es',
            integration_hook: hook
          )
          expect(message.reload.translations).to include('es' => translated_text)
        end
      end

      context 'when outgoing auto translation is disabled' do
        let(:hook_settings) do
          {
            project_id: 'test',
            credentials: {},
            auto_translate_incoming: true,
            auto_translate_outgoing: false
          }
        end

        it 'does not translate the message' do
          described_class.new(hook: hook, message: message).perform

          expect(Integrations::GoogleTranslate::ProcessorService).not_to have_received(:new)
          expect(message.reload.translations).to be_nil
        end
      end

      context 'when translation already exists' do
        let(:hook_settings) do
          {
            project_id: 'test',
            credentials: {},
            auto_translate_incoming: true,
            auto_translate_outgoing: true
          }
        end

        before do
          message.update!(translations: { 'es' => 'Existing translation' })
        end

        it 'does not call translator again' do
          described_class.new(hook: hook, message: message).perform

          expect(Integrations::GoogleTranslate::ProcessorService).not_to have_received(:new)
          expect(message.reload.translations['es']).to eq('Existing translation')
        end
      end
    end
  end
end
