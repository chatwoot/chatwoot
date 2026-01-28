require 'rails_helper'

RSpec.describe Captain::SummaryService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'Summary of conversation', input_tokens: 100, output_tokens: 50) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
    # Stub captain enabled check to allow specs to test base functionality
    # without enterprise module interference
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#perform' do
    it 'passes correct model to API' do
      expect(service).to receive(:make_api_call).with(
        hash_including(model: Captain::BaseTaskService::GPT_MODEL)
      ).and_call_original

      service.perform
    end

    it 'passes system prompt and conversation text as messages' do
      allow(service).to receive(:prompt_from_file).with('summary').and_return('Summarize this')

      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages].length).to eq(2)
        expect(args[:messages][0][:role]).to eq('system')
        expect(args[:messages][0][:content]).to eq('Summarize this')
        expect(args[:messages][1][:role]).to eq('user')
        expect(args[:messages][1][:content]).to be_a(String)
        { message: 'Summary' }
      end

      service.perform
    end

    it 'returns formatted response' do
      result = service.perform

      expect(result[:message]).to eq('Summary of conversation')
      expect(result[:usage]['prompt_tokens']).to eq(100)
      expect(result[:usage]['completion_tokens']).to eq(50)
    end
  end
end
