require 'rails_helper'

RSpec.describe 'Twilio::DeliveryStatusController', type: :request do
  include Rails.application.routes.url_helpers

  describe 'POST /twilio/delivery_status' do
    let(:account) { create(:account) }
    let(:twilio_channel) { create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123') }
    let(:params) do
      {
        'MessageSid' => 'SM123',
        'MessageStatus' => 'delivered',
        'AccountSid' => 'AC123',
        'From' => twilio_channel.phone_number
      }
    end

    def post_with_signature(url, params:, channel: twilio_channel)
      validator = Twilio::Security::RequestValidator.new(channel.auth_token)
      signature = validator.build_signature_for(url, params)
      post url, params: params, headers: { 'X-Twilio-Signature' => signature }
    end

    context 'with valid signature' do
      it 'enqueues the delivery status job' do
        url = twilio_delivery_status_index_url
        expect do
          post_with_signature(url, params: params)
        end.to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)
      end

      it 'returns no content status' do
        url = twilio_delivery_status_index_url
        post_with_signature(url, params: params)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with invalid signature' do
      it 'returns forbidden status' do
        post twilio_delivery_status_index_url, params: params, headers: { 'X-Twilio-Signature' => 'invalid' }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not enqueue the job' do
        expect do
          post twilio_delivery_status_index_url, params: params, headers: { 'X-Twilio-Signature' => 'invalid' }
        end.not_to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)
      end
    end

    context 'with missing signature header' do
      it 'returns forbidden status' do
        post twilio_delivery_status_index_url, params: params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when channel uses API key authentication' do
      let(:twilio_channel) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123', api_key_sid: 'SK123')
      end

      it 'skips signature validation and enqueues the job' do
        expect do
          post twilio_delivery_status_index_url, params: params
        end.to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)
      end
    end

    context 'with MessagingServiceSid lookup' do
      let(:twilio_channel) { create(:channel_twilio_sms, account: account, account_sid: 'AC123') }
      let(:params) do
        {
          'MessageSid' => 'SM123',
          'MessageStatus' => 'delivered',
          'AccountSid' => 'AC123',
          'MessagingServiceSid' => twilio_channel.messaging_service_sid
        }
      end

      it 'validates and enqueues the job' do
        url = twilio_delivery_status_index_url
        post_with_signature(url, params: params)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when To does not map to a channel but From does' do
      let(:params) do
        {
          'MessageSid' => 'SM123',
          'MessageStatus' => 'delivered',
          'AccountSid' => 'AC123',
          'To' => '+19999999999',
          'From' => twilio_channel.phone_number
        }
      end

      it 'falls back to From lookup and enqueues the delivery status job' do
        url = twilio_delivery_status_index_url

        expect do
          post_with_signature(url, params: params)
        end.to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when To maps to an API-key channel but From maps to a different channel' do
      let!(:api_key_channel) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123', api_key_sid: 'SK123')
      end
      let!(:from_channel) { create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'AC123') }
      let(:params) do
        {
          'MessageSid' => 'SM123',
          'MessageStatus' => 'delivered',
          'AccountSid' => 'AC123',
          'To' => api_key_channel.phone_number,
          'From' => from_channel.phone_number
        }
      end

      it 'rejects invalid signatures instead of skipping verification' do
        expect do
          post twilio_delivery_status_index_url, params: params, headers: { 'X-Twilio-Signature' => 'invalid' }
        end.not_to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
