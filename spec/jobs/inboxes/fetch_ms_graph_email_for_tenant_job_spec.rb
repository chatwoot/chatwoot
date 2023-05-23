require 'rails_helper'

RSpec.describe Inboxes::FetchMsGraphEmailForTenantJob do
  include ActionMailbox::TestHelper

  let(:account) { create(:account) }
  let(:microsoft_imap_email_channel) do
    create(:channel_email, provider: 'microsoft', imap_enabled: true, imap_address: 'outlook.office365.com',
                           imap_port: 993, imap_login: 'imap@outlook.com', imap_password: 'password', account: account,
                           provider_config: { access_token: 'access_token' })
  end
  let(:ms_email_inbox) { create(:inbox, channel: microsoft_imap_email_channel, account: account) }
  let(:inbound_mail) { create_inbound_email_from_mail(from: 'testemail@gmail.com', to: 'imap@outlook.com', subject: 'Hello!') }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when imap fetch new emails for microsoft mailer' do
    before do
      stub_request(:get, 'https://graph.microsoft.com/v1.0/me/messages?$filter=receivedDateTime%20ge%202023-05-01T00:00:00Z%20and%20receivedDateTime%20le%202023-05-03T00:00:00Z&$select=id&$top=1000')
    end

    it 'fetch and process all emails' do
      with_modified_env AZURE_TENANT_ID: 'azure_tenant_id' do
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
  end
end
