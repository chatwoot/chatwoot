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
      coordinates_long: coordinates_long,
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


# Processing Zalo webhook payload: {"event_name"=>"user_send_location", "app_id"=>"102719276611582260", "sender"=>{"id"=>"8309393969855402319"}, "recipient"=>{"id"=>"1423847451268726170"}, "message"=>{"attachments"=>[{"payload"=>{"coordinates"=>{"latitude"=>"10.7923119", "longitude"=>"106.7820651"}}, "type"=>"location"}], "text"=>"Cơm Coffee New Sky", "msg_id"=>"b8de7d84fa1b3043690c"}, "timestamp"=>"1751100041636", "user_id_by_app"=>"7300442764876318465", "controller"=>"webhooks/zalo", "action"=>"process_payload", "zalo"=>{"event_name"=>"user_send_location", "app_id"=>"102719276611582260", "sender"=>{"id"=>"8309393969855402319"}, "recipient"=>{"id"=>"1423847451268726170"}, "message"=>{"attachments"=>[{"payload"=>{"coordinates"=>{"latitude"=>"10.7923119", "longitude"=>"106.7820651"}}, "type"=>"location"}], "text"=>"Cơm Coffee New Sky", "msg_id"=>"b8de7d84fa1b3043690c"}, "timestamp"=>"1751100041636", "user_id_by_app"=>"7300442764876318465"}}
