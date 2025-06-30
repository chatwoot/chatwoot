class Zalo::Messages::LocationService < Zalo::Messages::BaseService
  private

  def message_content
    nil
  end

  def content_type
    :text
  end

  def process_attachments
    return unless need_process_attachments?

    @message.attachments.find_or_initialize_by(
      account_id: account.id,
      file_type: :location,
      fallback_title: fallback_title,
      coordinates_lat: coordinates_lat,
      coordinates_long: coordinates_long
    )
  rescue StandardError => e
    Rails.logger.error("Failed to process attachments: #{e.message}")
    raise e
  end

  def need_process_attachments?
    message_attachments.present? && @message.attachments.empty?
  end

  def fallback_title
    params.dig(:message, :text).presence
  end

  def coordinates_lat
    params.dig(:message, :attachments, 0, :payload, :coordinates, :latitude)
  end

  def coordinates_long
    params.dig(:message, :attachments, 0, :payload, :coordinates, :longitude)
  end
end
