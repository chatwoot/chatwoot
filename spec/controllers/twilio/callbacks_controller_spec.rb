require 'rails_helper'

RSpec.describe 'Twilio::CallbacksController', type: :request do
  include Rails.application.routes.url_helpers

  describe 'POST /twilio/callback' do
    let(:account) { create(:account) }
    let(:twilio_channel) { create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123') }
    let(:params) do
      {
        'From' => '+1234567890',
        'To' => twilio_channel.phone_number,
        'Body' => 'Test message',
        'AccountSid' => 'AC123',
        'SmsSid' => 'SM123'
      }
    end

    def post_with_signature(url, params:)
      validator = Twilio::Security::RequestValidator.new(twilio_channel.auth_token)
      signature = validator.build_signature_for(url, params)
      post url, params: params, headers: { 'X-Twilio-Signature' => signature }
    end

    context 'with valid signature' do
      it 'enqueues the Twilio events job' do
        url = twilio_callback_index_url
        expect do
          post_with_signature(url, params: params)
        end.to have_enqueued_job(Webhooks::TwilioEventsJob)
      end

      it 'returns no content status' do
        url = twilio_callback_index_url
        post_with_signature(url, params: params)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with invalid signature' do
      it 'returns forbidden status' do
        post twilio_callback_index_url, params: params, headers: { 'X-Twilio-Signature' => 'invalid' }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not enqueue the job' do
        expect do
          post twilio_callback_index_url, params: params, headers: { 'X-Twilio-Signature' => 'invalid' }
        end.not_to have_enqueued_job(Webhooks::TwilioEventsJob)
      end
    end

    context 'with missing signature header' do
      it 'returns forbidden status' do
        post twilio_callback_index_url, params: params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when channel is not found' do
      it 'returns forbidden status' do
        post twilio_callback_index_url, params: params.merge('AccountSid' => 'UNKNOWN', 'To' => '+0000000000')
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when channel uses API key authentication' do
      let(:twilio_channel) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123', api_key_sid: 'SK123')
      end

      it 'skips signature validation and enqueues the job' do
        expect do
          post twilio_callback_index_url, params: params
        end.to have_enqueued_job(Webhooks::TwilioEventsJob)
      end
    end

    context 'when behind a reverse proxy with X-Forwarded-Proto' do
      it 'validates signature against the HTTPS URL' do
        http_url = twilio_callback_index_url
        https_url = http_url.sub('http://', 'https://')
        validator = Twilio::Security::RequestValidator.new(twilio_channel.auth_token)
        signature = validator.build_signature_for(https_url, params)
        post http_url, params: params, headers: {
          'X-Twilio-Signature' => signature,
          'X-Forwarded-Proto' => 'https'
        }
        expect(response).to have_http_status(:no_content)
      end

      it 'validates signature when forwarded proto is a comma-separated chain' do
        http_url = twilio_callback_index_url
        https_url = http_url.sub('http://', 'https://')
        validator = Twilio::Security::RequestValidator.new(twilio_channel.auth_token)
        signature = validator.build_signature_for(https_url, params)
        post http_url, params: params, headers: {
          'X-Twilio-Signature' => signature,
          'X-Forwarded-Proto' => 'https,http'
        }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with MessagingServiceSid lookup' do
      let(:twilio_channel) { create(:channel_twilio_sms, account: account, account_sid: 'AC123') }
      let(:params) do
        {
          'From' => '+1234567890',
          'Body' => 'Test message',
          'AccountSid' => 'AC123',
          'SmsSid' => 'SM123',
          'MessagingServiceSid' => twilio_channel.messaging_service_sid
        }
      end

      it 'validates and enqueues the job' do
        url = twilio_callback_index_url
        post_with_signature(url, params: params)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when MessagingServiceSid is present but does not match a channel' do
      let(:params) do
        {
          'From' => '+1234567890',
          'To' => twilio_channel.phone_number,
          'Body' => 'Test message',
          'AccountSid' => 'AC123',
          'SmsSid' => 'SM123',
          'MessagingServiceSid' => 'MG_UNKNOWN'
        }
      end

      it 'falls back to account and phone number lookup' do
        url = twilio_callback_index_url

        expect do
          post_with_signature(url, params: params)
        end.to have_enqueued_job(Webhooks::TwilioEventsJob)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
