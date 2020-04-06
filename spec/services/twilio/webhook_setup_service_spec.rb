require 'rails_helper'

describe Twilio::WebhookSetupService do
  include Rails.application.routes.url_helpers

  let(:channel_twilio_sms) { create(:channel_twilio_sms) }
  let(:twilio_client) { instance_double(::Twilio::REST::Client) }
  let(:phone_double) { instance_double('phone_double') }
  let(:phone_record_double) { instance_double('phone_record_double') }

  before do
    allow(::Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(phone_double).to receive(:update)
    allow(phone_record_double).to receive(:sid).and_return('1234')
  end

  describe '#perform' do
    it 'logs error if phone_number is not found' do
      allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
      allow(phone_double).to receive(:list).and_return([])

      described_class.new(inbox: channel_twilio_sms.inbox).perform

      expect(phone_double).not_to have_received(:update)
    end

    it 'update webhook_url if phone_number is found' do
      allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
      allow(phone_double).to receive(:list).and_return([phone_record_double])

      described_class.new(inbox: channel_twilio_sms.inbox).perform

      expect(phone_double).to have_received(:update).with(
        sms_method: 'POST',
        sms_url: twilio_callback_index_url
      )
    end

    it 'doesnot call update if TwilioError is thrown' do
      allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
      allow(phone_double).to receive(:list).and_raise(Twilio::REST::TwilioError)

      described_class.new(inbox: channel_twilio_sms.inbox).perform

      expect(phone_double).not_to have_received(:update)
    end
  end
end
