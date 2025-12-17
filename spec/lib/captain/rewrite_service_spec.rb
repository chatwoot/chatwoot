require 'rails_helper'

RSpec.describe Captain::RewriteService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:content) { 'I need help with my order' }
  let(:event) do
    {
      'name' => event_name,
      'data' => {
        'conversation_display_id' => conversation.display_id,
        'content' => content
      }
    }
  end
  let(:service) { described_class.new(account: account, event: event) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'Rewritten text', input_tokens: 10, output_tokens: 5) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#fix_spelling_grammar_message' do
    let(:event_name) { 'fix_spelling_grammar' }

    it 'uses fix_spelling_grammar prompt' do
      expect(service).to receive(:prompt_from_file).with('fix_spelling_grammar').and_return('Fix errors')

      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages][0][:content]).to eq('Fix errors')
        expect(args[:messages][1][:content]).to eq(content)
        { message: 'Fixed' }
      end

      service.fix_spelling_grammar_message
    end
  end

  describe 'tone rewrite methods' do
    let(:tone_prompt_template) { 'Rewrite in {{ tone }} tone' }

    before do
      allow(service).to receive(:prompt_from_file).with('tone_rewrite').and_return(tone_prompt_template)
    end

    describe '#casual_message' do
      let(:event_name) { 'casual' }

      it 'uses casual tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in casual tone')
          { message: 'Hey, need help?' }
        end

        service.casual_message
      end
    end

    describe '#professional_message' do
      let(:event_name) { 'professional' }

      it 'uses professional tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in professional tone')
          { message: 'Professional text' }
        end

        service.professional_message
      end
    end

    describe '#friendly_message' do
      let(:event_name) { 'friendly' }

      it 'uses friendly tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in friendly tone')
          { message: 'Friendly text' }
        end

        service.friendly_message
      end
    end

    describe '#confident_message' do
      let(:event_name) { 'confident' }

      it 'uses confident tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in confident tone')
          { message: 'Confident text' }
        end

        service.confident_message
      end
    end

    describe '#straightforward_message' do
      let(:event_name) { 'straightforward' }

      it 'uses straightforward tone' do
        expect(service).to receive(:make_api_call) do |args|
          expect(args[:messages][0][:content]).to eq('Rewrite in straightforward tone')
          { message: 'Straightforward text' }
        end

        service.straightforward_message
      end
    end
  end

  describe '#improve_message' do
    let(:event_name) { 'improve' }
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

      service.improve_message
    end

    it 'returns formatted response' do
      result = service.improve_message

      expect(result[:message]).to eq('Rewritten text')
    end
  end
end
