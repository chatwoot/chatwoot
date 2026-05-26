require 'rails_helper'

describe Line::IncomingMessageService do
  let!(:line_channel) { create(:channel_line) }
  let(:inbox) { line_channel.inbox }

  let(:params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': { 'type': 'user', 'userId': 'U4af4980629' },
          'message': { 'id': '325708', 'type': 'text', 'text': 'Hello, world' }
        }
      ]
    }.with_indifferent_access
  end

  let(:multi_user_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f1',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': { 'type': 'user', 'userId': 'U4af4980629' },
          'message': { 'id': '3257081', 'type': 'text', 'text': 'Hello, world 1' }
        },
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f2',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': { 'type': 'user', 'userId': 'U4af49806292' },
          'message': { 'id': '3257082', 'type': 'text', 'text': 'Hello, world 2' }
        }
      ]
    }.with_indifferent_access
  end

  describe '#perform' do
    it 'does nothing when events are blank' do
      expect(Line::MessageCreator).not_to receive(:perform_later)
      described_class.new(inbox: inbox, params: { events: [] }).perform
    end

    it 'dispatches one job for a single user' do
      expect(Line::MessageCreator).to receive(:perform_later).once
      described_class.new(inbox: inbox, params: params).perform
    end

    it 'dispatches one job per user group when multiple users send messages' do
      expect(Line::MessageCreator).to receive(:perform_later).twice
      described_class.new(inbox: inbox, params: multi_user_params).perform
    end
  end
end
