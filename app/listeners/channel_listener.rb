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
    # Xử lý cho kênh Facebook và Instagram
    channel_type = conversation.inbox.channel_type
    return unless %w[Channel::FacebookPage Channel::Instagram].include?(channel_type)

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
      # Tạo typing service tương ứng với channel type
      typing_service = case channel_type
                      when 'Channel::FacebookPage'
                        Facebook::TypingIndicatorService.new(channel, source_id)
                      when 'Channel::Instagram'
                        Instagram::TypingIndicatorService.new(channel, source_id)
                      end

      return if typing_service.blank?

      # Nếu là typing_on, sử dụng phương thức mark_seen_and_typing tối ưu cho mobile
      if typing_status == 'typing_on'
        result = typing_service.mark_seen_and_typing
      else
        # Nếu là typing_off, chỉ cần tắt typing indicator
        result = typing_service.disable
      end

      platform_name = channel_type == 'Channel::FacebookPage' ? 'Facebook' : 'Instagram'

      if result
        Rails.logger.info "Successfully sent #{typing_status} to #{platform_name} v22 for conversation #{conversation.id}"
      else
        Rails.logger.warn "Failed to send #{typing_status} to #{platform_name} v22 for conversation #{conversation.id}"
      end
    rescue => e
      platform_name = channel_type == 'Channel::FacebookPage' ? 'Facebook' : 'Instagram'
      Rails.logger.error "Error sending typing indicator to #{platform_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end