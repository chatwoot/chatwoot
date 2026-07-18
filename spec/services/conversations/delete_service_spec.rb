require 'rails_helper'

RSpec.describe Conversations::DeleteService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:ip) { '127.0.0.1' }
  let(:service) { described_class.new(conversation: conversation, user: user, ip: ip) }

  context 'when deleting an email conversation' do
    let(:inbox) { create(:channel_email, :imap_email, account: account).inbox }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let!(:incoming_message) { create(:message, account: account, inbox: inbox, conversation: conversation, source_id: 'incoming@example.com') }
    let(:deleted_message_tracker) { instance_double(Imap::DeletedMessageTracker, record: true) }

    before do
      allow(Imap::DeletedMessageTracker).to receive(:new).with(inbox: inbox).and_return(deleted_message_tracker)
    end

    it 'records incoming message source ids and enqueues the deletion job' do
      expect { service.perform }.to have_enqueued_job(DeleteObjectJob).with(conversation, user, ip)

      expect(deleted_message_tracker).to have_received(:record).with([incoming_message.source_id])
    end
  end

  context 'when deleting a non-email conversation' do
    let(:conversation) { create(:conversation, account: account) }

    it 'enqueues the deletion job without recording message source ids' do
      expect(Imap::DeletedMessageTracker).not_to receive(:new)

      expect { service.perform }.to have_enqueued_job(DeleteObjectJob).with(conversation, user, ip)
    end
  end
end
