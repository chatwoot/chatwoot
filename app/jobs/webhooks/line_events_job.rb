class Webhooks::LineEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 8

  def perform(params: {}, signature: '', post_body: '')
    @params = params
    return unless valid_event_payload?
    return unless valid_post_body?(post_body, signature)

    key = format(::Redis::Alfred::LINE_MESSAGE_MUTEX, line_channel_id: @params[:line_channel_id])

    with_lock(key, 10.seconds) do
      Line::IncomingMessageService.new(inbox: @channel.inbox, params: @params['line'].with_indifferent_access).perform
    end
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
