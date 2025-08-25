require 'rails_helper'

RSpec.describe Imap::FetchEmailService do
  include ActionMailbox::TestHelper
  let(:logger) { instance_double(ActiveSupport::Logger, info: true, error: true) }
  let(:account) { create(:account) }
  let(:imap_email_channel) { create(:channel_email, :imap_email, account: account) }
  let(:imap) { instance_double(Net::IMAP) }
  let(:eml_content_with_message_id) { Rails.root.join('spec/fixtures/files/only_text.eml').read }

  describe '#perform' do
    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(Net::IMAP).to receive(:new).with(
        imap_email_channel.imap_address, port: imap_email_channel.imap_port, ssl: imap_email_channel.imap_enable_ssl
      ).and_return(imap)
      allow(imap).to receive(:authenticate).with(
        'PLAIN', imap_email_channel.imap_login, imap_email_channel.imap_password
      )
      allow(imap).to receive(:select).with('INBOX')
    end

    context 'when using CRAM-MD5 authentication' do
      let(:cram_md5_channel) { create(:channel_email, :imap_email, account: account, imap_authentication: 'CRAM-MD5') }

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
        allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([])
        allow(imap).to receive(:logout)

        described_class.new(channel: cram_md5_channel).perform

        expect(imap).to have_received(:authenticate).with(
          'CRAM-MD5', cram_md5_channel.imap_login, cram_md5_channel.imap_password
        )
      end
    end

    context 'when using LOGIN authentication' do
      let(:login_channel) { create(:channel_email, :imap_email, account: account, imap_authentication: 'LOGIN') }

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
        allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([])
        allow(imap).to receive(:logout)

        described_class.new(channel: login_channel).perform

        expect(imap).to have_received(:login).with(
          login_channel.imap_login, login_channel.imap_password
        )
      end
    end

    context 'when new emails are available in the mailbox' do
      it 'fetches the emails and returns the emails that are not present in the db' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'RFC822' => eml_content_with_message_id)

          allow(imap).to receive(:search).with(%w[SINCE 25-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'RFC822').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: imap_email_channel).perform

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with(1, 'RFC822')
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
          expect(imap).not_to have_received(:fetch).with(1, 'RFC822')
        end
      end
    end
  end
end
