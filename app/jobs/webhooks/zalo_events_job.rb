class Webhooks::ZaloEventsJob < ApplicationJob
  queue_as :default

  SUPPORTED_EVENTS = %w[user_send_text user_send_image user_send_link user_send_audio user_send_video user_send_sticker
                        user_send_location user_send_file user_received_message user_seen_message user_submit_info
                        oa_send_text oa_send_image oa_send_gif oa_send_file oa_send_sticker].freeze

  def perform(params = {}, signature: '', post_body: '', from_zns: false)
    return unless SUPPORTED_EVENTS.include?(params[:event_name])
    return unless validate_signature(params, post_body, signature)

    oa_id = delivery_event?(params) || oa_send_from_chat_tool?(params) ? params[:sender][:id] : params[:recipient][:id]
    channel = Channel::ZaloOa.find_by(oa_id: oa_id)
    return unless channel

    process_event_params(channel, params, from_zns)
  end

  private

  def validate_signature(params, post_body, signature)
    app_id = params[:app_id]
    timestamp = params[:timestamp]
    oa_secret_key = ENV.fetch('ZALO_OA_SECRET_KEY', nil)
    raw_verify = "#{app_id}#{post_body}#{timestamp}#{oa_secret_key}"

    hash = Digest::SHA256.hexdigest(raw_verify)
    signature == "mac=#{hash}"
  end

  def process_event_params(channel, params, from_zns)
    if from_zns
      Zalo::ZnsDeliveryService.new(params: params.with_indifferent_access).perform
    elsif delivery_event?(params)
      Zalo::DeliveryStatusService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    elsif oa_send_from_chat_tool?(params)
      Zalo::OutgoingMessageService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    else
      Zalo::IncomingMessageService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    end
  end

  def delivery_event?(params)
    params[:event_name] == 'user_received_message' || params[:event_name] == 'user_seen_message'
  end

  def oa_send_from_chat_tool?(params)
    params[:event_name].start_with?('oa_') && params[:sender][:admin_id].present?
  end
end
