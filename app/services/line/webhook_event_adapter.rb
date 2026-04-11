class Line::WebhookEventAdapter
  class << self
    def normalize(events)
      {
        'events' => events.filter_map { |event| normalize_event(event) }
      }
    end

    private

    def normalize_event(event)
      case event.type
      when 'message'
        normalize_message_event(event)
      when 'delivery'
        normalize_delivery_event(event)
      end
    end

    def normalize_message_event(event)
      return unless event.source.respond_to?(:type) && event.source.type == 'user'

      {
        'type' => event.type,
        'source' => { 'userId' => event.source.user_id },
        'message' => normalize_message(event.message)
      }
    end

    def normalize_delivery_event(event)
      return unless event.respond_to?(:delivery) && event.delivery.respond_to?(:data)

      {
        'type' => event.type,
        'webhookEventId' => event.webhook_event_id,
        'timestamp' => event.timestamp,
        'deliveryContext' => {
          'isRedelivery' => event.delivery_context.is_redelivery
        },
        'delivery' => { 'data' => event.delivery.data }
      }
    end

    def normalize_message(message)
      payload = {
        'id' => message.id.to_s,
        'type' => message.type
      }

      payload['text'] = message.text if message.respond_to?(:text) && message.text.present?
      payload['stickerId'] = message.sticker_id if message.respond_to?(:sticker_id) && message.sticker_id.present?
      payload['fileName'] = message.file_name if message.respond_to?(:file_name) && message.file_name.present?
      payload
    end
  end
end
