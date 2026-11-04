require 'rails_helper'

RSpec.describe 'Twilio::CallbacksController', type: :request do
  include Rails.application.routes.url_helpers

  describe 'POST /twilio/callback' do
    let(:params) do
      {
        'From' => '+1234567890',
        'To' => '+0987654321',
        'Body' => 'Test message',
        'AccountSid' => 'AC123',
        'SmsSid' => 'SM123',
        'ExternalUserId' => 'IN.2081978709342942',
        'ParentExternalUserId' => 'IN.ENT.9081726354',
        'ProfileUsername' => 'muhsin',
        'ReferralCtwaClid' => 'AfjyUDlaIoiweZDnlzmDTEaG',
        'ReferralSourceId' => '120237244350960485',
        'ReferralSourceUrl' => 'https://fb.me/4tBfhWhjr',
        'ReferralSourceType' => 'ad',
        'ReferralHeadline' => 'German citizenship lawyer',
        'ReferralBody' => 'Fast-track your German citizenship',
        'ReferralMediaId' => '',
        'ReferralNumMedia' => '0'
      }
    end

    it 'enqueues the Twilio events job' do
      expect do
        post twilio_callback_index_url, params: params
      end.to have_enqueued_job(Webhooks::TwilioEventsJob).with(params)
    end

    it 'returns no content status' do
      post twilio_callback_index_url, params: params
      expect(response).to have_http_status(:no_content)
    end

    it 'forwards the quoted message SID to the Twilio events job' do
      params['OriginalRepliedMessageSid'] = 'SMoriginal'

      expect do
        post twilio_callback_index_url, params: params
      end.to have_enqueued_job(Webhooks::TwilioEventsJob).with(params)
    end

    context 'when the request resolves to a channel' do
      let(:channel) { create(:channel_twilio_sms, :with_phone_number) }
      let(:params) do
        { 'From' => '+15550001111', 'To' => channel.phone_number, 'Body' => 'Hello', 'AccountSid' => channel.account_sid, 'SmsSid' => 'SM456' }
      end

      def signature_for(token)
        Twilio::Security::RequestValidator.new(token).build_signature_for(twilio_callback_index_url, params)
      end

      it 'accepts unsigned requests until the channel sends a valid signature' do
        expect do
          post twilio_callback_index_url, params: params
        end.to have_enqueued_job(Webhooks::TwilioEventsJob).with(params)
        expect(channel.reload.provider_config).not_to have_key('callback_signature_enforced')
      end

      it 'rejects unsigned requests once a valid signature has been seen' do
        post twilio_callback_index_url, params: params, headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        expect(response).to have_http_status(:no_content)
        expect(channel.reload.provider_config['callback_signature_enforced']).to be(true)

        expect do
          post twilio_callback_index_url, params: params.merge('Body' => 'Tampered'),
                                          headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        end.not_to have_enqueued_job(Webhooks::TwilioEventsJob)
        expect(response).to have_http_status(:forbidden)
      end

      it 'accepts a signature for the configured webhook URL when the request URL differs' do
        channel.update!(provider_config: { 'callback_signature_enforced' => true })

        expect do
          post '/twilio/callback', params: params, headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        end.to have_enqueued_job(Webhooks::TwilioEventsJob).with(params)
      end

      it 'verifies numbers in a messaging service pool against the phone number channel' do
        channel.update!(provider_config: { 'callback_signature_enforced' => true })
        params['MessagingServiceSid'] = "MG#{SecureRandom.hex(16)}"

        expect do
          post twilio_callback_index_url, params: params, headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        end.to have_enqueued_job(Webhooks::TwilioEventsJob).with(params)
      end

      it 'does not enforce signatures for API key channels without an account auth token' do
        channel.update!(api_key_sid: "SK#{SecureRandom.hex(16)}")

        post twilio_callback_index_url, params: params, headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        post twilio_callback_index_url, params: params

        expect(response).to have_http_status(:no_content)
        expect(channel.reload.provider_config).not_to have_key('callback_signature_enforced')
      end
    end
  end
end
