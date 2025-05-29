require 'rails_helper'

RSpec.describe Aiagent::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:aiagent_assistant, account: account) }
  let(:aiagent_inbox_association) { create(:aiagent_inbox, aiagent_assistant: assistant, inbox: inbox) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:mock_llm_chat_service) { instance_double(Aiagent::Llm::AssistantChatService) }

    before do
      create(:message, conversation: conversation, content: 'Hello', message_type: :incoming)

      allow(inbox).to receive(:aiagent_active?).and_return(true)
      allow(Aiagent::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Aiagent Specs' })
    end

    it 'generates and processes response' do
      described_class.perform_now(conversation, assistant)
      expect(conversation.messages.count).to eq(2)
      expect(conversation.messages.outgoing.count).to eq(1)
      expect(conversation.messages.last.content).to eq('Hey, welcome to Aiagent Specs')
    end

    it 'increments usage response' do
      described_class.perform_now(conversation, assistant)
      account.reload
      expect(account.usage_limits[:aiagent][:responses][:consumed]).to eq(1)
    end
  end
end
