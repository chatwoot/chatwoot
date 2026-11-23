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
      let(:inbound_mail) { instance_double(Mail::Message, message_id: 'message-id') }
      let(:second_inbound_mail) { instance_double(Mail::Message, message_id: 'second-message-id') }
      let(:mailbox) { double }
      let(:exception_tracker) { double }
      let(:fetch_service) { double }
      let(:failure_tracker) { instance_double(Imap::FailedMessageTracker, skip?: false, record_failure: 1) }

      before do
        allow(Imap::ImapMailbox).to receive(:new).and_return(mailbox)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
        allow(Imap::FailedMessageTracker).to receive(:new).with(inbox: imap_email_channel.inbox).and_return(failure_tracker)

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

      it 'marks the email as failed when processing times out' do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        described_class.perform_now(imap_email_channel)

        expect(failure_tracker).to have_received(:record_failure).with('message-id')
      end

      it 'continues processing remaining emails when one email fails' do
        allow(fetch_service).to receive(:perform).and_return([inbound_mail, second_inbound_mail])
        allow(mailbox).to receive(:process).with(inbound_mail, imap_email_channel).and_raise(StandardError)
        allow(mailbox).to receive(:process).with(second_inbound_mail, imap_email_channel)
        allow(exception_tracker).to receive(:capture_exception)

        described_class.perform_now(imap_email_channel)

        expect(mailbox).to have_received(:process).with(second_inbound_mail, imap_email_channel)
      end

      it 'skips emails that have failed multiple times recently' do
        allow(failure_tracker).to receive(:skip?).with('message-id').and_return(true)

        expect(mailbox).not_to receive(:process)

        described_class.perform_now(imap_email_channel)
      end

      it 'logs errors if mailbox returns errors' do
        allow(mailbox).to receive(:process).and_raise(StandardError)

        expect(exception_tracker).to receive(:capture_exception)

        described_class.perform_now(imap_email_channel)
      end

      context 'when processing retries are exhausted' do
        let(:inbound_mail) do
          instance_double(Mail::Message, message_id: 'message-id', attachments: [double])
        end
        let(:process_calls) { [] }

        before do
          allow(failure_tracker).to receive(:record_failure).with('message-id')
                                                            .and_return(Imap::FailedMessageTracker::MAX_FAILURES)
          # without_attachments! mutates the mail; its return value is not the mail itself.
          allow(inbound_mail).to receive(:without_attachments!).and_return(instance_double(Mail::PartsList))
          allow(inbound_mail).to receive(:parts).and_return([])
          allow(exception_tracker).to receive(:capture_exception)

          # The first mailbox run raises; a later degraded import succeeds.
          allow(mailbox).to receive(:process).with(inbound_mail, imap_email_channel) do
            process_calls << true
            raise StandardError if process_calls.length == 1
          end
        end

        it 'imports the email without attachments' do
          described_class.perform_now(imap_email_channel)

          expect(inbound_mail).to have_received(:without_attachments!)
          expect(mailbox).to have_received(:process).with(inbound_mail, imap_email_channel).twice
        end

        it 'enqueues an activity message when the degraded import succeeds' do
          allow(mailbox).to receive(:process).with(inbound_mail, imap_email_channel) do
            process_calls << true
            raise StandardError if process_calls.length == 1

            create(:message, source_id: 'message-id', account: account,
                             inbox: imap_email_channel.inbox,
                             conversation: create(:conversation, account: account, inbox: imap_email_channel.inbox))
          end

          expect(Conversations::ActivityMessageJob).to receive(:perform_later)
            .with(anything, hash_including(message_type: :activity))

          described_class.perform_now(imap_email_channel)
        end

        it 'does not claim a degraded import when the email was already imported' do
          create(:message, source_id: 'message-id', account: account,
                           inbox: imap_email_channel.inbox,
                           conversation: create(:conversation, account: account, inbox: imap_email_channel.inbox))

          expect(Conversations::ActivityMessageJob).not_to receive(:perform_later)

          described_class.perform_now(imap_email_channel)

          expect(inbound_mail).not_to have_received(:without_attachments!)
        end

        it 'strips attachments nested in multipart parts from a real email' do
          real_mail = Mail.read(Rails.root.join('spec/fixtures/files/in_reply_to.eml'))

          expect(real_mail.attachments).not_to be_empty

          described_class.new.send(:strip_attachments!, real_mail)

          expect(real_mail.attachments).to be_empty
        end

        it 'does not retry when the email has no attachments' do
          allow(inbound_mail).to receive(:attachments).and_return([])

          described_class.perform_now(imap_email_channel)

          expect(inbound_mail).not_to have_received(:without_attachments!)
          expect(mailbox).to have_received(:process).with(inbound_mail, imap_email_channel).once
        end
      end
    end
  end
end
