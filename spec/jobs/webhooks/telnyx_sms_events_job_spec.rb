require 'rails_helper'

RSpec.describe Webhooks::TelnyxSmsEventsJob do
  let(:channel) { create(:channel_telnyx_sms) }

  it 'passes received messages to the incoming message service' do
    payload = {
      'id' => 'telnyx-message-id',
      'from' => { 'phone_number' => '+15555550123' },
      'to' => [{ 'phone_number' => channel.phone_number }],
      'text' => 'Hello',
      'media' => [{ 'url' => 'https://example.com/image.png' }]
    }
    params = { 'data' => { 'event_type' => 'message.received', 'payload' => payload } }
    service = instance_double(Sms::IncomingMessageService, perform: nil)

    expect(Sms::IncomingMessageService).to receive(:new).with(
      inbox: channel.inbox,
      params: {
        id: 'telnyx-message-id',
        from: '+15555550123',
        to: channel.phone_number,
        text: 'Hello',
        media: ['https://example.com/image.png']
      }.with_indifferent_access
    ).and_return(service)

    described_class.perform_now(params)
  end

  it 'passes finalized messages to the delivery status service' do
    payload = {
      'id' => 'telnyx-message-id',
      'to' => [{ 'phone_number' => channel.phone_number, 'status' => 'delivered' }]
    }
    params = { 'data' => { 'event_type' => 'message.finalized', 'payload' => payload } }
    service = instance_double(Sms::TelnyxDeliveryStatusService, perform: nil)

    expect(Sms::TelnyxDeliveryStatusService).to receive(:new).with(
      inbox: channel.inbox,
      params: payload.with_indifferent_access
    ).and_return(service)

    described_class.perform_now(params)
  end
end
