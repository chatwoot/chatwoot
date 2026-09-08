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
  end
end
