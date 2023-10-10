require 'rails_helper'

RSpec.describe 'Twilio::DeliveryController', type: :request do
  include Rails.application.routes.url_helpers
  let(:twilio_service) { instance_double(Twilio::MessageDeliveryService) }

  before do
    allow(Twilio::MessageDeliveryService).to receive(:new).and_return(twilio_service)
    allow(twilio_service).to receive(:perform)
  end

  describe 'POST /twilio/delivery' do
    it 'calls incoming message service' do
      post twilio_delivery_index_url, params: {}
      expect(twilio_service).to have_received(:perform)
    end
  end
end
