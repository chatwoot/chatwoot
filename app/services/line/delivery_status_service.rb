class Line::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  DELIVERY_TAG_PREFIX = 'chatwoot-line-pnp-'.freeze

  def perform
    return if params[:events].blank?

    params[:events].each { |event| process_event(event) }
  end

  private

  def process_event(event)
    return unless event['type'] == 'delivery'

    message = find_message(event.dig('delivery', 'data').to_s)
    return unless message

    Messages::StatusUpdateService.new(message, 'delivered').perform
  end

  def find_message(delivery_tag)
    return if delivery_tag.blank?

    message_from_delivery_tag(delivery_tag) || message_from_template_params(delivery_tag)
  end

  def message_from_delivery_tag(delivery_tag)
    return unless delivery_tag.start_with?(DELIVERY_TAG_PREFIX)

    message_id = delivery_tag.delete_prefix(DELIVERY_TAG_PREFIX)
    return if message_id.blank?

    message = inbox.messages.find_by(id: message_id)
    return unless message&.additional_attributes&.dig('template_params', 'delivery_tag') == delivery_tag

    message
  end

  def message_from_template_params(delivery_tag)
    inbox.messages.find_by(
      "additional_attributes -> 'template_params' ->> 'delivery_tag' = ?",
      delivery_tag
    )
  end
end
