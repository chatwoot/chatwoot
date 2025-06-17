class Conversations::TypingStatusManager
  include Events::Types

  attr_reader :conversation, :user, :params

  def initialize(conversation, user, params)
    @conversation = conversation
    @user = user
    @params = params
  end

  def trigger_typing_event(event, is_private)
    user = @user.presence || @resource
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user, is_private: is_private)

    # Nếu là bot agent, cũng gửi typing indicator đến platform (Facebook/Instagram)
    if @user.is_a?(AgentBot) && event == CONVERSATION_TYPING_ON
      send_platform_typing_indicator('on')
    elsif @user.is_a?(AgentBot) && event == CONVERSATION_TYPING_OFF
      send_platform_typing_indicator('off')
    end
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    # Return the head :ok response from the controller
  end

  private

  # Gửi typing indicator đến platform (Facebook/Instagram) khi bot agent typing
  def send_platform_typing_indicator(status)
    return unless @conversation.inbox.channel_type.in?(['Channel::FacebookPage', 'Channel::Instagram'])
    return if @conversation.contact.blank?

    begin
      typing_service = Bot::TypingService.new(conversation: @conversation)

      case status
      when 'on'
        result = typing_service.enable_typing
        Rails.logger.info "TypingStatusManager: Bot agent typing ON sent to #{@conversation.inbox.channel_type} - Success: #{result}"
      when 'off'
        result = typing_service.disable_typing
        Rails.logger.info "TypingStatusManager: Bot agent typing OFF sent to #{@conversation.inbox.channel_type} - Success: #{result}"
      end
    rescue => e
      Rails.logger.error "TypingStatusManager: Error sending bot agent typing to platform: #{e.message}"
    end
  end
end
