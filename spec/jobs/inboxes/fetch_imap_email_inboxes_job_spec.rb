require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailInboxesJob, type: :job do
  let(:account) { create(:account) }
  let(:imap_email_channel) do
    create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com', imap_port: 993, imap_login: 'imap@gmail.com',
                           imap_password: 'password', account: account)
  end
  let(:microsoft_imap_email_channel) do
    create(:channel_email, provider: 'microsoft', imap_enabled: true, imap_address: 'outlook.office365.com',
                           imap_port: 993, imap_login: 'imap@outlook.com', imap_password: 'password', account: account)
  end
  let(:email_inbox) { create(:inbox, channel: imap_email_channel, account: account) }
  let(:ms_email_inbox) { create(:inbox, channel: microsoft_imap_email_channel, account: account) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'fetch all the email channels' do
      imap_email_inboxes = double
      allow(imap_email_inboxes).to receive(:all).and_return([email_inbox])
      allow(Inbox).to receive(:where).and_return(imap_email_inboxes)

      expect(Inboxes::FetchImapEmailsJob).to receive(:perform_later).with(imap_email_channel).once

      described_class.perform_now
    end
  end

  context 'when called for microsoft mailer' do
    it 'fetch all the email channels' do
      ms_imap_email_inboxes = double
      allow(ms_imap_email_inboxes).to receive(:all).and_return([ms_email_inbox])
      allow(Inbox).to receive(:where).and_return(ms_imap_email_inboxes)

      expect(Inboxes::FetchImapEmailsJob).to receive(:perform_later).with(imap_email_channel).once

      described_class.perform_now
    end
  end
end
