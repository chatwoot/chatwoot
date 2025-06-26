require 'rails_helper'

RSpec.describe Webhooks::TwilioDeliveryStatusJob do
  subject(:job) { described_class.perform_later(params) }

  let(:params) do
    {
      'MessageSid' => 'SM123',
      'MessageStatus' => 'delivered',
      'AccountSid' => 'AC123'
    }
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('low')
  end

  it 'calls the Twilio::DeliveryStatusService' do
    service = double
    expect(Twilio::DeliveryStatusService).to receive(:new).with(params: params).and_return(service)
    expect(service).to receive(:perform)
    described_class.new.perform(params)
  end
end
