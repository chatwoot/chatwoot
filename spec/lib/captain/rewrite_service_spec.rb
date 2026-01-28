require 'rails_helper'

RSpec.describe Captain::RewriteService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:content) { 'I need help with my order' }
  let(:operation) { 'fix_spelling_grammar' }
  let(:service) { described_class.new(account: account, content: content, operation: operation, conversation_display_id: conversation.display_id) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'Rewritten text', input_tokens: 10, output_tokens: 5) }

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

  describe '#perform with fix_spelling_grammar operation' do
    let(:operation) { 'fix_spelling_grammar' }

    it 'uses fix_spelling_grammar prompt' do
      expect(service).to receive(:prompt_from_file).with('fix_spelling_grammar').and_return('Fix errors')

      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages][0][:content]).to eq('Fix errors')
        expect(args[:messages][1][:content]).to eq(content)
        { message: 'Fixed' }
      end

      service.perform
    end
  end

  describe 'tone rewrite methods' do
    let(:tone_prompt_template) { 'Rewrite in {{ tone }} tone' }

    before do
      allow(service).to receive(:prompt_from_file).with('tone_rewrite').and_return(tone_prompt_template)
    end

    describe '#perform with casual operation' do
      let(:operation) { 'casual' }

      it 'uses casual tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in casual tone')
          { message: 'Hey, need help?' }
        end

        service.perform
      end
    end

    describe '#perform with professional operation' do
      let(:operation) { 'professional' }

      it 'uses professional tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in professional tone')
          { message: 'Professional text' }
        end

        service.perform
      end
    end

    describe '#perform with friendly operation' do
      let(:operation) { 'friendly' }

      it 'uses friendly tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in friendly tone')
          { message: 'Friendly text' }
        end

        service.perform
      end
    end

    describe '#perform with confident operation' do
      let(:operation) { 'confident' }

      it 'uses confident tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in confident tone')
          { message: 'Confident text' }
        end

        service.perform
      end
    end

    describe '#perform with straightforward operation' do
      let(:operation) { 'straightforward' }

      it 'uses straightforward tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in straightforward tone')
          { message: 'Straightforward text' }
        end

        service.perform
      end
    end
  end

  describe '#perform with improve operation' do
    let(:operation) { 'improve' }
    let(:improve_template) { 'Context: {{ conversation_context }}\nDraft: {{ draft_message }}' }

    before do
      create(:message, conversation: conversation, message_type: :incoming, content: 'Customer message')
      allow(service).to receive(:prompt_from_file).with('improve').and_return(improve_template)
    end

    it 'uses conversation context and draft message with Liquid template' do
      expect(service).to receive(:make_api_call) do |args|
        system_content = args[:messages][0][:content]

        expect(system_content).to include('Context:')
        expect(system_content).to include('Draft: I need help with my order')
        expect(args[:messages][1][:content]).to eq(content)
        { message: 'Improved text' }
      end

      service.perform
    end

    it 'returns formatted response' do
      result = service.perform

      expect(result[:message]).to eq('Rewritten text')
    end
  end

  describe '#perform with invalid operation' do
    it 'raises ArgumentError for unknown operation' do
      invalid_service = described_class.new(
        account: account,
        content: content,
        operation: 'invalid_operation',
        conversation_display_id: conversation.display_id
      )

      expect { invalid_service.perform }.to raise_error(ArgumentError, /Invalid operation/)
    end

    it 'prevents method injection attacks' do
      dangerous_service = described_class.new(
        account: account,
        content: content,
        operation: 'perform',
        conversation_display_id: conversation.display_id
      )

      expect { dangerous_service.perform }.to raise_error(ArgumentError, /Invalid operation/)
    end
  end
end
