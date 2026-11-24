require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  subject(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id, user: agent) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:system_prompts) { [] }
  let(:answer) { { 'reply_needed' => true, 'reply' => 'Here is how.', 'note_for_agent' => '' } }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    allow(ChatwootApp).to receive_messages(chatwoot_cloud?: true, advanced_search_allowed?: true)
    account.enable_features!('captain_tasks', 'advanced_search', 'advanced_search_indexing')
    create(:message, conversation: conversation, message_type: :incoming, content: 'How do I export contacts?')

    response = instance_double(RubyLLM::Message, content: answer.to_json, parsed: answer, tokens: RubyLLM::Tokens.new(input: 50, output: 20))
    allow(Llm::Config).to receive(:with_api_key).and_yield(instance_double(RubyLLM::Context, chat: mock_chat))
    allow(mock_chat).to receive_messages(with_tools: mock_chat, after_message: mock_chat, with_thinking: mock_chat, with_schema: mock_chat,
                                         ask: response)
    allow(mock_chat).to receive(:with_instructions) { |prompt| system_prompts << prompt }
  end

  context 'with the agent-draft flag on' do
    before { account.enable_features!(described_class::AGENT_REPLY_FEATURE) }

    it 'offers the past reply search and tells the model how to use past replies' do
      service.perform

      expect(mock_chat).to have_received(:with_tools).with(an_instance_of(Captain::Tools::SearchPastRepliesService))
      expect(system_prompts.first).to include('search_past_replies')
      expect(system_prompts.first).to include('never copy names, contact details')
    end

    it 'drafts without the past reply search on Cloud when messages are not indexed' do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
      allow(Rails.logger).to receive(:info).and_call_original

      service.perform

      expect(mock_chat).not_to have_received(:with_tools)
      expect(system_prompts.first).not_to include('search_past_replies')
      expect(Rails.logger).to have_received(:info).with(/past reply search not offered, messages are not indexed for this account/)
    end

    it 'searches past replies in the database on a self-hosted installation without OpenSearch' do
      allow(ChatwootApp).to receive_messages(chatwoot_cloud?: false, self_hosted_paid?: true, advanced_search_allowed?: false)
      tool = instance_double(Captain::Tools::SearchPastRepliesService)
      allow(Captain::Tools::SearchPastRepliesService).to receive(:new)
        .with(account: account, user: agent, conversation: conversation, source: :database).and_return(tool)

      service.perform

      expect(mock_chat).to have_received(:with_tools).with(tool)
      expect(system_prompts.first).to include('search_past_replies')
    end

    it 'drafts without the past reply search when the account does not index messages' do
      account.disable_features!('advanced_search_indexing')

      service.perform

      expect(mock_chat).not_to have_received(:with_tools)
    end
  end

  context 'with the agent-draft flag on and canned responses' do
    let(:long_answer) { "Open Contacts and click Export. #{'Then follow the remaining steps in the export screen. ' * 3}Final detail." }

    before do
      account.enable_features!(described_class::AGENT_REPLY_FEATURE)
      create(:canned_response, account: account, short_code: 'export-contacts', content: long_answer)
    end

    it 'lists canned responses by name and lets the model read them with a tool instead of pasting them' do
      service.perform

      expect(mock_chat).to have_received(:with_tools).with(an_instance_of(Captain::Tools::GetCannedResponsesService))
      expect(system_prompts.first).to include('get_canned_responses')
      expect(system_prompts.first).to include('- export-contacts: Open Contacts and click Export.')
      expect(system_prompts.first).not_to include('Final detail.')
    end
  end

  context 'with the agent-draft flag off' do
    it 'never offers the past reply search' do
      service.perform

      expect(mock_chat).not_to have_received(:with_tools)
      expect(system_prompts.first).not_to include('search_past_replies')
    end
  end
end
