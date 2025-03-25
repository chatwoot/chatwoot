require 'rails_helper'

describe Digitaltolk::Openai::Translation do
  subject { described_class.new.perform(content) }

  let(:content) { 'This is a test content' }
  let(:stubbed_base_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => {
              'translated_message' => 'translated text',
              'translated_locale' => 'sv'
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
        expect(subject).to eq({ 'translated_message' => 'translated text', 'translated_locale' => 'sv' })
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
