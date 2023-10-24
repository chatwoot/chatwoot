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

    context 'when message sent to fail' do
      it 'raises an error with out details' do
        error_response = {
          'message' => 'Invalid reply token'
        }
        allow(line_client).to receive(:push_message).and_raise(error_response.to_json)
        expect { described_class.new(message: message).perform }.to raise_error.with_message(error_response.to_json)
      end

      it 'raises an error with details' do
        error_response = {
          'message' => 'The request body has 1 error(s)',
          'details' => [
            {
              'message' => 'May not be empty',
              'property' => 'messages[0].text'
            }
          ]
        }
        allow(line_client).to receive(:push_message).and_raise(error_response.to_json)
        expect { described_class.new(message: message).perform }.to raise_error.with_message(error_response.to_json)
      end
    end
  end
end
