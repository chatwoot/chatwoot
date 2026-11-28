require 'rails_helper'

RSpec.describe Imap::FetchEmailService do
  include ActionMailbox::TestHelper
  let(:logger) { instance_double(ActiveSupport::Logger, info: true, error: true) }
  let(:account) { create(:account) }
  let(:imap_email_channel) { create(:channel_email, :imap_email, account: account) }
  let(:imap) { instance_double(Net::IMAP) }
  let(:eml_content_with_message_id) { Rails.root.join('spec/fixtures/files/only_text.eml').read }
  let(:eml_content_without_message_id) { eml_content_with_message_id.sub(/^Message-ID:.*\n/, '') }

  describe '#perform' do
    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(Net::IMAP).to receive(:new).with(
        imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
      ).and_return(imap)
      allow(imap).to receive(:authenticate).with(
        'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
      )
      allow(imap).to receive(:select).with('INBOX')
    end

    context 'when using CRAM-MD5 authentication' do
      let(:cram_md5_channel) { create(:channel_email, :imap_email, account: account, imap_authentication: 'cram-md5') }

      before do
        allow(Net::IMAP).to receive(:new).with(
          cram_md5_channel.imap_address, port: cram_md5_channel.imap_port, ssl: cram_md5_channel.imap_enable_ssl
        ).and_return(imap)
        allow(imap).to receive(:authenticate).with(
          'CRAM-MD5', cram_md5_channel.imap_login, cram_md5_channel.imap_password
        )
        allow(imap).to receive(:select).with('INBOX')
      end

      it 'uses CRAM-MD5 authentication' do
        travel_to '26.10.2020 10:00'.to_datetime do
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: cram_md5_channel).perform

          expect(imap).to have_received(:authenticate).with(
            'CRAM-MD5', cram_md5_channel.imap_login, cram_md5_channel.imap_password
          )
        end
      end
    end

    context 'when using LOGIN authentication' do
      let(:login_channel) { create(:channel_email, :imap_email, account: account, imap_authentication: 'login') }

      before do
        allow(Net::IMAP).to receive(:new).with(
          login_channel.imap_address, port: login_channel.imap_port, ssl: login_channel.imap_enable_ssl
        ).and_return(imap)
        allow(imap).to receive(:login).with(
          login_channel.imap_login, login_channel.imap_password
        )
        allow(imap).to receive(:select).with('INBOX')
      end

      it 'uses LOGIN authentication' do
        travel_to '26.10.2020 10:00'.to_datetime do
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: login_channel).perform

          expect(imap).to have_received(:login).with(
            login_channel.imap_login, login_channel.imap_password
          )
        end
      end
    end

    context 'when new emails are available in the mailbox' do
      it 'fetches the emails and returns the emails that are not present in the db' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)

          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with(1, 'BODY.PEEK[]')
          expect(logger).to have_received(:info).with("[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{imap_email_channel.email}, found 1.")
          expect(imap).to have_received(:logout)
        end
      end

      it 'fetches the emails and returns the mail objects that are not present in the db' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          create(:message, source_id: email_object.message_id, account: account, inbox: imap_email_channel.inbox)

          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)

          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 0
          expect(imap).to have_received(:search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).not_to have_received(:fetch).with(1, 'BODY.PEEK[]')
        end
      end

      it 'does not return recently deleted emails' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          redis_key = format(Redis::RedisKeys::IMAP_DELETED_MESSAGE,
                             inbox_id: imap_email_channel.inbox.id,
                             message_id_digest: Digest::SHA256.hexdigest(email_object.message_id))

          Imap::DeletedMessageTracker.new(inbox: imap_email_channel.inbox).record([email_object.message_id])
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(imap).not_to have_received(:fetch).with(1, 'RFC822')
        ensure
          Redis::Alfred.delete(redis_key) if redis_key
        end
      end

      it 'does not download emails that already failed processing the maximum number of times' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          redis_key = format(Redis::RedisKeys::IMAP_FAILED_MESSAGE,
                             inbox_id: imap_email_channel.inbox.id,
                             message_id_digest: Digest::SHA256.hexdigest(email_object.message_id))
          tracker = Imap::FailedMessageTracker.new(inbox: imap_email_channel.inbox)

          Imap::FailedMessageTracker::MAX_FAILURES.times { tracker.record_failure(email_object.message_id) }
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).not_to have_received(:fetch).with(1, 'BODY.PEEK[]')
        ensure
          Redis::Alfred.delete(redis_key) if redis_key
        end
      end

      it 'does not download a recently failed email that is still backing off' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          redis_key = format(Redis::RedisKeys::IMAP_FAILED_MESSAGE,
                             inbox_id: imap_email_channel.inbox.id,
                             message_id_digest: Digest::SHA256.hexdigest(email_object.message_id))
          tracker = Imap::FailedMessageTracker.new(inbox: imap_email_channel.inbox)

          tracker.record_failure(email_object.message_id)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(imap).not_to have_received(:fetch).with(1, 'BODY.PEEK[]')
        ensure
          Redis::Alfred.delete(redis_key) if redis_key
        end
      end

      it 'downloads a failed email again once the backoff has elapsed' do
        email_object = create_inbound_email_from_fixture('only_text.eml')
        tracker = Imap::FailedMessageTracker.new(inbox: imap_email_channel.inbox)

        travel_to '26.10.2020 09:54'.to_datetime do
          tracker.record_failure(email_object.message_id)
        end

        travel_to '26.10.2020 10:00'.to_datetime do
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)
          redis_key = format(Redis::RedisKeys::IMAP_FAILED_MESSAGE,
                             inbox_id: imap_email_channel.inbox.id,
                             message_id_digest: Digest::SHA256.hexdigest(email_object.message_id))

          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(imap).to have_received(:fetch).with(1, 'BODY.PEEK[]')
        ensure
          Redis::Alfred.delete(redis_key) if redis_key
        end
      end

      it 'reconnects and continues fetching when the connection drops mid run' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)
          reconnected_imap = instance_double(Net::IMAP)

          allow(Net::IMAP).to receive(:new).with(
            imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
          ).and_return(imap, *Array.new(5, reconnected_imap))
          allow(reconnected_imap).to receive(:authenticate).with(
            'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
          )
          allow(reconnected_imap).to receive(:select).with('INBOX')
          allow(reconnected_imap).to receive(:disconnect)
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
          allow(reconnected_imap).to receive(:search)
            .with(['HEADER', 'Message-ID', email_object.message_id]).and_return([1])
          allow(reconnected_imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(reconnected_imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:disconnect)
          expect(reconnected_imap).to have_received(:select).with('INBOX')
          expect(reconnected_imap).to have_received(:fetch).with(1, 'BODY.PEEK[]')
        end
      end

      it 'keeps emails fetched before and after a dropped connection' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          second_eml = eml_content_with_message_id.sub(/^Message-ID:.*$/, 'Message-ID: <second@example.com>')
          email_header_one = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          email_header_two = Net::IMAP::FetchData.new(2, 'BODY[HEADER]' => second_eml)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)
          imap_fetch_mail_two = Net::IMAP::FetchData.new(2, 'BODY[]' => second_eml)
          reconnected_imap = instance_double(Net::IMAP)
          fetch_one_calls = 0

          allow(Net::IMAP).to receive(:new).with(
            imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
          ).and_return(imap, *Array.new(5, reconnected_imap))
          allow(reconnected_imap).to receive(:authenticate).with(
            'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
          )
          allow(reconnected_imap).to receive(:select).with('INBOX')
          allow(reconnected_imap).to receive(:disconnect)
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1, 2])
          allow(imap).to receive(:fetch).with([1, 2], 'BODY.PEEK[HEADER]').and_return([email_header_one, email_header_two])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
          # The retried message and the queued second message both re-resolve
          # against the replacement session's renumbered mailbox.
          allow(reconnected_imap).to receive(:search) do |args|
            args.last.include?('second@example.com') ? [2] : [1]
          end
          allow(reconnected_imap).to receive(:fetch).with(1, 'BODY.PEEK[]') do
            fetch_one_calls += 1
            raise IOError, 'closed stream' if fetch_one_calls == 1

            [imap_fetch_mail]
          end
          allow(reconnected_imap).to receive(:fetch).with(2, 'BODY.PEEK[]').and_return([imap_fetch_mail_two])
          allow(reconnected_imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 2
          expect(result.map(&:message_id)).to include(email_object.message_id)
          expect(reconnected_imap).to have_received(:fetch).with(2, 'BODY.PEEK[]')
        end
      end

      it 'stops fetching once reconnect attempts are exhausted' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_headers = (1..4).map { |seq_no| Net::IMAP::FetchData.new(seq_no, 'BODY[HEADER]' => eml_content_with_message_id) }
          connection_attempts = 0

          allow(Net::IMAP).to receive(:new) do
            connection_attempts += 1
            raise IOError, 'closed stream' if connection_attempts > 1

            imap
          end
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:logout)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1, 2, 3, 4])
          allow(imap).to receive(:fetch).with([1, 2, 3, 4], 'BODY.PEEK[HEADER]').and_return(email_headers)
          allow(imap).to receive(:fetch).with(anything, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(connection_attempts).to eq(Imap::BaseFetchEmailService::MAX_RECONNECT_ATTEMPTS + 1)
          # No fetch is attempted once the connection is considered lost.
          expect(imap).to have_received(:fetch).with(anything, 'BODY.PEEK[]').exactly(3).times
        end
      end

      it 'stops reconnecting when every fetch keeps failing on the new connections' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_headers = (1..5).map { |seq_no| Net::IMAP::FetchData.new(seq_no, 'BODY[HEADER]' => eml_content_with_message_id) }
          reconnected_imaps = (1..3).map do |seq_no|
            instance_double(Net::IMAP).tap do |client|
              allow(client).to receive(:authenticate).with(
                'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
              )
              allow(client).to receive(:select).with('INBOX')
              allow(client).to receive(:disconnect)
              allow(client).to receive(:logout)
              allow(client).to receive(:search)
                .with(['HEADER', 'Message-ID', email_object.message_id]).and_return([seq_no])
              allow(client).to receive(:fetch).with(anything, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
            end
          end

          allow(Net::IMAP).to receive(:new).with(
            imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
          ).and_return(imap, *reconnected_imaps)
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1, 2, 3, 4, 5])
          allow(imap).to receive(:fetch).with([1, 2, 3, 4, 5], 'BODY.PEEK[HEADER]').and_return(email_headers)
          allow(imap).to receive(:fetch).with(anything, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(Net::IMAP).to have_received(:new).exactly(Imap::BaseFetchEmailService::MAX_RECONNECT_ATTEMPTS + 1).times
          expect(reconnected_imaps.last).not_to have_received(:disconnect)
        end
      end

      it 're-resolves the sequence number by message id after reconnecting' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(5, 'BODY[]' => eml_content_with_message_id)
          reconnected_imap = instance_double(Net::IMAP)

          allow(Net::IMAP).to receive(:new).with(
            imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
          ).and_return(imap, *Array.new(5, reconnected_imap))
          allow(reconnected_imap).to receive(:authenticate).with(
            'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
          )
          allow(reconnected_imap).to receive(:select).with('INBOX')
          allow(reconnected_imap).to receive(:disconnect)
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
          # Another client expunged earlier mail, so the message moved from seq 1 to seq 5.
          allow(reconnected_imap).to receive(:search)
            .with(['HEADER', 'Message-ID', email_object.message_id]).and_return([5])
          allow(reconnected_imap).to receive(:fetch).with(5, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(reconnected_imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(reconnected_imap).to have_received(:fetch).with(5, 'BODY.PEEK[]')
          expect(reconnected_imap).not_to have_received(:fetch).with(1, 'BODY.PEEK[]')
        end
      end

      it 'skips the message when it no longer exists after reconnecting' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          reconnected_imap = instance_double(Net::IMAP)

          allow(Net::IMAP).to receive(:new).with(
            imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
          ).and_return(imap, *Array.new(5, reconnected_imap))
          allow(reconnected_imap).to receive(:authenticate).with(
            'plain', imap_email_channel.imap_login, imap_email_channel.imap_password
          )
          allow(reconnected_imap).to receive(:select).with('INBOX')
          allow(reconnected_imap).to receive(:disconnect)
          allow(imap).to receive(:disconnect)
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
          allow(reconnected_imap).to receive(:search)
            .with(['HEADER', 'Message-ID', email_object.message_id]).and_return([])
          allow(reconnected_imap).to receive(:fetch)
          allow(reconnected_imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(reconnected_imap).not_to have_received(:fetch).with(anything, 'BODY.PEEK[]')
        end
      end

      it 'returns the emails fetched before the connection was lost' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_headers = (1..3).map { |seq_no| Net::IMAP::FetchData.new(seq_no, 'BODY[HEADER]' => eml_content_with_message_id) }
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)

          connection_attempts = 0
          allow(Net::IMAP).to receive(:new) do
            connection_attempts += 1
            raise IOError, 'closed stream' if connection_attempts > 1

            imap
          end
          allow(imap).to receive(:disconnect)
          # The client left behind by the failed reconnect is dead: logout raises IOError.
          allow(imap).to receive(:logout).and_raise(IOError, 'closed stream')
          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1, 2, 3])
          allow(imap).to receive(:fetch).with([1, 2, 3], 'BODY.PEEK[HEADER]').and_return(email_headers)
          allow(imap).to receive(:fetch).with(1, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:fetch).with(2, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')
          allow(imap).to receive(:fetch).with(3, 'BODY.PEEK[]').and_raise(IOError, 'closed stream')

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
        end
      end

      it 'does not count emails without message ids toward the sync limit' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          max_messages_per_sync = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          empty_message_id_seq_nums = (1..max_messages_per_sync).to_a
          valid_message_seq_num = max_messages_per_sync + 1
          empty_message_id_headers = empty_message_id_seq_nums.map do |seq_num|
            Net::IMAP::FetchData.new(seq_num, 'BODY[HEADER]' => eml_content_without_message_id)
          end
          valid_email_header = Net::IMAP::FetchData.new(valid_message_seq_num, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(valid_message_seq_num, 'BODY[]' => eml_content_with_message_id)

          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return(empty_message_id_seq_nums + [valid_message_seq_num])
          allow(imap).to receive(:fetch).with(empty_message_id_seq_nums, 'BODY.PEEK[HEADER]').and_return(empty_message_id_headers)
          allow(imap).to receive(:fetch).with([valid_message_seq_num], 'BODY.PEEK[HEADER]').and_return([valid_email_header])
          allow(imap).to receive(:fetch).with(valid_message_seq_num, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:fetch).with(empty_message_id_seq_nums, 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with([valid_message_seq_num], 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with(valid_message_seq_num, 'BODY.PEEK[]')
        end
      end
    end
  end
end
