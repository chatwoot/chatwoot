require 'rails_helper'

RSpec.describe 'Twilio::CallbacksController', type: :request do
  include Rails.application.routes.url_helpers
  let(:twilio_service) { instance_double(Twilio::IncomingMessageService) }

  before do
    allow(Twilio::IncomingMessageService).to receive(:new).and_return(twilio_service)
    allow(twilio_service).to receive(:perform)
  end

  describe 'GET /twilio/callback' do
    it 'calls incoming message service' do
      post twilio_callback_index_url, params: {}
      expect(twilio_service).to have_received(:perform)
    end
  end
end
