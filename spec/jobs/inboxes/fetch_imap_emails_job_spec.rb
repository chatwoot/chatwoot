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

    context 'when the channel is regular imap' do
      it 'calls the imap fetch service' do
        fetch_service = double
        allow(Imap::FetchEmailService).to receive(:new).with(channel: imap_email_channel, interval: 1).and_return(fetch_service)
        allow(fetch_service).to receive(:perform).and_return([])

        described_class.perform_now(imap_email_channel)
        expect(fetch_service).to have_received(:perform)
      end

      it 'calls the imap fetch service with the correct interval' do
        fetch_service = double
        allow(Imap::FetchEmailService).to receive(:new).with(channel: imap_email_channel, interval: 4).and_return(fetch_service)
        allow(fetch_service).to receive(:perform).and_return([])

        described_class.perform_now(imap_email_channel, 4)
        expect(fetch_service).to have_received(:perform)
      end
    end
  end

    context 'when the channel is Microsoft' do
      it 'calls the Microsoft fetch service' do
        fetch_service = double
        allow(Imap::MicrosoftFetchEmailService).to receive(:new).with(channel: microsoft_imap_email_channel, interval: 1).and_return(fetch_service)
        allow(fetch_service).to receive(:perform).and_return([])

        described_class.perform_now(microsoft_imap_email_channel)
        expect(fetch_service).to have_received(:perform)
      end
    end

    context 'when IMAP OAuth errors out' do
      it 'marks the connection as requiring authorization' do
        error_response = double
        oauth_error = OAuth2::Error.new(error_response)

        allow(Imap::MicrosoftFetchEmailService).to receive(:new)
          .with(channel: microsoft_imap_email_channel, interval: 1)
          .and_raise(oauth_error)

        allow(Redis::Alfred).to receive(:incr)

        expect(Redis::Alfred).to receive(:incr)
          .with("AUTHORIZATION_ERROR_COUNT:channel_email:#{microsoft_imap_email_channel.id}")

        described_class.perform_now(microsoft_imap_email_channel)
      end
    end

    context 'when the fetch service returns the email objects' do
      let(:inbound_mail) {  create_inbound_email_from_fixture('welcome.eml').mail }
      let(:mailbox) { double }
      let(:exception_tracker) { double }
      let(:fetch_service) { double }

      before do
        allow(Imap::ImapMailbox).to receive(:new).and_return(mailbox)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)

        allow(Imap::FetchEmailService).to receive(:new).with(channel: imap_email_channel, interval: 1).and_return(fetch_service)
        allow(fetch_service).to receive(:perform).and_return([inbound_mail])
      end

      create(:message, message_type: 'incoming', source_id: email.message_id, account: account, inbox: imap_email_channel.inbox,
                       conversation: conversation)

        expect(Imap::FetchEmailService).to receive(:new).with(channel: imap_email_channel, interval: 1).and_return(fetch_service)
        expect(fetch_service).to receive(:perform).and_return([inbound_mail])
        expect(mailbox).to receive(:process).with(inbound_mail, imap_email_channel)

      described_class.perform_now(imap_email_channel)
    end
  end
end
