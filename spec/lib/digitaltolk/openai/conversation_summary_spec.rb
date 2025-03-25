require 'rails_helper'

describe Digitaltolk::Openai::ConversationSummary do
  subject { described_class.new.perform(conversation) }

  let(:conversation) { create(:conversation) }

  let(:stubbed_base_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => {
              'summary' => 'summary',
              'translated_summary' => 'translated summary'
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
    it 'returns the summary and translated summary' do
      expect(subject).to eq({ 'summary' => 'summary', 'translated_summary' => 'translated summary' })
    end

    it 'does not trigger an error' do
      expect { subject }.not_to raise_error
    end
  end

  describe 'conversation_messages' do
    let!(:message1) { create(:message, content: 'This is an incoming question', conversation: conversation, message_type: :incoming) }
    let!(:message2) { create(:message, content: 'This is outgoing message', conversation: conversation, message_type: :outgoing) }

    it 'returns the conversation messages' do
      service = described_class.new
      service.instance_variable_set(:@conversation, conversation)
      expect(service.send(:conversation_messages)).to eq([message1, message2])
    end
  end
end
