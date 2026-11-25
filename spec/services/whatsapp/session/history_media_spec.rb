require 'rails_helper'

RSpec.describe Whatsapp::Session::HistoryMedia do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:model) { Whatsapp::Session::Model }
  let(:ref) { model::MediaRef.new(kind: 'url', url: 'https://connector.test/media/abc', mime: 'image/jpeg') }
  let(:inbound) do
    model::InboundMessage.new(id: '3EB0DEF1', chat: model::Address.phone('5541999990000'), from_me: false,
                              timestamp: 1_755_440_000_123, content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', ref: ref))
  end
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: '3EB0DEF1',
                     content_attributes: { 'imported' => true, 'history_archive' => true })
  end

  describe '.defer' do
    # A redelivery of an archived message, outside any import: the bookkeeping is a write
    # to that message, and an update outside the history context reaches bots and webhooks.
    it 'writes the pending marks as history' do
      levels = []
      allow(message).to receive(:update!).and_wrap_original do |original, *args|
        levels << Import::SilentWrite.on?
        original.call(*args)
      end

      described_class.defer(message, inbound)

      expect(levels).to eq([true])
      expect(message.reload.content_attributes.dig('pending_media', 'ref', 'url')).to eq(ref.url)
    end

    # The download landed between the caller's look and the lock.
    it 'leaves a message whose file arrived meanwhile as it is' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!

      described_class.defer(message, inbound)

      expect(message.reload.content_attributes).not_to include('is_unsupported', 'history_media')
    end

    it 'leaves a message deleted meanwhile as it is' do
      message.update!(content_attributes: message.content_attributes.merge('deleted' => true))

      described_class.defer(message, inbound)

      expect(message.reload.content_attributes).not_to include('history_media', 'pending_media')
    end

    it 'leaves a message whose file was given up on meanwhile as it is' do
      message.update!(content_attributes: message.content_attributes.merge('media_unavailable' => true))

      described_class.defer(message, inbound)

      expect(message.reload.content_attributes).not_to include('history_media', 'pending_media')
    end
  end

  describe '.requeue' do
    let(:queue) { described_class.queue_key(inbox) }

    after do
      Redis::Alfred.delete(queue)
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    def pending(source_id, at)
      create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: source_id, created_at: at,
                       content_attributes: { 'is_unsupported' => true, 'history_media' => true, 'imported' => true,
                                             'pending_media' => model::Content::Media.new(kind: 'image', mime: 'image/jpeg').to_h })
    end

    # On a large inbox the collection is a run's work like any other, and a run has a budget.
    it 'stops at the deadline and says where to pick up' do
      older = pending('R1', 2.days.ago)
      newer = pending('R2', 1.day.ago)

      from = described_class.requeue(inbox, deadline: 1.second.ago)
      expect(from).to eq(newer.id)
      expect(Redis::Alfred.zcard(queue)).to eq(0)

      expect(described_class.requeue(inbox, from: from, deadline: 1.minute.from_now)).to be_nil
      expect(Redis::Alfred.zrangebyscore(queue, '-inf', '+inf')).to contain_exactly(older.id.to_s, newer.id.to_s)
    end
  end
end
