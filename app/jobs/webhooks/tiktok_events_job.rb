# https://business-api.tiktok.com/portal/docs?id=1832190670631937
class Webhooks::TiktokEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 8

  SUPPORTED_EVENTS = [:im_send_msg, :im_receive_msg, :im_mark_read_msg].freeze

  def perform(event)
    @event = event.with_indifferent_access

    return if channel_is_inactive?

    key = format(::Redis::Alfred::TIKTOK_MESSAGE_MUTEX, business_id: business_id, conversation_id: conversation_id)
    with_lock(key, 10.seconds) do
      process_event
    end
  end

  private

  def channel_is_inactive?
    return true if channel.blank?
    return true unless channel.account.active?

    false
  end

  def process_event
    return if event_name.blank? || channel.blank?

    send(event_name)
  end

  def event_name
    @event_name ||= SUPPORTED_EVENTS.include?(@event[:event].to_sym) ? @event[:event] : nil
  end

  def business_id
    @business_id ||= @event[:user_openid]
  end

  def content
    @content ||= JSON.parse(@event[:content]).deep_symbolize_keys
  end

  def conversation_id
    @conversation_id ||= content[:conversation_id]
  end

  def channel
    @channel ||= Channel::Tiktok.find_by(business_id: business_id)
  end

  # Receive real-time notifications if you send a message to a user.
  def im_send_msg
    # This can be either an echo message or a message sent directly via tiktok application
    ::Tiktok::MessageService.new(channel: channel, content: content).perform
  end

  # Receive real-time notifications if a user outside the European Economic Area (EEA), Switzerland, or the UK sends a message to you.
  def im_receive_msg
    ::Tiktok::MessageService.new(channel: channel, content: content).perform
  end

  # Receive real-time notifications when a Personal Account user marks all messages in a session as read.
  def im_mark_read_msg
    ::Tiktok::ReadStatusService.new(channel: channel, content: content).perform
  end
end
