require 'rails_helper'

RSpec.describe Aiagent::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:topic) { create(:aiagent_topic, account: account) }
  let(:aiagent_inbox_association) { create(:aiagent_inbox, aiagent_topic: topic, inbox: inbox) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:mock_llm_chat_service) { instance_double(Aiagent::Llm::TopicChatService) }

    before do
      create(:message, conversation: conversation, content: 'Hello', message_type: :incoming)

      allow(inbox).to receive(:aiagent_active?).and_return(true)
      allow(Aiagent::Llm::TopicChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Aiagent Specs' })
    end

    it 'generates and processes response' do
      described_class.perform_now(conversation, topic)
      expect(conversation.messages.count).to eq(2)
      expect(conversation.messages.outgoing.count).to eq(1)
      expect(conversation.messages.last.content).to eq('Hey, welcome to Aiagent Specs')
    end

    it 'increments usage response' do
      described_class.perform_now(conversation, topic)
      account.reload
      expect(account.usage_limits[:aiagent][:responses][:consumed]).to eq(1)
    end
  end
end
