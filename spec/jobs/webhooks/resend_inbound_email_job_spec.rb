require 'rails_helper'

RSpec.describe Webhooks::ResendInboundEmailJob do
  let(:raw_url) { 'https://inbound.resend.test/receiving/raw/em_123?Signature=abc' }
  let(:raw_email) { file_fixture('support_1.eml').read }

  before do
    stub_request(:get, 'https://api.resend.com/emails/receiving/em_123?html_format=cid')
      .with(headers: { 'Authorization' => 'Bearer re_full_access' })
      .to_return(status: 200, body: { id: 'em_123', raw: { download_url: raw_url } }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, raw_url).to_return(status: 200, body: raw_email)
  end

  it 'hands the original message to Action Mailbox once, even when the webhook is redelivered' do
    with_modified_env RESEND_INBOUND_API_KEY: 're_full_access' do
      expect do
        2.times { described_class.perform_now('em_123') }
      end.to change(ActionMailbox::InboundEmail, :count).by(1)
    end

    expect(ActionMailbox::InboundEmail.last.source).to eq(raw_email)
  end

  it 'raises when the download does not answer in time, so the job is retried and stores nothing' do
    stub_request(:get, raw_url).to_timeout

    with_modified_env RESEND_INBOUND_API_KEY: 're_full_access' do
      expect { described_class.perform_now('em_123') }.to raise_error(Net::OpenTimeout)
    end

    expect(ActionMailbox::InboundEmail.count).to eq(0)
    expect(a_request(:get, raw_url)).to have_been_made.once
  end

  it 'raises when the receiving API refuses the key, so the job is retried' do
    stub_request(:get, 'https://api.resend.com/emails/receiving/em_123?html_format=cid').to_return(status: 401)

    with_modified_env RESEND_INBOUND_API_KEY: 're_sending_only' do
      expect { described_class.perform_now('em_123') }.to raise_error(HTTParty::ResponseError)
    end
  end
end
