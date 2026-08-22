class Webhooks::LineEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: '', post_body: '')
    @params = params
    return unless valid_event_payload?
    return unless valid_post_body?(post_body, signature)

    line_params = @params['line'].presence || @params.except(:line_channel_id).presence
    return unless line_params

    Line::IncomingMessageService.new(inbox: @channel.inbox, params: line_params.with_indifferent_access).perform
  end

  private

  def valid_event_payload?
    @channel = Channel::Line.find_by(line_channel_id: @params[:line_channel_id]) if @params[:line_channel_id]
    if @channel.blank?
      Rails.logger.warn("[LINE] channel not found for line_channel_id=#{@params[:line_channel_id]}")
      return false
    end
    true
  end

  # https://developers.line.biz/en/reference/messaging-api/#signature-validation
  # validate the line payload
  def valid_post_body?(post_body, signature)
    if @channel.blank?
      Rails.logger.warn('[LINE] cannot validate signature without channel')
      return false
    end

    return false if signature.blank? || post_body.blank?

    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @channel.line_channel_secret, post_body)
    expected = Base64.strict_encode64(hash)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  rescue StandardError => e
    Rails.logger.error("[LINE] signature validation failed: #{e.class} #{e.message}")
    false
  end
end
