require 'rails_helper'

RSpec.describe Imap::MicrosoftFetchEmailService do
  include ActionMailbox::TestHelper
  let(:logger) { instance_double(ActiveSupport::Logger, info: true, error: true) }
  let(:account) { create(:account) }
  let(:microsoft_channel) { create(:channel_email, :microsoft_email, account: account) }
  let(:imap) { instance_double(Net::IMAP) }
  let(:refresh_token_service) { double }
  let(:eml_content_with_message_id) { Rails.root.join('spec/fixtures/files/only_text.eml').read }

  describe '#perform' do
    before do
      allow(Rails).to receive(:logger).and_return(logger)

      allow(Net::IMAP).to receive(:new).with(
        microsoft_channel.imap_address, port: microsoft_channel.imap_port, ssl: true
      ).and_return(imap)
      allow(imap).to receive(:authenticate).with(
        'XOAUTH2', microsoft_channel.imap_login, microsoft_channel.provider_config['access_token']
      )
      allow(imap).to receive(:select).with('INBOX')

      allow(Microsoft::RefreshOauthTokenService).to receive(:new).and_return(refresh_token_service)
      allow(refresh_token_service).to receive(:access_token).and_return(microsoft_channel.provider_config['access_token'])
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

          result = described_class.new(channel: microsoft_channel).perform

          expect(refresh_token_service).to have_received(:access_token)

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:search).with(%w[SINCE 25-Oct-2020])
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with(1, 'RFC822')
          expect(logger).to have_received(:info).with("[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{microsoft_channel.email}, found 1.")
        end
      end
    end

    context 'when the interval is passed during an IMAP Sync' do
      it 'fetches the emails based on the interval specified in the job' do
        travel_to '26.10.2020 10:00'.to_datetime do
          email_object = create_inbound_email_from_fixture('only_text.eml')
          email_header = Net::IMAP::FetchData.new(1, 'BODY[HEADER]' => eml_content_with_message_id)
          imap_fetch_mail = Net::IMAP::FetchData.new(1, 'RFC822' => eml_content_with_message_id)

          allow(imap).to receive(:search).with(%w[SINCE 18-Oct-2020]).and_return([1])
          allow(imap).to receive(:fetch).with([1], 'BODY.PEEK[HEADER]').and_return([email_header])
          allow(imap).to receive(:fetch).with(1, 'RFC822').and_return([imap_fetch_mail])
          allow(imap).to receive(:logout)

          result = described_class.new(channel: microsoft_channel, interval: 8).perform

          expect(refresh_token_service).to have_received(:access_token)

          expect(result.length).to eq 1
          expect(result[0].message_id).to eq email_object.message_id
          expect(imap).to have_received(:search).with(%w[SINCE 18-Oct-2020])
          expect(imap).to have_received(:fetch).with([1], 'BODY.PEEK[HEADER]')
          expect(imap).to have_received(:fetch).with(1, 'RFC822')
          expect(logger).to have_received(:info).with("[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{microsoft_channel.email}, found 1.")
        end
      end
    end
  end
end
