require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailsJob do
  include ActionMailbox::TestHelper

  let(:account) { create(:account) }
  let(:imap_email_channel) do
    create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com', imap_port: 993, imap_login: 'imap@gmail.com',
                           imap_password: 'password', imap_inbox_synced_at: Time.now.utc, account: account)
  end
  let(:microsoft_imap_email_channel) do
    create(:channel_email, provider: 'microsoft', imap_enabled: true, imap_address: 'outlook.office365.com',
                           imap_port: 993, imap_login: 'imap@outlook.com', imap_password: 'password', account: account,
                           provider_config: { access_token: 'access_token' })
  end
  let(:ms_email_inbox) { create(:inbox, channel: microsoft_imap_email_channel, account: account) }
  let!(:conversation) { create(:conversation, inbox: imap_email_channel.inbox, account: account) }
  let(:inbound_mail) { create_inbound_email_from_mail(from: 'testemail@gmail.com', to: 'imap@outlook.com', subject: 'Hello!') }
  let(:inbound_mail_with_no_date) { create_inbound_email_from_fixture('mail_with_no_date.eml') }
  let(:inbound_mail_with_attachments) { create_inbound_email_from_fixture('multiple_attachments.eml') }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  context 'when imap fetch new emails' do
    it 'process the email' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
      end

      imap_fetch_mail = Net::IMAP::FetchData.new
      imap_fetch_mail.attr = { seqno: 1, RFC822: email }.with_indifferent_access

      imap = double

      allow(Net::IMAP).to receive(:new).and_return(imap)
      allow(imap).to receive(:authenticate)
      allow(imap).to receive(:select)
      allow(imap).to receive(:search).and_return([1])
      allow(imap).to receive(:fetch).and_return([imap_fetch_mail])

      read_mail = Mail::Message.new(date: DateTime.now, from: 'testemail@gmail.com', to: 'imap@outlook.com', subject: 'Hello!')
      allow(Mail).to receive(:read_from_string).and_return(inbound_mail.mail)

      imap_mailbox = double

      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)
      expect(imap_mailbox).to receive(:process).with(read_mail, imap_email_channel).once

      described_class.perform_now(imap_email_channel)
    end

    it 'process the email with no date' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
      end

      imap_fetch_mail = Net::IMAP::FetchData.new
      imap_fetch_mail.attr = { seqno: 1, RFC822: email }.with_indifferent_access

      imap = double

      allow(Net::IMAP).to receive(:new).and_return(imap)
      allow(imap).to receive(:authenticate)
      allow(imap).to receive(:select)
      allow(imap).to receive(:search).and_return([1])
      allow(imap).to receive(:fetch).and_return([imap_fetch_mail])

      allow(Mail).to receive(:read_from_string).and_return(inbound_mail_with_no_date.mail)

      imap_mailbox = double

      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)
      expect(imap_mailbox).to receive(:process).with(inbound_mail_with_no_date.mail, imap_email_channel).once

      described_class.perform_now(imap_email_channel)
    end
  end

  context 'when imap fetch new emails with more than 15 attachments' do
    it 'process the email' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
      end

      imap_fetch_mail = Net::IMAP::FetchData.new
      imap_fetch_mail.attr = { seqno: 1, RFC822: email }.with_indifferent_access

      imap = double

      allow(Net::IMAP).to receive(:new).and_return(imap)
      allow(imap).to receive(:authenticate)
      allow(imap).to receive(:select)
      allow(imap).to receive(:search).and_return([1])
      allow(imap).to receive(:fetch).and_return([imap_fetch_mail])

      inbound_mail_with_attachments.mail.date = DateTime.now

      allow(Mail).to receive(:read_from_string).and_return(inbound_mail_with_attachments.mail)

      imap_mailbox = Imap::ImapMailbox.new

      allow(Imap::ImapMailbox).to receive(:new).and_return(imap_mailbox)

      described_class.perform_now(imap_email_channel)
      expect(Message.last.attachments.count).to eq(15)
    end
  end

  context 'when imap fetch new emails for microsoft mailer' do
    it 'fetch and process all emails' do
      email = Mail.new do
        to 'test@outlook.com'
        from 'test@gmail.com'
        subject :test.to_s
        body 'hello'
      end
      imap_fetch_mail = Net::IMAP::FetchData.new
      imap_fetch_mail.attr = { RFC822: email }.with_indifferent_access

      ms_imap = double

      allow(Net::IMAP).to receive(:new).and_return(ms_imap)
      allow(ms_imap).to receive(:authenticate)
      allow(ms_imap).to receive(:select)
      allow(ms_imap).to receive(:search).and_return([1])
      allow(ms_imap).to receive(:fetch).and_return([imap_fetch_mail])
      allow(Mail).to receive(:read_from_string).and_return(inbound_mail)

      ms_imap_email_inbox = double

      allow(Imap::ImapMailbox).to receive(:new).and_return(ms_imap_email_inbox)
      expect(ms_imap_email_inbox).to receive(:process).with(inbound_mail, microsoft_imap_email_channel).once

      described_class.perform_now(microsoft_imap_email_channel)
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
