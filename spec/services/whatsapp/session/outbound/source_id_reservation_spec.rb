require 'rails_helper'

RSpec.describe Whatsapp::Session::Outbound::SourceIdReservation do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account, message_type: :outgoing)
  end

  it 'generates ids in the shape WhatsApp clients use' do
    expect(described_class.generate).to match(/\A3EB0[0-9A-F]{18}\z/)
  end

  it 'reserves once and reuses the reservation on a retry' do
    reserved = described_class.reserve(message)

    expect(reserved).to be_present
    expect(described_class.reserve(message.reload)).to eq(reserved)
  end

  # Whoever moves `source_id` from blank to set owns the revoke of a message deleted
  # mid-send, and three writers race for it.
  describe '.assign' do
    it 'owes the revoke only to the caller that assigned the id of a deleted message' do
      message.update_under_lock!(deleted: true)

      first = described_class.assign(message, { source_id: '3EB0FIRST' })
      second = described_class.assign(message.reload, { source_id: '3EB0FIRST' })

      expect([first, second]).to eq(%i[revoke written])
    end

    it 'owes nothing when the message is still alive' do
      expect(described_class.assign(message, { source_id: '3EB0FIRST' })).to eq(:written)
      expect(message.reload.source_id).to eq('3EB0FIRST')
    end

    # Toggling a reaction rewrites the same row and clears its reservation on purpose. A
    # slow response from the emoji that was just replaced must not write its id back: the
    # replacement send would then be skipped as something the provider already has.
    it 'refuses a response whose reservation the row has moved on from' do
      described_class.reserve(message)
      stale = message.reload.pending_source_id
      message.update_under_lock!(pending_source_id: nil)

      expect(described_class.assign(message.reload, { source_id: '3EB0FIRST' }, reservation: stale)).to eq(:stale)
      expect(message.reload.source_id).to be_nil
    end

    # The echo of a send we already gave up on. Waiting for a delivery receipt to promote
    # it leaves a window where the message is proven to exist and still shows Retry — and
    # Retry clears the reservation and sends a fresh id, producing exactly the duplicate
    # this reservation exists to prevent.
    it 'retires a local send failure when the id proves the message exists' do
      message.update!(status: :failed, external_error: 'send timed out')

      expect(described_class.assign(message, { source_id: '3EB0FIRST' })).to eq(:written)

      expect(message.reload.status).to eq('sent')
      expect(message.external_error).to be_blank
    end

    # Only the writer that fills the column, and only over a failure. A receipt that
    # already moved the message forward must not be walked back to `sent`.
    it 'leaves a message the provider already confirmed where it is' do
      described_class.assign(message, { source_id: '3EB0FIRST' })
      message.reload.update!(status: :delivered)

      described_class.assign(message.reload, { source_id: '3EB0FIRST' })

      expect(message.reload.status).to eq('delivered')
    end

    # `update_all` would have written the id without changing the record, leaving
    # `previous_changes` empty: dashboards and webhooks never learn the provider id, and
    # the reaction toolbar stays hidden until something else touches the message.
    it 'writes through the model so the update is broadcast' do
      described_class.assign(message, { source_id: '3EB0FIRST' })

      expect(message.saved_changes).to include('source_id')
    end
  end
end
