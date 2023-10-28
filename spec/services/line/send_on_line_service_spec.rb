require 'rails_helper'

describe Line::SendOnLineService do
  describe '#perform' do
    let(:line_client) { double }
    let(:line_channel) { create(:channel_line) }
    let(:message) do
      create(:message, message_type: :outgoing, content: 'test',
                       conversation: create(:conversation, inbox: line_channel.inbox))
    end

    before do
      allow(Line::Bot::Client).to receive(:new).and_return(line_client)
    end

    context 'when message send' do
      it 'calls @channel.client.push_message' do
        allow(line_client).to receive(:push_message)
        expect(line_client).to receive(:push_message)
        described_class.new(message: message).perform
      end
    end

    context 'when message send fails without details' do
      let(:error_response) do
        {
          'message' => 'The request was invalid'
        }.to_json
      end

      before do
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '400', body: error_response))
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('failed')
      end

      it 'updates the external error without details' do
        described_class.new(message: message).perform
        message.reload
        expect(message.external_error).to eq('The request was invalid')
      end
    end

    context 'when message send fails with details' do
      let(:error_response) do
        {
          'message' => 'The request was invalid',
          'details' => [
            {
              'property' => 'messages[0].text',
              'message' => 'May not be empty'
            }
          ]
        }.to_json
      end

      before do
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '400', body: error_response))
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('failed')
      end

      it 'updates the external error with details' do
        described_class.new(message: message).perform
        message.reload
        expect(message.external_error).to eq('The request was invalid, messages[0].text: May not be empty')
      end
    end

    context 'when message send succeeds' do
      let(:success_response) do
        {
          'message' => 'ok'
        }.to_json
      end

      before do
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '200', body: success_response))
      end

      it 'updates the message status to delivered' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('delivered')
      end
    end
  end
end
