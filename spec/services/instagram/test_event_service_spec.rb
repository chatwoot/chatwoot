require 'rails_helper'

describe Instagram::TestEventService do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }

  describe '#perform' do
    context 'when validating test webhook event' do
      let(:test_messaging) do
        {
          'sender': {
            'id': '12334'
          },
          'recipient': {
            'id': '23245'
          },
          'timestamp': '1527459824',
          'message': {
            'mid': 'random_mid',
            'text': 'random_text'
          }
        }.with_indifferent_access
      end

      it 'creates test message for valid test webhook event' do
        # Ensure inbox exists before test
        inbox

        service = described_class.new(test_messaging)

        expect { service.perform }.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('random_text')
        expect(message.source_id).to eq('random_mid')
        expect(message.message_type).to eq('incoming')
      end

      it 'creates a contact with sender_username' do
        # Ensure inbox exists before test
        inbox

        service = described_class.new(test_messaging)
        service.perform

        contact = Contact.last
        expect(contact.name).to eq('sender_username')
      end

      it 'returns false for non-test webhook events' do
        invalid_messaging = test_messaging.deep_dup
        invalid_messaging[:sender][:id] = 'different_id'

        service = described_class.new(invalid_messaging)

        expect(service.perform).to be(false)
      end

      it 'returns nil when no Instagram channel exists' do
        # Delete all inboxes and channels
        Inbox.destroy_all
        Channel::Instagram.destroy_all

        service = described_class.new(test_messaging)

        expect(service.perform).to be_nil
      end
    end
  end
end
