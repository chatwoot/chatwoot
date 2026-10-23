class Whatsapp::LocationMessageService
  class Error < StandardError; end

  pattr_initialize [:conversation!, :sender!, :params!]

  def perform
    raise Error, I18n.t('errors.whatsapp.location_message.outside_messaging_window') unless conversation.can_reply?

    location = params[:location_id].present? ? saved_location : current_location

    Messages::MessageBuilder.new(sender, conversation, content: content_for(location), content_attributes: { whatsapp_location: location }).perform
  end

  private

  def saved_location
    raise Error, I18n.t('errors.whatsapp.location_message.single_mode_required') if params[:latitude].present? || params[:longitude].present?

    found = conversation.inbox.channel.locations.find { |location| location['id'] == params[:location_id] }
    raise Error, I18n.t('errors.whatsapp.location_message.not_found') if found.nil?

    found.slice('id', 'name', 'address', 'latitude', 'longitude')
  end

  def current_location
    { 'latitude' => coordinate(params[:latitude], 90), 'longitude' => coordinate(params[:longitude], 180) }
  end

  def coordinate(value, limit)
    number = Float(value, exception: false)
    raise Error, I18n.t('errors.whatsapp.location_message.invalid_coordinates') unless number&.between?(-limit, limit)

    number
  end

  def content_for(location)
    return [location['name'], location['address']].join("\n") if location['name']

    "#{I18n.t('errors.whatsapp.location_message.current_location')}\n#{location['latitude']}, #{location['longitude']}"
  end
end
