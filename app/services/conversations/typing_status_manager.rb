class Conversations::TypingStatusManager
  include Events::Types

  attr_reader :conversation, :user, :params

  def initialize(conversation, user, params)
    @conversation = conversation
    @user = user
    @params = params
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end
  end

  private

  def trigger_typing_event(event)
    # Dispatch event cho UI (ActionCable)
    Rails.configuration.dispatcher.dispatch(
      event,
      Time.zone.now,
      conversation: @conversation,
      user: @user,
      is_private: params[:is_private] || false
    )

    # Chỉ gửi typing indicator đến platform khi là human agent (User)
    # Bỏ logic bot agent phức tạp, chỉ focus vào human agent
    if @user.is_a?(User) && @user.agent?
      send_platform_typing_indicator(event)
    end
  end

  def send_platform_typing_indicator(event)
    Rails.logger.info "TypingStatusManager: Processing typing #{event == CONVERSATION_TYPING_ON ? 'ON' : 'OFF'} for conversation #{@conversation.id}"

    # Chỉ hỗ trợ Facebook và Instagram
    return unless @conversation.inbox.channel_type.in?(['Channel::FacebookPage', 'Channel::Instagram'])

    # Kiểm tra contact và source_id
    if @conversation.contact.blank?
      Rails.logger.error "TypingStatusManager: Contact missing for conversation #{@conversation.id}"
      return
    end

    source_id = @conversation.contact.get_source_id(@conversation.inbox.id)
    if source_id.blank?
      Rails.logger.error "TypingStatusManager: Source ID missing for conversation #{@conversation.id}"
      return
    end

    # Gửi typing indicator trực tiếp đến platform
    begin
      success = case event
                when CONVERSATION_TYPING_ON
                  send_typing_on(source_id)
                when CONVERSATION_TYPING_OFF
                  send_typing_off(source_id)
                else
                  false
                end

      Rails.logger.info "TypingStatusManager: Typing indicator sent to #{@conversation.inbox.channel_type} - Success: #{success}"
    rescue => e
      Rails.logger.error "TypingStatusManager: Error sending typing indicator: #{e.message}"
    end
  end

  # Gửi typing ON trực tiếp
  def send_typing_on(source_id)
    typing_service = create_typing_service(source_id)
    typing_service&.enable || false
  end

  # Gửi typing OFF trực tiếp
  def send_typing_off(source_id)
    typing_service = create_typing_service(source_id)
    typing_service&.disable || false
  end

  # Tạo typing service phù hợp với channel
  def create_typing_service(source_id)
    case @conversation.inbox.channel_type
    when 'Channel::FacebookPage'
      Facebook::TypingIndicatorService.new(@conversation.inbox.channel, source_id)
    when 'Channel::Instagram'
      Instagram::TypingIndicatorService.new(@conversation.inbox.channel, source_id)
    else
      nil
    end
  end
end
