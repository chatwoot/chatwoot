require 'rails_helper'

describe Line::SendOnLineService do
  describe '#perform' do
    context 'when a valid message' do
      it 'calls @channel.client.push_message' do
        line_client = double
        line_channel = create(:channel_line)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: create(:conversation, inbox: line_channel.inbox))
        allow(line_client).to receive(:push_message)
        allow(Line::Bot::Client).to receive(:new).and_return(line_client)
        expect(line_client).to receive(:push_message)
        described_class.new(message: message).perform
      end
    end
  end
end
