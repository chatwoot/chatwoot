require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::MediaDownloadFailed do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

  let(:model) { Whatsapp::Session::Model }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:pending_media) do
    model::Content::Media.new(kind: 'image', mime: 'image/jpeg', filename: 'foto.jpg').to_h
  end
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     source_id: '3EB0AAAA0001', content_attributes: { 'pending_media' => pending_media })
  end
  let(:failure) do
    model::Events::MediaDownloadFailed.new(
      chat: chat, message_id: message.source_id, reason: reason, recoverable: recoverable
    )
  end
  let(:event) { model::Event.build(failure, epoch: 1, seq: 1) }

  before { allow(channel).to receive(:provider_service).and_return(backend) }

  context 'when the file is gone for good' do
    let(:reason) { 'media_key_expired' }
    let(:recoverable) { false }

    it 'flags the bubble so the agent stops waiting for it' do
      expect(dispatch).to eq(:handled)

      expect(message.reload.content_attributes['is_unsupported']).to be(true)
    end

    it 'asks nobody for the bytes' do
      expect { dispatch }.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
    end
  end

  context "when WhatsApp dropped the file and the sender's phone may still have it" do
    let(:reason) { 'media_off_cdn' }
    let(:recoverable) { true }

    # The whole point of the flag: the bubble is not flagged, so the fetch that follows
    # can still put the attachment in it. Flagging first is what used to make the
    # recovery unreachable, since MediaFetchJob stands down on `is_unsupported`.
    it 'asks for the bytes instead of giving up on them' do
      expect { dispatch }.to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
        .with(message, pending_media, chat.to_h)

      expect(message.reload.content_attributes['is_unsupported']).to be_nil
    end

    # A file of an imported history is held to the inbox's switch and window like any
    # other: it goes to the drain, which reads them before asking.
    # Also the placeholder recovered live, which keeps `imported` but was rewritten without
    # the history mark.
    it 'hands a history file to the drain instead of asking at once' do
      message.update!(content_attributes: message.content_attributes.merge('imported' => true))

      expect { dispatch }.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
      expect(Redis::Alfred.zrangebyscore(Whatsapp::Session::HistoryMedia.queue_key(inbox), '-inf', '+inf')).to eq([message.id.to_s])
      # Rendered while it waits, with the button, even if the drain never gets to it.
      expect(message.reload.content_attributes['is_unsupported']).to be(true)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    it 'leaves a history file whose download landed meanwhile as it is' do
      message.update!(content_attributes: message.content_attributes.merge('imported' => true))
      allow(Whatsapp::Session::HistoryMedia).to receive(:settled?).and_return(true)

      dispatch

      expect(message.reload.content_attributes).not_to include('is_unsupported', 'history_media')
    end

    # A message published before the writer kept a descriptor, or one that never carried
    # media at all. There is nothing to rebuild an attachment from, so asking would fetch
    # bytes nothing could attach.
    it 'gives up when nothing was kept to fetch with' do
      message.update!(content_attributes: {})

      expect { dispatch }.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
      expect(message.reload.content_attributes['is_unsupported']).to be(true)
    end

    # The bytes arrived by another route while this event was in flight. Flagging the
    # bubble now would say the attachment is missing next to the attachment.
    it 'does nothing for a message that already has its file' do
      message.attachments.create!(account_id: message.account_id, file_type: :image)

      expect(dispatch).to eq(:ignored)
      expect(message.reload.content_attributes['is_unsupported']).to be_nil
    end
  end
end
