require 'rails_helper'

describe Digitaltolk::Openai::QualityCheck do
  subject { described_class.new.perform(conversation, response) }

  let(:conversation) { create(:conversation) }
  let(:response) { 'This is a test response' }
  let(:stubbed_base_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => stubbed_prompt_response
          }
        }
      ]
    }
  end

  before do
    create(:message, content: 'This is a test question', conversation: conversation, message_type: :incoming)

    stub_request(:post, "#{Digitaltolk::Openai::Base::API_BASE_URL}/#{Digitaltolk::Openai::Base::API_VERSION}/chat/completions")
      .to_return(status: 200, body: stubbed_base_response.to_json, headers: {})
  end

  describe '#perform' do
    context 'when base response is empty' do
      let(:stubbed_base_response) { {} }
      let(:stubbed_prompt_response) { {} }

      it 'returns the response from OpenAI' do
        expect(subject).to eq(stubbed_prompt_response)
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when base response is not empty' do
      let(:stubbed_prompt_response) do
        {
          'response' => {
            'answer_quality_check': {
              score: 95,
              feedback: 'This is a good response',
              passed: true
            },
            'language_and_grammar_check': {
              score: 90,
              corrected_message: 'This is a good response',
              passed: true
            },
            'customer_centricity_check': {
              score: 95,
              passed: true
            }
          },
          :passed => true
        }.to_json
      end

      it 'returns the response from OpenAI' do
        expect(subject).to eq(JSON.parse(stubbed_prompt_response))
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
