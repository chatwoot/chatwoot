class Bot::TypingService
  def initialize(conversation:)
    @conversation = conversation
    @inbox = conversation.inbox
    @contact = conversation.contact
  end
  
  def enable_typing
    case @inbox.channel_type
    when 'Channel::FacebookPage'
      enable_facebook_typing
    when 'Channel::Instagram'
      enable_instagram_typing
    when 'Channel::Whatsapp'
      enable_whatsapp_typing
    when 'Channel::Telegram'
      enable_telegram_typing
    else
      false
    end
  end

  def disable_typing
    case @inbox.channel_type
    when 'Channel::FacebookPage'
      disable_facebook_typing
    when 'Channel::Instagram'
      disable_instagram_typing
    when 'Channel::Whatsapp'
      disable_whatsapp_typing
    when 'Channel::Telegram'
      disable_telegram_typing
    else
      false
    end
  end

  def mark_seen
    case @inbox.channel_type
    when 'Channel::FacebookPage'
      mark_facebook_seen
    when 'Channel::Instagram'
      mark_instagram_seen
    when 'Channel::Whatsapp'
      mark_whatsapp_seen
    when 'Channel::Telegram'
      mark_telegram_seen
    else
      false
    end
  end
  
  private
  
  def enable_facebook_typing
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    # Sử dụng phương thức mark_seen_and_typing để đảm bảo typing hoạt động trên di động
    typing_service = Facebook::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.mark_seen_and_typing
  rescue => e
    Rails.logger.error "Bot::TypingService: Error enabling Facebook typing indicator: #{e.message}"
    false
  end

  def disable_facebook_typing
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    typing_service = Facebook::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.disable
  rescue => e
    Rails.logger.error "Bot::TypingService: Error disabling Facebook typing indicator: #{e.message}"
    false
  end

  def mark_facebook_seen
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    typing_service = Facebook::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.mark_seen
  rescue => e
    Rails.logger.error "Bot::TypingService: Error marking Facebook message as seen: #{e.message}"
    false
  end

  # Instagram typing methods
  def enable_instagram_typing
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    # Sử dụng phương thức mark_seen_and_typing để đảm bảo typing hoạt động trên di động
    typing_service = Instagram::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.mark_seen_and_typing
  rescue => e
    Rails.logger.error "Bot::TypingService: Error enabling Instagram typing indicator: #{e.message}"
    false
  end

  def disable_instagram_typing
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    typing_service = Instagram::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.disable
  rescue => e
    Rails.logger.error "Bot::TypingService: Error disabling Instagram typing indicator: #{e.message}"
    false
  end

  def mark_instagram_seen
    return false if @contact.blank? || @contact.get_source_id(@inbox.id).blank?

    typing_service = Instagram::TypingIndicatorService.new(@inbox.channel, @contact.get_source_id(@inbox.id))
    typing_service.mark_seen
  rescue => e
    Rails.logger.error "Bot::TypingService: Error marking Instagram message as seen: #{e.message}"
    false
  end
  
  # Các phương thức tương tự cho WhatsApp và Telegram
  # Có thể triển khai sau khi đã tối ưu Facebook
  
  def enable_whatsapp_typing
    # Triển khai sau
    false
  end
  
  def disable_whatsapp_typing
    # Triển khai sau
    false
  end
  
  def mark_whatsapp_seen
    # Triển khai sau
    false
  end
  
  def enable_telegram_typing
    # Triển khai sau
    false
  end
  
  def disable_telegram_typing
    # Triển khai sau
    false
  end
  
  def mark_telegram_seen
    # Triển khai sau
    false
  end
end
