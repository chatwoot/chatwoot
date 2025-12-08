require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject(:service) { described_class.new(hook: hook, event: event) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :openai, account: account) }

  # Mock RubyLLM objects
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context) }
  let(:mock_config) { OpenStruct.new }
  let(:mock_response) do
    instance_double(
      RubyLLM::Message,
      content: 'This is a reply from openai.',
      input_tokens: nil,
      output_tokens: nil
    )
  end
  let(:mock_response_with_usage) do
    instance_double(
      RubyLLM::Message,
      content: 'This is a reply from openai.',
      input_tokens: 50,
      output_tokens: 20
    )
  end

  before do
    allow(RubyLLM).to receive(:context).and_yield(mock_config).and_return(mock_context)
    allow(mock_context).to receive(:chat).and_return(mock_chat)

    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:add_message).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#perform' do
    describe 'text transformation operations' do
      shared_examples 'text transformation operation' do |event_name|
        let(:event) { { 'name' => event_name, 'data' => { 'content' => 'This is a test' } } }

        it 'returns the transformed text' do
          result = service.perform
          expect(result[:message]).to eq('This is a reply from openai.')
        end

        it 'sends the user content to the LLM' do
          service.perform
          expect(mock_chat).to have_received(:ask).with('This is a test')
        end

        it 'sets system instructions' do
          service.perform
          expect(mock_chat).to have_received(:with_instructions).with(a_string_including('You are a helpful support agent'))
        end
      end

      it_behaves_like 'text transformation operation', 'rephrase'
      it_behaves_like 'text transformation operation', 'fix_spelling_grammar'
      it_behaves_like 'text transformation operation', 'shorten'
      it_behaves_like 'text transformation operation', 'expand'
      it_behaves_like 'text transformation operation', 'make_friendly'
      it_behaves_like 'text transformation operation', 'make_formal'
      it_behaves_like 'text transformation operation', 'simplify'
    end

    describe 'conversation-based operations' do
      let!(:conversation) { create(:conversation, account: account) }

      before do
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent')
        create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer')
      end

      context 'with reply_suggestion event' do
        let(:event) { { 'name' => 'reply_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

        it 'returns the suggested reply' do
          result = service.perform
          expect(result[:message]).to eq('This is a reply from openai.')
        end

        it 'adds conversation history before asking' do
          service.perform
          # Should add the first message as history, then ask with the last message
          expect(mock_chat).to have_received(:add_message).with(role: :user, content: 'hello agent')
          expect(mock_chat).to have_received(:ask).with('hello customer')
        end
      end

      context 'with summarize event' do
        let(:event) { { 'name' => 'summarize', 'data' => { 'conversation_display_id' => conversation.display_id } } }

        it 'returns the summary' do
          result = service.perform
          expect(result[:message]).to eq('This is a reply from openai.')
        end

        it 'sends formatted conversation as a single message' do
          service.perform
          # Summarize sends conversation as a formatted string in one user message
          expect(mock_chat).to have_received(:ask).with(a_string_matching(/Customer.*hello agent.*Agent.*hello customer/m))
        end
      end

      context 'with label_suggestion event and no labels' do
        let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

        it 'returns nil' do
          expect(service.perform).to be_nil
        end
      end
    end

    describe 'edge cases' do
      context 'with unknown event name' do
        let(:event) { { 'name' => 'unknown', 'data' => {} } }

        it 'returns nil' do
          expect(service.perform).to be_nil
        end
      end
    end

    describe 'response structure' do
      let(:event) { { 'name' => 'rephrase', 'data' => { 'content' => 'test message' } } }

      context 'when response includes usage data' do
        before do
          allow(mock_chat).to receive(:ask).and_return(mock_response_with_usage)
        end

        it 'returns message with usage data' do
          result = service.perform

          expect(result[:message]).to eq('This is a reply from openai.')
          expect(result[:usage]['prompt_tokens']).to eq(50)
          expect(result[:usage]['completion_tokens']).to eq(20)
          expect(result[:usage]['total_tokens']).to eq(70)
        end

        it 'includes request_messages in response' do
          result = service.perform

          expect(result[:request_messages]).to be_an(Array)
          expect(result[:request_messages].length).to eq(2)
        end
      end

      context 'when response does not include usage data' do
        it 'returns message with zero total tokens' do
          result = service.perform

          expect(result[:message]).to eq('This is a reply from openai.')
          expect(result[:usage]['total_tokens']).to eq(0)
        end

        it 'includes request_messages in response' do
          result = service.perform

          expect(result[:request_messages]).to be_an(Array)
        end
      end
    end

    describe 'endpoint configuration' do
      let(:event) { { 'name' => 'rephrase', 'data' => { 'content' => 'test message' } } }

      context 'without CAPTAIN_OPEN_AI_ENDPOINT configured' do
        before { InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.destroy }

        it 'uses default OpenAI endpoint' do
          expect(Llm::Config).to receive(:with_api_key).with(
            hook.settings['api_key'],
            api_base: 'https://api.openai.com/v1'
          ).and_call_original

          service.perform
        end
      end

      context 'with CAPTAIN_OPEN_AI_ENDPOINT configured' do
        before do
          InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.destroy
          create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: 'https://custom.azure.com/')
        end

        it 'uses custom endpoint' do
          expect(Llm::Config).to receive(:with_api_key).with(
            hook.settings['api_key'],
            api_base: 'https://custom.azure.com/v1'
          ).and_call_original

          service.perform
        end
      end
    end
  end
end
