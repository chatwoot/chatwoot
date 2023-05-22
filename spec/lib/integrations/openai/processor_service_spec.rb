require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject { described_class.new(hook: hook, event: event) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :openai, account: account) }
  let(:expected_headers) { { 'Authorization' => "Bearer #{hook.settings['api_key']}" } }
  let(:openai_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => 'This is a reply from openai.'
          }
        }
      ]
    }.to_json
  end
  let!(:conversation) { create(:conversation, account: account) }
  let!(:customer_message) { create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent') }
  let!(:agent_message) { create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer') }

  describe '#perform' do
    context 'when event name is rephrase' do
      let(:event) { { 'name' => 'rephrase', 'data' => { 'tone' => 'friendly', 'content' => 'This is a test message' } } }

      it 'returns the rephrased message using the tone in data' do
        request_body = {
          'model' => 'gpt-3.5-turbo',
          'messages' => [
            {
              'role' => 'system',
              'content' => 'You are a helpful support agent. ' \
                           'Please rephrase the following response to a more ' \
                           "#{event['data']['tone']} tone. Reply in the user's language."
            },
            { 'role' => 'user', 'content' => event['data']['content'] }
          ]
        }.to_json

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq('This is a reply from openai.')
      end
    end

    context 'when event name is reply_suggestion' do
      let(:event) { { 'name' => 'reply_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

      it 'returns the suggested reply' do
        request_body = {
          'model' => 'gpt-3.5-turbo',
          'messages' => [
            { role: 'system',
              content: 'Please suggest a reply to the following conversation between support agents and customer. Reply in the user\'s language.' },
            { role: 'user', content: customer_message.content },
            { role: 'assistant', content: agent_message.content }
          ]
        }.to_json

        # Update the stub_request with the correct messages order
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq('This is a reply from openai.')
      end
    end

    context 'when event name is summarize' do
      let(:event) { { 'name' => 'summarize', 'data' => { 'conversation_display_id' => conversation.display_id } } }
      let(:conversation_messages) do
        "Customer #{customer_message.sender.name} : #{customer_message.content}\nAgent #{agent_message.sender.name} : #{agent_message.content}\n"
      end

      it 'returns the summarized message' do
        request_body = {
          'model' => 'gpt-3.5-turbo',
          'messages' => [
            { 'role' => 'system',
              'content' => 'Please summarize the key points from the following conversation between support agents and customer ' \
                           'as bullet points for the next support agent looking into the conversation. Reply in the user\'s language.' },
            { 'role' => 'user', 'content' => conversation_messages }
          ]
        }.to_json

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq('This is a reply from openai.')
      end
    end

    context 'when event name is not one that can be processed' do
      let(:event) { { 'name' => 'unknown', 'data' => {} } }

      it 'returns nil' do
        expect(subject.perform).to be_nil
      end
    end
  end
end
