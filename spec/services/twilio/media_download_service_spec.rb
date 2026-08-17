require 'rails_helper'

RSpec.describe Twilio::MediaDownloadService do
  let(:account) { create(:account) }
  let(:channel) do
    create(
      :channel_twilio_sms,
      account: account,
      account_sid: 'ACxxx',
      inbox: create(:inbox, account: account, greeting_enabled: false)
    )
  end
  let(:message_sid) { "MM#{'1' * 32}" }
  let(:media_sid) { "ME#{'2' * 32}" }
  let(:media_url) do
    "https://api.twilio.com/2010-04-01/Accounts/#{channel.account_sid}/Messages/#{message_sid}/Media/#{media_sid}"
  end
  let(:auth_credentials) { [channel.account_sid, channel.auth_token] }
  let(:service) do
    described_class.new(channel: channel, media_url: media_url, message_sid: message_sid, media_index: 0)
  end

  before do
    allow(service).to receive(:sleep)
  end

  it 'downloads the media once with authentication when it is immediately available' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
    allow(Rails.logger).to receive(:info)

    file = service.perform

    expect(file.content_type).to eq('image/png')
    expect(service).not_to have_received(:sleep)
    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.once
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=success attempt=1')
    )
  end

  it 'waits and retries an authenticated 404 with authentication' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(
        { status: 404 },
        { status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' } }
      )

    file = service.perform

    expect(file.content_type).to eq('image/png')
    expect(service).to have_received(:sleep).with(1).once
    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.twice
    expect(a_request(:get, media_url).with { |request| request.headers['Authorization'].blank? }).not_to have_been_made
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
    expect(a_request(:get, media_url).with { |request| request.headers['Authorization'].blank? }).not_to have_been_made
    expect(Rails.logger).to have_received(:info).with(
      include('[TWILIO] Media download outcome=skipped attempt=3', 'error=Down::NotFound')
    )
  end

  it 'does not retry a non-404 Twilio error without authentication' do
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_raise(Down::Error.new('Download error'))

    expect(service.perform).to be_nil

    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.once
    expect(a_request(:get, media_url).with { |request| request.headers['Authorization'].blank? }).not_to have_been_made
  end

  it 'does not follow redirects for authenticated media downloads' do
    redirect_url = 'https://redirect.example/media.jpg'
    stub_request(:get, media_url)
      .with(basic_auth: auth_credentials)
      .to_return(status: 302, headers: { 'Location' => redirect_url })
    stub_request(:get, redirect_url)
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })

    expect(service.perform).to be_nil

    expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).to have_been_made.once
    expect(a_request(:get, redirect_url)).not_to have_been_made
  end

  it 'uses the initial channel credentials for every retry' do
    initial_credentials = auth_credentials
    changed_credentials = ['ACchanged', 'changed-token']
    stub_request(:get, media_url)
      .with(basic_auth: initial_credentials)
      .to_return(
        { status: 404 },
        { status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' } }
      )
    allow(service).to receive(:sleep) do
      channel.assign_attributes(account_sid: changed_credentials.first, auth_token: changed_credentials.last)
    end

    expect(service.perform.content_type).to eq('image/png')

    expect(a_request(:get, media_url).with(basic_auth: initial_credentials)).to have_been_made.twice
    expect(a_request(:get, media_url).with(basic_auth: changed_credentials)).not_to have_been_made
  end

  context 'when media comes from a non-Twilio URL' do
    let(:media_url) { 'https://example.com/media.jpg' }

    it 'downloads without Twilio credentials' do
      stub_request(:get, media_url)
        .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })

      expect(service.perform.content_type).to eq('image/jpeg')

      expect(service).not_to have_received(:sleep)
      expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).not_to have_been_made
      expect(a_request(:get, media_url).with { |request| request.headers['Authorization'].blank? }).to have_been_made.once
    end

    it 'retries a failed public download without credentials' do
      stub_request(:get, media_url)
        .to_return(
          { status: 503 },
          { status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' } }
        )

      expect(service.perform.content_type).to eq('image/jpeg')

      expect(a_request(:get, media_url).with(basic_auth: auth_credentials)).not_to have_been_made
      expect(a_request(:get, media_url).with { |request| request.headers['Authorization'].blank? }).to have_been_made.twice
    end
  end

  it 'does not send credentials to a plaintext Twilio URL' do
    plaintext_url = media_url.sub('https://', 'http://')
    stub_request(:get, plaintext_url)
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })

    plaintext_service = described_class.new(
      channel: channel, media_url: plaintext_url, message_sid: message_sid, media_index: 0
    )

    expect(plaintext_service.perform.content_type).to eq('image/png')
    expect(a_request(:get, plaintext_url).with(basic_auth: auth_credentials)).not_to have_been_made
  end

  context 'when API key authentication is configured' do
    let(:api_key_sid) { "SK#{'3' * 32}" }
    let(:api_key_secret) { 'api-key-secret' }
    let(:api_key_credentials) { [api_key_sid, api_key_secret] }
    let(:channel) do
      super().tap do |twilio_channel|
        twilio_channel.update!(api_key_sid: api_key_sid, auth_token: api_key_secret)
      end
    end

    it 'uses the API key credentials for every transient 404 attempt' do
      stub_request(:get, media_url)
        .with(basic_auth: api_key_credentials)
        .to_return(
          { status: 404 },
          { status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' } }
        )

      expect(service.perform.content_type).to eq('image/png')

      expect(a_request(:get, media_url).with(basic_auth: api_key_credentials)).to have_been_made.twice
    end
  end
end
