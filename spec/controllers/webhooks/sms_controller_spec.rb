require 'rails_helper'

RSpec.describe 'Webhooks::SmsController', type: :request do
  describe 'POST /webhooks/sms/{:phone_number}' do
    it 'call the sms events job with the params' do
      allow(Webhooks::SmsEventsJob).to receive(:perform_later)
      expect(Webhooks::SmsEventsJob).to receive(:perform_later)
      post '/webhooks/sms/123221321', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
