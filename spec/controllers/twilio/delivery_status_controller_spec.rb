require 'rails_helper'

RSpec.describe 'Twilio::DeliveryStatusController', type: :request do
  include Rails.application.routes.url_helpers

  describe 'POST /twilio/delivery_status' do
    let(:params) do
      {
        'MessageSid' => 'SM123',
        'MessageStatus' => 'delivered',
        'AccountSid' => 'AC123'
      }
    end

    it 'enqueues the Twilio delivery status job' do
      expect do
        post twilio_delivery_status_index_url, params: params
      end.to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob).with(params)
    end

    it 'returns no content status' do
      post twilio_delivery_status_index_url, params: params
      expect(response).to have_http_status(:no_content)
    end

    context 'when the request resolves to a channel' do
      let(:channel) { create(:channel_twilio_sms, :with_phone_number) }
      let(:params) do
        { 'MessageSid' => 'SM456', 'MessageStatus' => 'delivered', 'AccountSid' => channel.account_sid, 'From' => channel.phone_number }
      end

      def signature_for(token)
        Twilio::Security::RequestValidator.new(token).build_signature_for(twilio_delivery_status_index_url, params)
      end

      it 'accepts unsigned requests until the channel sends a valid signature' do
        expect do
          post twilio_delivery_status_index_url, params: params
        end.to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob).with(params)
      end

      it 'rejects invalid signatures once a valid signature has been seen' do
        post twilio_delivery_status_index_url, params: params, headers: { 'X-Twilio-Signature' => signature_for(channel.auth_token) }
        expect(channel.reload.provider_config['delivery_status_signature_enforced']).to be(true)

        expect do
          post twilio_delivery_status_index_url, params: params, headers: { 'X-Twilio-Signature' => signature_for('wrong-token') }
        end.not_to have_enqueued_job(Webhooks::TwilioDeliveryStatusJob)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
