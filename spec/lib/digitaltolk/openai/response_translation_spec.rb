require 'rails_helper'

describe Digitaltolk::Openai::ResponseTranslation do
  subject { described_class.new.perform(content, customer_query) }

  let(:content) { 'This is a test content' }
  let(:customer_query) { 'This is a test customer query' }
  let(:stubbed_base_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => {
              'translated_agent_message' => 'translated text',
              'translated_agent_message_locale' => 'sv',
              'agent_message_locale' => 'en',
              'customer_message_locale' => 'en'
            }.to_json
          }
        }
      ]
    }
  end

  before do
    stub_request(:post, "#{Digitaltolk::Openai::Base::API_BASE_URL}/#{Digitaltolk::Openai::Base::API_VERSION}/chat/completions")
      .to_return(status: 200, body: stubbed_base_response.to_json, headers: {})
  end

  describe '#perform' do
    context 'when base response is not empty' do
      it 'returns the translated message' do
        expect(subject).to eq(JSON.parse(stubbed_base_response['choices'][0]['message']['content']))
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
