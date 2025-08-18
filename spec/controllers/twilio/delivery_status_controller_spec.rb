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
  end
end
