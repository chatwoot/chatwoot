require 'rails_helper'

RSpec.describe Imap::FetchEmailService do
  include ActionMailbox::TestHelper
  let(:logger) { instance_double(ActiveSupport::Logger, info: true, error: true) }
  let(:account) { create(:account) }
  let(:imap_email_channel) { create(:channel_email, :imap_email, account: account) }
  let(:imap) { instance_double(Net::IMAP) }
  let(:eml_content_with_message_id) { Rails.root.join('spec/fixtures/files/only_text.eml').read }
  let(:eml_content_without_message_id) { eml_content_with_message_id.sub(/^Message-ID:.*\n/, '') }
  let(:uid_validity) { 987_654 }

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
      allow(imap).to receive(:responses).with('UIDVALIDITY').and_yield([uid_validity])
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
          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
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
          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
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
          email_header = Net::IMAP::FetchData.new(1, 'UID' => 1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'BODY[]' => eml_content_with_message_id)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:uid_fetch).with([1], %w[UID BODY.PEEK[HEADER]]).and_return([email_header])
          allow(imap).to receive(:uid_fetch).with(1, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:uid_fetch).with([1], %w[UID BODY.PEEK[HEADER]])
          expect(imap).to have_received(:uid_fetch).with(1, 'BODY.PEEK[]')
          expect(logger).to have_received(:info)
            .with("[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{imap_email_channel.email}, found 1 (full sync).")
          expect(imap).to have_received(:logout)
        end
      end

      it 'fetches the emails and returns the mail objects that are not present in the db' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          create(:message, source_id: email_object.message_id, account: account, inbox: imap_email_channel.inbox)

          email_header = Net::IMAP::FetchData.new(1, 'UID' => 1, 'BODY[HEADER]' => eml_content_with_message_id)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:uid_fetch).with([1], %w[UID BODY.PEEK[HEADER]]).and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 0
          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:uid_fetch).with([1], %w[UID BODY.PEEK[HEADER]])
          expect(imap).not_to have_received(:uid_fetch).with(1, 'BODY.PEEK[]')
        end
      end

      it 'does not return recently deleted emails' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'UID' => 1, 'BODY[HEADER]' => eml_content_with_message_id)
          redis_key = format(Redis::RedisKeys::IMAP_DELETED_MESSAGE,
                             inbox_id: imap_email_channel.inbox.id,
                             message_id_digest: Digest::SHA256.hexdigest(email_object.message_id))

          Imap::DeletedMessageTracker.new(inbox: imap_email_channel.inbox).record([email_object.message_id])
          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:uid_fetch).with([1], %w[UID BODY.PEEK[HEADER]]).and_return([email_header])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(imap).not_to have_received(:uid_fetch).with(1, 'RFC822')
        ensure
          Redis::Alfred.delete(redis_key) if redis_key
        end
      end

      it 'does not count emails without message ids toward the sync limit' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          max_messages_per_sync = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          empty_message_id_seq_nums = (1..max_messages_per_sync).to_a
          valid_message_seq_num = max_messages_per_sync + 1
          empty_message_id_headers = empty_message_id_seq_nums.map do |seq_num|
            Net::IMAP::FetchData.new(seq_num, 'UID' => seq_num, 'BODY[HEADER]' => eml_content_without_message_id)
          end
          valid_email_header = Net::IMAP::FetchData.new(valid_message_seq_num, 'UID' => valid_message_seq_num,
                                                                               'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(valid_message_seq_num, 'BODY[]' => eml_content_with_message_id)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return(empty_message_id_seq_nums + [valid_message_seq_num])
          allow(imap).to receive(:uid_fetch).with(empty_message_id_seq_nums, %w[UID BODY.PEEK[HEADER]]).and_return(empty_message_id_headers)
          allow(imap).to receive(:uid_fetch).with([valid_message_seq_num], %w[UID BODY.PEEK[HEADER]]).and_return([valid_email_header])
          allow(imap).to receive(:uid_fetch).with(valid_message_seq_num, 'BODY.PEEK[]').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:uid_fetch).with(empty_message_id_seq_nums, %w[UID BODY.PEEK[HEADER]])
          expect(imap).to have_received(:uid_fetch).with([valid_message_seq_num], %w[UID BODY.PEEK[HEADER]])
          expect(imap).to have_received(:uid_fetch).with(valid_message_seq_num, 'BODY.PEEK[]')
        end
      end
    end

    context 'when a UID cursor is already recorded' do
      let(:cursor) { Imap::UidCursor.new(inbox: imap_email_channel.inbox) }
      let(:mailbox) do
        Digest::SHA256.hexdigest(
          [imap_email_channel.imap_address, imap_email_channel.imap_port, imap_email_channel.imap_login].join(':')
        )
      end

      after { cursor.clear }

      it 'asks only for UIDs above the cursor instead of re-listing the window' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity, last_uid: 41, swept_at: Time.current, mailbox: mailbox)

          allow(imap).to receive(:uid_search).with(['UID', Net::IMAP::SequenceSet.new('42:*')]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(imap).to have_received(:uid_search).with(['UID', Net::IMAP::SequenceSet.new('42:*')])
          expect(imap).not_to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
        end
      end

      # `N:*` is not "UIDs at or above N": the server answers with its highest UID even
      # when that UID is below N, so an idle mailbox would hand back the same message on
      # every run and re-fetch its header forever.
      it 'discards the trailing UID the server returns below the requested range' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity, last_uid: 41, swept_at: Time.current, mailbox: mailbox)

          allow(imap).to receive(:uid_search).with(['UID', Net::IMAP::SequenceSet.new('42:*')]).and_return([41])
          # Stubbed so the negative expectation below can be asserted at all; the point
          # is that the filter keeps it from ever being called.
          allow(imap).to receive(:uid_fetch)
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result).to be_empty
          expect(imap).not_to have_received(:uid_fetch)
        end
      end

      it 'falls back to the date sweep when the mailbox reports a new UIDVALIDITY' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity - 1, last_uid: 41, swept_at: Time.current, mailbox: mailbox)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
        end
      end

      it 'falls back to the date sweep once the full sweep interval has elapsed' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity, last_uid: 41, mailbox: mailbox,
                       swept_at: Time.current - Imap::BaseFetchEmailService::FULL_SWEEP_INTERVAL - 1)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
        end
      end

      it 'keeps the cursor when a run finds nothing, so the next run resumes from it' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity, last_uid: 41, swept_at: Time.current, mailbox: mailbox)

          allow(imap).to receive(:uid_search).with(['UID', Net::IMAP::SequenceSet.new('42:*')]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(cursor.read).to include(uid_validity: uid_validity, last_uid: 41)
        end
      end

      # A cursor that claims UIDs the run never looked at hides them from every later
      # incremental poll, and only the hourly sweep would find them, 500 at a time.
      it 'does not advance the cursor past UIDs the sync limit left uninspected' do
        travel_to '26.10.2020 10:00'.to_datetime do
          max = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          seen = (1..max).to_a
          unseen = [max + 1, max + 2]
          headers = seen.map do |uid|
            Net::IMAP::FetchData.new(uid, 'UID' => uid, 'BODY[HEADER]' => eml_content_with_message_id)
          end

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return(seen + unseen)
          allow(imap).to receive(:uid_fetch).with(seen, %w[UID BODY.PEEK[HEADER]]).and_return(headers)
          allow(imap).to receive(:uid_fetch).with(unseen, %w[UID BODY.PEEK[HEADER]]).and_return([])
          allow(imap).to receive(:uid_fetch).with(anything, 'BODY.PEEK[]').and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(cursor.read[:last_uid]).to eq max
        end
      end

      # The cursor never moves backwards, so a capped sweep can leave pending UIDs below it,
      # invisible to every incremental poll. Closing the sweep window anyway turns the
      # backlog into 500 messages an hour, and a big enough one ages out of the SINCE window.
      it 'does not close the sweep window when the cap cut the full sweep short' do
        travel_to '26.10.2020 10:00'.to_datetime do
          max = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          varrido_em = 2.hours.ago.to_i
          cursor.write(uid_validity: uid_validity, last_uid: 9_999, swept_at: varrido_em, mailbox: mailbox)

          baixos = (1..max).to_a
          headers = baixos.map do |uid|
            Net::IMAP::FetchData.new(uid, 'UID' => uid, 'BODY[HEADER]' => eml_content_with_message_id)
          end

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return(baixos + [max + 1, max + 2])
          allow(imap).to receive(:uid_fetch).with(baixos, %w[UID BODY.PEEK[HEADER]]).and_return(headers)
          allow(imap).to receive(:uid_fetch).with(anything, 'BODY.PEEK[]').and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(cursor.read[:swept_at]).to eq varrido_em
        end
      end

      # RFC 3501 does not require SEARCH to answer in ascending order. Slicing the reply as
      # it came would put high UIDs in the first batch, hit the cap there, and park the
      # cursor above UIDs no run ever inspected.
      it 'inspects the lowest UIDs first when SEARCH answers out of order' do
        travel_to '26.10.2020 10:00'.to_datetime do
          max = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          baixos = (1..max).to_a
          altos = [max + 1, max + 2]
          headers = baixos.map do |uid|
            Net::IMAP::FetchData.new(uid, 'UID' => uid, 'BODY[HEADER]' => eml_content_with_message_id)
          end

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return(altos + baixos)
          allow(imap).to receive(:uid_fetch).with(baixos, %w[UID BODY.PEEK[HEADER]]).and_return(headers)
          allow(imap).to receive(:uid_fetch).with(anything, 'BODY.PEEK[]').and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(cursor.read[:last_uid]).to eq max
          expect(imap).not_to have_received(:uid_fetch).with(altos, %w[UID BODY.PEEK[HEADER]])
        end
      end

      # A slice that ends exactly on the cap used to cost one more header FETCH of up to
      # 500 UIDs that the run had already decided not to read.
      it 'does not fetch another header batch once the sync limit is already reached' do
        travel_to '26.10.2020 10:00'.to_datetime do
          max = Imap::BaseFetchEmailService::MAX_MESSAGES_PER_SYNC
          primeiro = (1..max).to_a
          segundo = [max + 1]
          headers = primeiro.map do |uid|
            Net::IMAP::FetchData.new(uid, 'UID' => uid, 'BODY[HEADER]' => eml_content_with_message_id)
          end

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return(primeiro + segundo)
          allow(imap).to receive(:uid_fetch).with(primeiro, %w[UID BODY.PEEK[HEADER]]).and_return(headers)
          allow(imap).to receive(:uid_fetch).with(anything, 'BODY.PEEK[]').and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(imap).not_to have_received(:uid_fetch).with(segundo, %w[UID BODY.PEEK[HEADER]])
        end
      end

      it 'drops the previous high-water mark when UIDVALIDITY changed' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity - 1, last_uid: 9_999, swept_at: Time.current, mailbox: mailbox)

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([7])
          allow(imap).to receive(:uid_fetch).with([7], %w[UID BODY.PEEK[HEADER]])
                                            .and_return([Net::IMAP::FetchData.new(7, 'UID' => 7,
                                                                                     'BODY[HEADER]' => eml_content_with_message_id)])
          allow(imap).to receive(:uid_fetch).with(7, 'BODY.PEEK[]').and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(cursor.read).to include(uid_validity: uid_validity, last_uid: 7)
        end
      end

      # UIDVALIDITY is per mailbox, not global, so it cannot tell two accounts apart on
      # its own. Repointing the channel must not inherit the old account's position.
      it 'ignores a cursor recorded against a different mailbox' do
        travel_to '26.10.2020 10:00'.to_datetime do
          cursor.write(uid_validity: uid_validity, last_uid: 41, swept_at: Time.current, mailbox: 'outra-caixa')

          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          described_class.new(channel: imap_email_channel).perform

          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
        end
      end
    end

    context 'when the mailbox does not report a UIDVALIDITY' do
      it 'sweeps by date instead of trusting a cursor it cannot validate' do
        travel_to '26.10.2020 10:00'.to_datetime do
          allow(imap).to receive(:responses).with('UIDVALIDITY').and_yield(nil)
          allow(imap).to receive(:uid_search).with(%w[SINCE 25-Oct-2020]).and_return([])
          allow(imap).to receive(:logout)

          expect { described_class.new(channel: imap_email_channel).perform }.not_to raise_error
          expect(imap).to have_received(:uid_search).with(%w[SINCE 25-Oct-2020])
        end
      end
    end
  end
end
