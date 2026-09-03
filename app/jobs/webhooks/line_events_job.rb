class Webhooks::LineEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: '', post_body: '')
    @params = params
    return unless valid_event_payload?

    unless valid_post_body?(post_body, signature)
      Rails.logger.warn(
        "[LINE] Invalid webhook signature channel_id=#{@channel.line_channel_id} account_id=#{@channel.account_id} " \
        "inbox_id=#{@channel.inbox_id} signature_present=#{signature.present?} body_sha256=#{Digest::SHA256.hexdigest(post_body)}"
      )
      return
    end

    Line::IncomingMessageService.new(inbox: @channel.inbox, params: @params['line'].with_indifferent_access).perform
  end

  private

  def valid_event_payload?
    @channel = Channel::Line.find_by(line_channel_id: @params[:line_channel_id]) if @params[:line_channel_id]
  end

  # https://developers.line.biz/en/reference/messaging-api/#signature-validation
  # validate the line payload
  def valid_post_body?(post_body, signature)
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @channel.line_channel_secret, post_body)
    Base64.strict_encode64(hash) == signature
  end
end
