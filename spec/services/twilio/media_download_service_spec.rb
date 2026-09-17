require 'rails_helper'

RSpec.describe Twilio::MediaDownloadService do
  let(:account) { create(:account) }
  let(:account_sid) { "AC#{'1' * 32}" }
  let(:channel) do
    create(
      :channel_twilio_sms,
      account: account,
      account_sid: account_sid,
      inbox: create(:inbox, account: account, greeting_enabled: false)
    )
  end
  let(:message_sid) { "MM#{'2' * 32}" }
  let(:media_sid) { "ME#{'3' * 32}" }
  let(:media_url) do
    "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages/#{message_sid}/Media/#{media_sid}"
  end
  let(:cdn_url) { "https://mms.twiliocdn.com/#{media_sid}?Expires=123&Signature=signed" }
  let(:auth_credentials) { [account_sid, channel.auth_token] }
  let(:service) do
    described_class.new(
      channel: channel,
      media_url: media_url,
      message_sid: message_sid,
      media_index: 0,
      retry_delays: [1, 3]
    )
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.twilio.com').and_return(['54.172.60.0'])
    allow(Resolv).to receive(:getaddresses).with('mms.twiliocdn.com').and_return(['18.65.3.1'])
    allow(service).to receive(:sleep)
  end

  it 'follows the Twilio CDN redirect without forwarding channel credentials' do
    redirected_authorization = nil
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(status: 302, headers: { 'Location' => cdn_url })
    stub_request(:get, cdn_url)
      .with do |request|
        redirected_authorization = request.headers['Authorization']
        true
      end
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })

    file = service.perform

    expect(file.read).to eq('image data')
    expect(file.content_type).to eq('image/jpeg')
    expect(redirected_authorization).to be_nil
    file.close
  end

  it 'uses only IPv4 addresses for Twilio media redirects' do
    ipv4_address = IPAddr.new('18.65.3.1')
    ipv6_address = IPAddr.new('2600:9000:2652:5000:1:47:fb00:93a1')
    allow(SsrfFilter::DEFAULT_RESOLVER).to receive(:call).with('mms.twiliocdn.com').and_return([ipv4_address, ipv6_address])

    expect(described_class::IPV4_RESOLVER.call('mms.twiliocdn.com')).to eq([ipv4_address])
  end

  it 'retries a transient authenticated 404 and follows the successful redirect' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(
        { status: 404 },
        { status: 302, headers: { 'Location' => cdn_url } }
      )
    stub_request(:get, cdn_url)
      .with { |request| request.headers['Authorization'].blank? }
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })
    allow(Rails.logger).to receive(:info)

    file = service.perform

    expect(file.read).to eq('image data')
    expect(service).to have_received(:sleep).with(1).once
    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.twice
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=retrying attempt=2', 'error=SafeFetch::HttpError', 'status=404')
    )
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=success attempt=2')
    )
    file.close
  end

  it 'stops after bounded authenticated 404 retries' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(status: 404)
    allow(Rails.logger).to receive(:info)

    expect(service.perform).to be_nil

    expect(service).to have_received(:sleep).with(1).once
    expect(service).to have_received(:sleep).with(3).once
    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.times(3)
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=skipped attempt=3', 'error=SafeFetch::HttpError', 'status=404')
    )
  end

  it 'stops immediately on a non-404 Twilio response' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(status: 500)
    allow(Rails.logger).to receive(:info)

    expect(service.perform).to be_nil

    expect(service).not_to have_received(:sleep)
    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.once
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=skipped attempt=1', 'status=500')
    )
  end

  it 'uses API key credentials for the Twilio request' do
    channel.update!(api_key_sid: "SK#{'4' * 32}", auth_token: 'api-key-secret')
    api_key_credentials = [channel.api_key_sid, channel.auth_token]
    stub_request(:get, media_url)
      .with(basic_auth: api_key_credentials)
      .to_return(status: 302, headers: { 'Location' => cdn_url })
    stub_request(:get, cdn_url)
      .with { |request| request.headers['Authorization'].blank? }
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })
    api_key_service = described_class.new(
      channel: channel,
      media_url: media_url,
      message_sid: message_sid,
      media_index: 0,
      retry_delays: [1, 3]
    )

    file = api_key_service.perform

    expect(file.read).to eq('image data')
    expect(a_request(:get, media_url).with(basic_auth: api_key_credentials)).to have_been_made.once
    file.close
  end

  it 'downloads non-Twilio media without channel credentials' do
    public_url = 'https://chatwoot-assets.local/sample.png'
    allow(Resolv).to receive(:getaddresses).with('chatwoot-assets.local').and_return(['93.184.216.34'])
    stub_request(:get, public_url)
      .with { |request| request.headers['Authorization'].blank? }
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })

    public_service = described_class.new(
      channel: channel,
      media_url: public_url,
      message_sid: message_sid,
      media_index: 0,
      retry_delays: [1, 3]
    )

    file = public_service.perform

    expect(file.read).to eq('image data')
    expect(a_request(:get, public_url).with { |request| request.headers['Authorization'].blank? }).to have_been_made.once
    file.close
  end
end
