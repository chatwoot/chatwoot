require 'rails_helper'

RSpec.describe Webhooks::XEventsJob do
  let(:account) { create(:account) }
  let!(:channel) { create(:channel_x, account: account, profile_id: '12345') }
  let(:job) { described_class.new }

  before do
    allow(job).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    context 'with direct message events' do
      it 'processes direct messages via X::IncomingMessageService' do
        message_service = instance_double(X::IncomingMessageService, perform: true)
        allow(X::IncomingMessageService).to receive(:new).and_return(message_service)

        event = {
          for_user_id: '12345',
          direct_message_events: [
            {
              message_create: {
                sender_id: '67890',
                target: { recipient_id: '12345' },
                message_data: {
                  text: 'Hello!',
                  id: 'dm-123',
                  created_timestamp: Time.current.to_i * 1000
                }
              }
            }
          ]
        }

        job.perform(event)

        expect(X::IncomingMessageService).to have_received(:new).with(
          channel: channel,
          dm_event: hash_including(
            message_create: hash_including(sender_id: '67890')
          ),
          users: nil
        )
        expect(message_service).to have_received(:perform)
      end

      it 'processes multiple direct messages' do
        message_service = instance_double(X::IncomingMessageService, perform: true)
        allow(X::IncomingMessageService).to receive(:new).and_return(message_service)

        event = {
          for_user_id: '12345',
          direct_message_events: [
            {
              message_create: {
                sender_id: '67890',
                target: { recipient_id: '12345' },
                message_data: { text: 'Message 1', id: 'dm-1', created_timestamp: 1000 }
              }
            },
            {
              message_create: {
                sender_id: '67890',
                target: { recipient_id: '12345' },
                message_data: { text: 'Message 2', id: 'dm-2', created_timestamp: 2000 }
              }
            }
          ]
        }

        job.perform(event)

        expect(X::IncomingMessageService).to have_received(:new).twice
      end
    end

    context 'with tweet events' do
      it 'processes tweet mentions via X::IncomingMessageService' do
        message_service = instance_double(X::IncomingMessageService, perform: true)
        allow(X::IncomingMessageService).to receive(:new).and_return(message_service)

        event = {
          for_user_id: '12345',
          tweet_create_events: [
            {
              id_str: 'tweet-123',
              text: '@myaccount Hello!',
              in_reply_to_user_id: '12345',
              user: {
                id_str: '67890',
                name: 'John Doe',
                username: 'johndoe'
              },
              entities: {
                user_mentions: [{ id_str: '12345', screen_name: 'myaccount' }]
              }
            }
          ]
        }

        job.perform(event)

        expect(X::IncomingMessageService).to have_received(:new).with(
          channel: channel,
          tweet_data: hash_including(id_str: 'tweet-123')
        )
        expect(message_service).to have_received(:perform)
      end

      it 'ignores tweets not directed at the channel profile' do
        allow(X::IncomingMessageService).to receive(:new)

        event = {
          for_user_id: '12345',
          tweet_create_events: [
            {
              id_str: 'tweet-123',
              text: '@someone_else Hello!',
              in_reply_to_user_id: '99999',
              user: { id_str: '67890' }
            }
          ]
        }

        job.perform(event)

        expect(X::IncomingMessageService).not_to have_received(:new)
      end
    end

    it 'does nothing when channel is missing' do
      allow(X::IncomingMessageService).to receive(:new)

      event = {
        for_user_id: 'nonexistent-profile',
        direct_message_events: [
          { message_create: { sender_id: '123' } }
        ]
      }

      job.perform(event)

      expect(X::IncomingMessageService).not_to have_received(:new)
    end

    it 'does nothing when account is inactive' do
      allow(Channel::X).to receive(:find_by).and_return(channel)
      allow(channel.account).to receive(:active?).and_return(false)
      allow(X::IncomingMessageService).to receive(:new)

      event = {
        for_user_id: '12345',
        direct_message_events: [
          { message_create: { sender_id: '123' } }
        ]
      }

      job.perform(event)

      expect(X::IncomingMessageService).not_to have_received(:new)
    end

    it 'handles events with no processable data gracefully' do
      allow(X::IncomingMessageService).to receive(:new)

      event = {
        for_user_id: '12345'
      }

      expect { job.perform(event) }.not_to raise_error
      expect(X::IncomingMessageService).not_to have_received(:new)
    end
  end
end
