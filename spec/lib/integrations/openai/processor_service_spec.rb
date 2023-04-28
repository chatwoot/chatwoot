require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject { described_class.new(hook: hook, event: event) }

  let(:hook) { create(:integrations_hook, :openai) }
  let(:expected_headers) { { 'Authorization' => "Bearer #{hook.settings['api_key']}" } }
  let(:openai_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => 'This is a rephrased test message.'
          }
        }
      ]
    }.to_json
  end

  describe '#perform' do
    context 'when event name is rephrase' do
      let(:event) { { 'name' => 'rephrase', 'data' => { 'tone' => 'friendly', 'content' => 'This is a test message' } } }

      it 'returns the rephrased message using the tone in data' do
        request_body = {
          'model' => 'gpt-3.5-turbo',
          'messages' => [
            { 'role' => 'system',
              'content' => "You are a helpful support agent. Please rephrase the following response to a more #{event['data']['tone']} tone." },
            { 'role' => 'user', 'content' => event['data']['content'] }
          ]
        }.to_json

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq('This is a rephrased test message.')
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
