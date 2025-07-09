class ChannelListener < BaseListener
  include Events::Types
  include Singleton

  def conversation_typing_on(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.blank?

    user = event.data[:user]
    # Chỉ xử lý typing cho human agents (User), bỏ qua bot agents
    return unless user.is_a?(User) && user.agent?

    process_typing_event(conversation, 'typing_on', event)
  end

  def conversation_typing_off(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.blank?

    user = event.data[:user]
    # Chỉ xử lý typing cho human agents (User), bỏ qua bot agents
    return unless user.is_a?(User) && user.agent?

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

    # Kiểm tra xem contact_inbox có source_id không
    source_id = contact_inbox.source_id
    if source_id.blank?
      Rails.logger.error "ChannelListener: Missing source_id for contact_inbox #{contact_inbox.id}"
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

      # Sử dụng enable/disable đơn giản theo Chatwoot gốc
      if typing_status == 'typing_on'
        result = typing_service.enable
      else
        result = typing_service.disable
      end

      platform_name = channel_type == 'Channel::FacebookPage' ? 'Facebook' : 'Instagram'

      if result
        Rails.logger.info "ChannelListener: Successfully sent #{typing_status} to #{platform_name} for conversation #{conversation.id}"
      else
        Rails.logger.warn "ChannelListener: Failed to send #{typing_status} to #{platform_name} for conversation #{conversation.id}"
      end
    rescue => e
      platform_name = channel_type == 'Channel::FacebookPage' ? 'Facebook' : 'Instagram'
      Rails.logger.error "ChannelListener: Error sending typing indicator to #{platform_name}: #{e.message}"
    end
  end
end