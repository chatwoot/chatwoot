require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailsJob, type: :job do
  let(:account) { create(:account) }
  let(:imap_email_channel) do
    create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com', imap_port: 993, imap_email: 'imap@gmail.com',
                           imap_password: 'password', imap_inbox_synced_at: Time.now.utc - 10, account: account)
  end
  let(:email_inbox) { create(:inbox, channel: imap_email_channel, account: account) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when imap fetch latest 10 emails' do
    it 'check for the new emails' do
      mail_date = Time.now.utc
      mail = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
        date mail_date
      end

      allow(Mail).to receive(:find).and_return([mail])
      imap_mailbox = double
      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)
      expect(imap_mailbox).to receive(:process).with(mail, imap_email_channel).once

      described_class.perform_now(imap_email_channel)

      expect(imap_email_channel.reload.imap_inbox_synced_at).to be > mail_date
    end
  end
end
