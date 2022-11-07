require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailsJob, type: :job do
  let(:account) { create(:account) }
  let(:imap_email_channel) do
    create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com', imap_port: 993, imap_login: 'imap@gmail.com',
                           imap_password: 'password', imap_inbox_synced_at: Time.now.utc, account: account)
  end
  let!(:conversation) { create(:conversation, inbox: imap_email_channel.inbox, account: account) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when imap fetch new emails' do
    it 'process the email' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
      end

      allow(Mail).to receive(:find).and_return([email])
      imap_mailbox = double
      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)
      expect(imap_mailbox).to receive(:process).with(email, imap_email_channel).once

      described_class.perform_now(imap_email_channel)
    end
  end

  context 'when imap fetch existing emails' do
    it 'does not process the email' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
        message_id '<messageId@example.com>'
      end

      create(:message, message_type: 'incoming', source_id: email.message_id, account: account, inbox: imap_email_channel.inbox,
                       conversation: conversation)

      allow(Mail).to receive(:find).and_return([email])
      imap_mailbox = double
      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)
      expect(imap_mailbox).not_to receive(:process).with(email, imap_email_channel)

      described_class.perform_now(imap_email_channel)
    end
  end
end
