require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:captain_inbox_association) { create(:captain_inbox, captain_assistant: assistant, inbox: inbox) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:mock_llm_chat_service) { instance_double(Captain::Llm::AssistantChatService) }
    let(:mock_language_detection_service) { instance_double(Captain::Llm::LanguageDetectionService) }

    before do
      create(:message, conversation: conversation, content: 'Hello', message_type: :incoming)

      allow(inbox).to receive(:captain_active?).and_return(true)
      allow(Captain::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Captain Specs' })

      allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(mock_language_detection_service)
      allow(mock_language_detection_service).to receive(:detect).with('Hello').and_return('en')
    end

    it 'generates and processes response' do
      described_class.perform_now(conversation, assistant)
      expect(conversation.messages.count).to eq(2)
      expect(conversation.messages.outgoing.count).to eq(1)
      expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
    end

    it 'increments usage response' do
      described_class.perform_now(conversation, assistant)
      account.reload
      expect(account.usage_limits[:captain][:responses][:consumed]).to eq(1)
    end

    context 'when language is already detected' do
      let(:conversation) { create(:conversation, inbox: inbox, account: account, additional_attributes: { 'conversation_language' => 'fr' }) }

      it 'does not detect language again' do
        expect(mock_language_detection_service).not_to receive(:detect)
        described_class.perform_now(conversation, assistant)

        conversation.reload
        expect(conversation.additional_attributes['conversation_language']).to eq('fr')
      end
    end

    context 'when language detection fails' do
      before do
        allow(mock_language_detection_service).to receive(:detect).and_return(nil)
      end

      it 'continues with response generation' do
        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
        expect(conversation.additional_attributes['language']).to be_nil
      end
    end
  end
end
