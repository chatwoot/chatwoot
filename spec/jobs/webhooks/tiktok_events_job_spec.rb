require 'rails_helper'

RSpec.describe Webhooks::TiktokEventsJob do
  before do
    allow_any_instance_of(described_class).to receive(:with_lock).and_yield
  end

  let(:account) { create(:account) }
  let!(:channel) { create(:channel_tiktok, account: account, business_id: 'biz-123') }

  describe '#perform' do
    it 'processes im_receive_msg events via Tiktok::MessageService' do
      message_service = instance_double(Tiktok::MessageService, perform: true)
      allow(Tiktok::MessageService).to receive(:new).and_return(message_service)

      event = {
        event: 'im_receive_msg',
        user_openid: 'biz-123',
        content: { conversation_id: 'tt-conv-1' }.to_json
      }

      described_class.perform_now(event)

      expect(Tiktok::MessageService).to have_received(:new).with(channel: channel, content: hash_including(conversation_id: 'tt-conv-1'))
      expect(message_service).to have_received(:perform)
    end

    it 'processes im_mark_read_msg events via Tiktok::ReadStatusService' do
      read_status_service = instance_double(Tiktok::ReadStatusService, perform: true)
      allow(Tiktok::ReadStatusService).to receive(:new).and_return(read_status_service)

      event = {
        event: 'im_mark_read_msg',
        user_openid: 'biz-123',
        content: { conversation_id: 'tt-conv-1', read: { last_read_timestamp: 1_700_000_000_000 }, from_user: { id: 'user-1' } }.to_json
      }

      described_class.perform_now(event)

      expect(Tiktok::ReadStatusService).to have_received(:new).with(channel: channel, content: hash_including(conversation_id: 'tt-conv-1'))
      expect(read_status_service).to have_received(:perform)
    end

    it 'ignores unsupported event types' do
      allow(Tiktok::MessageService).to receive(:new)

      event = {
        event: 'unknown_event',
        user_openid: 'biz-123',
        content: { conversation_id: 'tt-conv-1' }.to_json
      }

      described_class.perform_now(event)

      expect(Tiktok::MessageService).not_to have_received(:new)
    end

    it 'does nothing when channel is missing' do
      allow(Tiktok::MessageService).to receive(:new)

      event = {
        event: 'im_receive_msg',
        user_openid: 'biz-does-not-exist',
        content: { conversation_id: 'tt-conv-1' }.to_json
      }

      described_class.perform_now(event)

      expect(Tiktok::MessageService).not_to have_received(:new)
    end

    it 'does nothing when account is inactive' do
      allow(Channel::Tiktok).to receive(:find_by).and_return(channel)
      allow(channel.account).to receive(:active?).and_return(false)

      message_service = instance_double(Tiktok::MessageService, perform: true)
      allow(Tiktok::MessageService).to receive(:new).and_return(message_service)

      event = {
        event: 'im_receive_msg',
        user_openid: 'biz-123',
        content: { conversation_id: 'tt-conv-1' }.to_json
      }

      described_class.perform_now(event)

      expect(Tiktok::MessageService).not_to have_received(:new)
    end
  end
end
