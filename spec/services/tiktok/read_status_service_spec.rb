require 'rails_helper'

RSpec.describe Tiktok::ReadStatusService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_tiktok, account: account, business_id: 'biz-123') }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'tt-conv-1') }
  let!(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      additional_attributes: { conversation_id: 'tt-conv-1' }
    )
  end

  describe '#perform' do
    it 'enqueues Conversations::UpdateMessageStatusJob for inbound read events' do
      allow(Conversations::UpdateMessageStatusJob).to receive(:perform_later)

      content = {
        conversation_id: 'tt-conv-1',
        read: { last_read_timestamp: 1_700_000_000_000 },
        from_user: { id: 'user-1' }
      }.deep_symbolize_keys

      described_class.new(channel: channel, content: content).perform

      expect(Conversations::UpdateMessageStatusJob).to have_received(:perform_later).with(conversation.id, kind_of(Time))
    end
  end
end
