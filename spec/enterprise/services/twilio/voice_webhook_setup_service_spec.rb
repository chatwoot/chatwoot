# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twilio::VoiceWebhookSetupService do
  let(:account_sid) { 'ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
  let(:auth_token) { 'auth_token_123' }
  let(:api_key_sid) { 'SKaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
  let(:api_key_secret) { 'api_key_secret_123' }
  let(:phone_number) { '+15551230001' }
  let(:frontend_url) { 'https://app.chatwoot.test' }

  let(:channel) do
    build(:channel_voice, phone_number: phone_number, provider_config: {
            account_sid: account_sid,
            auth_token: auth_token,
            api_key_sid: api_key_sid,
            api_key_secret: api_key_secret
          })
  end

  let(:twilio_base_url) { "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}" }
  let(:incoming_numbers_url) { "#{twilio_base_url}/IncomingPhoneNumbers.json" }
  let(:applications_url) { "#{twilio_base_url}/Applications.json" }
  let(:phone_number_sid) { 'PN123' }
  let(:phone_number_url) { "#{twilio_base_url}/IncomingPhoneNumbers/#{phone_number_sid}.json" }

  before do
    # Token validation using Account SID + Auth Token
    stub_request(:get, /#{Regexp.escape(incoming_numbers_url)}.*/)
      .with(basic_auth: [account_sid, auth_token])
      .to_return(status: 200,
                 body: { incoming_phone_numbers: [], meta: { key: 'incoming_phone_numbers' } }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    # Number lookup using API Key SID/Secret
    stub_request(:get, /#{Regexp.escape(incoming_numbers_url)}.*/)
      .with(basic_auth: [api_key_sid, api_key_secret])
      .to_return(status: 200,
                 body: { incoming_phone_numbers: [{ sid: phone_number_sid }], meta: { key: 'incoming_phone_numbers' } }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    # TwiML App create (voice only)
    stub_request(:post, applications_url)
      .with(basic_auth: [api_key_sid, api_key_secret])
      .to_return(status: 201,
                 body: { sid: 'AP123' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    # Incoming Phone Number webhook update
    stub_request(:post, phone_number_url)
      .with(basic_auth: [api_key_sid, api_key_secret])
      .to_return(status: 200,
                 body: { sid: phone_number_sid }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'creates a TwiML App and configures number webhooks with correct URLs' do
    with_modified_env FRONTEND_URL: frontend_url do
      service = described_class.new(channel: channel)
      sid = service.perform

      expect(sid).to eq('AP123')

      expected_voice_url = channel.voice_call_webhook_url
      expected_status_url = channel.voice_status_webhook_url

      # Assert TwiML App creation body includes voice URL and POST method
      expect(
        a_request(:post, applications_url)
          .with(body: hash_including('VoiceUrl' => expected_voice_url, 'VoiceMethod' => 'POST'))
      ).to have_been_made

      # Assert number webhook update body includes both URLs and POST methods
      expect(
        a_request(:post, phone_number_url)
          .with(
            body: hash_including(
              'VoiceUrl' => expected_voice_url,
              'VoiceMethod' => 'POST',
              'StatusCallback' => expected_status_url,
              'StatusCallbackMethod' => 'POST'
            )
          )
      ).to have_been_made
    end
  end
end
