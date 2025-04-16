class ChannelListener < BaseListener
  include Events::Types
  include Singleton

  def conversation_typing_on(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.blank?

    process_typing_event(conversation, 'typing_on', event)
  end

  def conversation_typing_off(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.blank?

    process_typing_event(conversation, 'typing_off', event)
  end

  private

  def process_typing_event(conversation, typing_status, event)
    # Chỉ xử lý cho kênh Facebook
    return unless conversation.inbox.channel_type == 'Channel::FacebookPage'
    # Không xử lý tin nhắn riêng tư
    return if event.data[:is_private]

    # Lấy thông tin cần thiết
    contact_inbox = conversation.contact_inbox
    return if contact_inbox.blank?

    channel = conversation.inbox.channel
    return if channel.blank?

    # Chỉ gửi typing indicator khi agent đang typing
    user = event.data[:user]
    return unless user.is_a?(User)

    # Kiểm tra xem contact_inbox có source_id không
    source_id = contact_inbox.source_id
    if source_id.blank?
      Rails.logger.error "Cannot send typing indicator: Missing source_id for contact_inbox #{contact_inbox.id}"
      return
    end

    begin
      # Gửi typing indicator đến Facebook
      typing_service = Facebook::TypingIndicatorService.new(channel, source_id)

      # Nếu là typing_on, đánh dấu tin nhắn đã xem trước, sau đó mới gửi typing indicator
      if typing_status == 'typing_on'
        # Đánh dấu tin nhắn đã xem trước khi gửi typing indicator
        mark_seen_result = typing_service.mark_seen
        Rails.logger.info "Marked message as seen for conversation #{conversation.id}" if mark_seen_result

        # Đợi một khoảng thời gian ngắn để Facebook xử lý request mark_seen
        sleep(0.3) if mark_seen_result

        # Sau đó mới gửi typing indicator
        result = typing_service.enable
      else
        # Nếu là typing_off, chỉ cần tắt typing indicator
        result = typing_service.disable
      end

      if result
        Rails.logger.info "Successfully sent #{typing_status} to Facebook for conversation #{conversation.id}"
      else
        Rails.logger.warn "Failed to send #{typing_status} to Facebook for conversation #{conversation.id}"
      end
    rescue => e
      Rails.logger.error "Error sending typing indicator to Facebook: #{e.message}"
    end
  end
end