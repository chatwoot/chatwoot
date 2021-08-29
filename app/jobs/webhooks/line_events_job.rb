class Webhooks::LineEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: "", post_body: "")
    return unless params[:line_channel_id]

    @channel = Channel::Line.find_by(line_channel_id: params[:line_channel_id])
    return unless @channel

    return unless valid_post_body?(post_body, signature)

    Line::IncomingMessageService.new(inbox: @channel.inbox, params: params['line'].with_indifferent_access).perform
  end

  private

  # https://developers.line.biz/en/reference/messaging-api/#signature-validation
  # validate the line payload
  def valid_post_body?(post_body, signature)
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, @channel.line_channel_secret, post_body)
    Base64.strict_encode64(hash) == signature
  end
end

