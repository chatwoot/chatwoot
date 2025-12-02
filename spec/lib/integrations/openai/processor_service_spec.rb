require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject(:service) { described_class.new(hook: hook, event: event) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :openai, account: account) }
  let(:expected_headers) { { 'Authorization' => "Bearer #{hook.settings['api_key']}" } }
  let(:openai_response) do
    {
      'choices' => [{ 'message' => { 'content' => 'This is a reply from openai.' } }]
    }.to_json
  end
  let(:openai_response_with_usage) do
    {
      'choices' => [{ 'message' => { 'content' => 'This is a reply from openai.' } }],
      'usage' => {
        'prompt_tokens' => 50,
        'completion_tokens' => 20,
        'total_tokens' => 70
      }
    }.to_json
  end

  describe '#perform' do
    shared_examples 'text transformation operation' do |event_name, system_prompt|
      let(:event) { { 'name' => event_name, 'data' => { 'content' => 'This is a test' } } }
      let(:expected_request_body) do
        {
          'model' => 'gpt-4o-mini',
          'messages' => [
            { 'role' => 'system', 'content' => system_prompt },
            { 'role' => 'user', 'content' => 'This is a test' }
          ]
        }.to_json
      end

      it "returns the #{event_name.tr('_', ' ')} text" do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: expected_request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response)

        result = service.perform
        expect(result[:message]).to eq('This is a reply from openai.')
      end
    end

    shared_examples 'successful openai response' do
      it 'returns the expected message' do
        result = service.perform
        expect(result[:message]).to eq('This is a reply from openai.')
      end
    end

    describe 'text transformation operations' do
      base_prompt = 'You are a helpful support agent. '
      language_suffix = 'Ensure that the reply should be in user language.'

      it_behaves_like 'text transformation operation', 'rephrase',
                      "#{base_prompt}Please rephrase the following response. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'fix_spelling_grammar',
                      "#{base_prompt}Please fix the spelling and grammar of the following response. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'shorten',
                      "#{base_prompt}Please shorten the following response. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'expand',
                      "#{base_prompt}Please expand the following response. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'make_friendly',
                      "#{base_prompt}Please make the following response more friendly. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'make_formal',
                      "#{base_prompt}Please make the following response more formal. #{language_suffix}"
      it_behaves_like 'text transformation operation', 'simplify',
                      "#{base_prompt}Please simplify the following response. #{language_suffix}"
    end

    describe 'conversation-based operations' do
      let!(:conversation) { create(:conversation, account: account) }
      let!(:customer_message) do
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent')
      end
      let!(:agent_message) do
        create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer')
      end

      context 'with reply_suggestion event' do
        let(:event) { { 'name' => 'reply_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }
        let(:expected_request_body) do
          {
            'model' => 'gpt-4o-mini',
            'messages' => [
              { role: 'system', content: Rails.root.join('lib/integrations/openai/openai_prompts/reply.txt').read },
              { role: 'user', content: customer_message.content },
              { role: 'assistant', content: agent_message.content }
            ]
          }.to_json
        end

        before do
          stub_request(:post, 'https://api.openai.com/v1/chat/completions')
            .with(body: expected_request_body, headers: expected_headers)
            .to_return(status: 200, body: openai_response)
        end

        it_behaves_like 'successful openai response'
      end

      context 'with summarize event' do
        let(:event) { { 'name' => 'summarize', 'data' => { 'conversation_display_id' => conversation.display_id } } }
        let(:conversation_messages) do
          "Customer #{customer_message.sender.name} : #{customer_message.content}\n" \
            "Agent #{agent_message.sender.name} : #{agent_message.content}\n"
        end
        let(:summary_prompt) do
          if ChatwootApp.enterprise?
            # -------------- Reason ---------------
            # Modified to check for 'extended' directory instead of 'enterprise'
            # ------------ Original -----------------------
            # Rails.root.join('enterprise/lib/enterprise/integrations/openai_prompts/summary.txt').read
            # ---------------------------------------------
            # ---------------------- Modification Begin ----------------------
            Rails.root.join('extended/lib/enterprise/integrations/openai_prompts/summary.txt').read
            # ---------------------- Modification End ------------------------
          else
            'Please summarize the key points from the following conversation between support agents and customer as bullet points ' \
              "for the next support agent looking into the conversation. Reply in the user's language."
          end
        end
        let(:expected_request_body) do
          {
            'model' => 'gpt-4o-mini',
            'messages' => [
              { 'role' => 'system', 'content' => summary_prompt },
              { 'role' => 'user', 'content' => conversation_messages }
            ]
          }.to_json
        end

        before do
          stub_request(:post, 'https://api.openai.com/v1/chat/completions')
            .with(body: expected_request_body, headers: expected_headers)
            .to_return(status: 200, body: openai_response)
        end

        it_behaves_like 'successful openai response'
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
          stub_request(:post, 'https://api.openai.com/v1/chat/completions')
            .with(body: anything, headers: expected_headers)
            .to_return(status: 200, body: openai_response_with_usage)
        end

        it 'returns message, usage, and request_messages' do
          result = service.perform

          expect(result[:message]).to eq('This is a reply from openai.')
          expect(result[:usage]).to eq({
                                         'prompt_tokens' => 50,
                                         'completion_tokens' => 20,
                                         'total_tokens' => 70
                                       })
          expect(result[:request_messages]).to be_an(Array)
          expect(result[:request_messages].length).to eq(2)
        end
      end

      context 'when response does not include usage data' do
        before do
          stub_request(:post, 'https://api.openai.com/v1/chat/completions')
            .with(body: anything, headers: expected_headers)
            .to_return(status: 200, body: openai_response)
        end

        it 'returns message and request_messages with nil usage' do
          result = service.perform

          expect(result[:message]).to eq('This is a reply from openai.')
          expect(result[:usage]).to be_nil
          expect(result[:request_messages]).to be_an(Array)
        end
      end
    end

    describe 'endpoint configuration' do
      let(:event) { { 'name' => 'rephrase', 'data' => { 'content' => 'test message' } } }

      shared_examples 'endpoint request' do |endpoint_url|
        it "makes request to #{endpoint_url}" do
          stub_request(:post, "#{endpoint_url}/v1/chat/completions")
            .with(body: anything, headers: expected_headers)
            .to_return(status: 200, body: openai_response)

          result = service.perform
          expect(result[:message]).to eq('This is a reply from openai.')
          expect(result[:request_messages]).to be_an(Array)
          expect(result[:usage]).to be_nil
        end
      end

      context 'without CAPTAIN_OPEN_AI_ENDPOINT configured' do
        before { InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.destroy }

        it_behaves_like 'endpoint request', 'https://api.openai.com'
      end

      context 'with CAPTAIN_OPEN_AI_ENDPOINT configured' do
        before do
          InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.destroy
          create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: 'https://custom.azure.com/')
        end

        it_behaves_like 'endpoint request', 'https://custom.azure.com'
      end
    end
  end
end
