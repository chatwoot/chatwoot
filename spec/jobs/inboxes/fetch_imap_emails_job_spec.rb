require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailsJob do
  include ActiveJob::TestHelper
  include ActionMailbox::TestHelper

  let(:account) { create(:account) }
  let(:imap_email_channel) { create(:channel_email, :imap_email, account: account) }
  let(:channel_with_imap_disabled) { create(:channel_email, :imap_email, imap_enabled: false, account: account) }
  let(:microsoft_imap_email_channel) { create(:channel_email, :microsoft_email) }

  describe '#perform' do
    it 'enqueues the job' do
      expect do
        described_class.perform_later(imap_email_channel, 1)
      end.to have_enqueued_job(described_class).on_queue('scheduled_jobs')
    end

    context 'when IMAP is disabled' do
      it 'does not fetch emails' do
        expect(Imap::FetchEmailService).not_to receive(:new)
        expect(Imap::MicrosoftFetchEmailService).not_to receive(:new)
        described_class.perform_now(channel_with_imap_disabled)
      end
    end

    context 'when IMAP reauthorization is required' do
      it 'does not fetch emails' do
        10.times do
          imap_email_channel.authorization_error!
        end

        expect(Imap::FetchEmailService).not_to receive(:new)
        # Confirm the imap_enabled flag is true to avoid false positives.
        expect(imap_email_channel.imap_enabled?).to be true

        described_class.perform_now(imap_email_channel)
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

      it 'calls the mailbox to create emails' do
        allow(mailbox).to receive(:process)

        expect(Imap::FetchEmailService).to receive(:new).with(channel: imap_email_channel, interval: 1).and_return(fetch_service)
        expect(fetch_service).to receive(:perform).and_return([inbound_mail])
        expect(mailbox).to receive(:process).with(inbound_mail, imap_email_channel)

        described_class.perform_now(imap_email_channel)
      end

      it 'logs errors if mailbox returns errors' do
        allow(mailbox).to receive(:process).and_raise(StandardError)

        expect(exception_tracker).to receive(:capture_exception)

        described_class.perform_now(imap_email_channel)
      end
    end
  end
end
