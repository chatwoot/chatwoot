require 'rails_helper'

RSpec.describe Line::WebhookEventAdapter do
  describe '.normalize' do
    it 'normalizes a user text message event' do
      source = Struct.new(:type, :user_id).new('user', 'U123')
      message = Struct.new(:id, :type, :text, :sticker_id, :file_name).new('mid-1', 'text', 'hello', nil, nil)
      event = Struct.new(:type, :source, :message).new('message', source, message)

      expect(described_class.normalize([event])).to eq(
        'events' => [
          {
            'type' => 'message',
            'source' => { 'userId' => 'U123' },
            'message' => { 'id' => 'mid-1', 'type' => 'text', 'text' => 'hello' }
          }
        ]
      )
    end

    it 'skips non-user sources' do
      source = Struct.new(:type, :group_id, :user_id).new('group', 'C123', 'U123')
      message = Struct.new(:id, :type, :text).new('mid-1', 'text', 'hello')
      event = Struct.new(:type, :source, :message).new('message', source, message)

      expect(described_class.normalize([event])).to eq('events' => [])
    end

    it 'normalizes a delivery completion event' do
      delivery_context = Struct.new(:is_redelivery).new(true)
      delivery = Struct.new(:data).new('chatwoot-line-pnp-123')
      event = Struct.new(:type, :webhook_event_id, :timestamp, :delivery_context, :delivery).new(
        'delivery',
        'evt-123',
        1_700_000_000_000,
        delivery_context,
        delivery
      )

      expect(described_class.normalize([event])).to eq(
        'events' => [
          {
            'type' => 'delivery',
            'webhookEventId' => 'evt-123',
            'timestamp' => 1_700_000_000_000,
            'deliveryContext' => { 'isRedelivery' => true },
            'delivery' => { 'data' => 'chatwoot-line-pnp-123' }
          }
        ]
      )
    end
  end
end
