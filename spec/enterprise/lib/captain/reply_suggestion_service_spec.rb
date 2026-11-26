require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  describe '#use_search_tool?' do
    subject(:use_search_tool?) { described_class.allocate.send(:use_search_tool?) }

    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)
      allow(ChatwootHub).to receive(:pricing_plan).and_return('premium')
    end

    it { is_expected.to be(true) }
  end

  describe '#perform' do
    subject(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id, user: agent) }

    let(:account) { create(:account) }
    let(:agent) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:system_prompts) { [] }

    before do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      account.enable_features!('captain_tasks')
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      create(:message, conversation: conversation, message_type: :incoming, content: 'How do I reset my password?')

      mock_response = instance_double(RubyLLM::Message, content: 'Here is how.', tokens: RubyLLM::Tokens.new(input: 50, output: 20))
      allow(Llm::Config).to receive(:with_api_key).and_yield(instance_double(RubyLLM::Context, chat: mock_chat))
      allow(mock_chat).to receive(:with_tools).and_return(mock_chat)
      allow(mock_chat).to receive(:after_message).and_return(mock_chat)
      allow(mock_chat).to receive(:with_instructions) { |prompt| system_prompts << prompt }
      allow(mock_chat).to receive(:with_thinking).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(mock_response)
    end

    context 'when the inbox assistant has no FAQs' do
      it 'drafts without the knowledge base search' do
        service.perform

        expect(mock_chat).not_to have_received(:with_tools)
        expect(system_prompts.first).not_to include('search_documentation')
      end
    end

    context 'when the inbox assistant has FAQs' do
      before { create(:captain_assistant_response, assistant: assistant) }

      it 'offers the knowledge base search' do
        service.perform

        expect(mock_chat).to have_received(:with_tools).with(an_instance_of(Captain::Tools::SearchReplyDocumentationService))
        expect(system_prompts.first).to include('search_documentation')
      end
    end

    context 'when the inbox has no assistant and the account has FAQs' do
      let(:other_inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: other_inbox) }

      before { create(:captain_assistant_response, assistant: assistant) }

      it 'offers the knowledge base search over the account FAQs' do
        service.perform

        expect(mock_chat).to have_received(:with_tools).with(an_instance_of(Captain::Tools::SearchReplyDocumentationService))
      end
    end
  end
end
