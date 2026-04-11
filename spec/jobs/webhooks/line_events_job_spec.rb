require 'rails_helper'

RSpec.describe Webhooks::LineEventsJob do
  let!(:line_channel) { create(:channel_line) }
  let(:parsed_event) { Struct.new(:type).new('message') }
  let(:delivery_event) { Struct.new(:type).new('delivery') }
  let(:normalized_payload) do
    {
      'events' => [
        { 'type' => 'message', 'message' => { 'id' => 'mid-1', 'type' => 'text', 'text' => 'hello' }, 'source' => { 'userId' => 'U123' } },
        { 'type' => 'delivery', 'delivery' => { 'data' => 'chatwoot-line-pnp-123' } }
      ]
    }
  end

  it 'parses the webhook once and forwards normalized events to both services' do
    inbound_service = instance_double(Line::IncomingMessageService, perform: true)
    delivery_service = instance_double(Line::DeliveryStatusService, perform: true)
    webhook_parser = instance_double(Line::Bot::V2::WebhookParser)

    allow(Channel::Line).to receive(:find_by).with(line_channel_id: line_channel.line_channel_id).and_return(line_channel)
    allow(line_channel).to receive(:webhook_parser).and_return(webhook_parser)
    expect(webhook_parser).to receive(:parse).once.with(body: '{"events":[]}', signature: 'sig').and_return([parsed_event, delivery_event])
    expect(Line::WebhookEventAdapter).to receive(:normalize).once.with([parsed_event, delivery_event]).and_return(normalized_payload)
    allow(Line::IncomingMessageService).to receive(:new).and_return(inbound_service)
    allow(Line::DeliveryStatusService).to receive(:new).and_return(delivery_service)

    described_class.perform_now(
      params: { 'line_channel_id' => line_channel.line_channel_id },
      post_body: '{"events":[]}',
      signature: 'sig'
    )

    expect(Line::IncomingMessageService).to have_received(:new).with(
      inbox: line_channel.inbox,
      params: normalized_payload.with_indifferent_access
    )
    expect(Line::DeliveryStatusService).to have_received(:new).with(
      inbox: line_channel.inbox,
      params: normalized_payload.with_indifferent_access
    )
  end
end
