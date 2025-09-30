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
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
      send_apple_typing_indicator(:start) if apple_messages_channel?
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
      send_apple_typing_indicator(:end) if apple_messages_channel?
    end
    # Return the head :ok response from the controller
  end

  private

  def apple_messages_channel?
    @conversation.inbox.channel.is_a?(Channel::AppleMessagesForBusiness)
  end

  def send_apple_typing_indicator(action)
    return unless params[:is_private] == false # Only for public messages

    # Get the Apple Messages source ID from contact's additional attributes
    apple_source_urn = @conversation.contact&.additional_attributes&.dig('apple_messages_source_id')
    return unless apple_source_urn # Need destination ID

    # Extract the UUID from the URN format (urn:biz:UUID)
    destination_id = apple_source_urn.sub(/^urn:biz:/, '')

    service = AppleMessagesForBusiness::OutgoingTypingIndicatorService.new(
      channel: @conversation.inbox.channel,
      destination_id: destination_id,
      action: action
    )

    result = service.perform
    Rails.logger.warn "[AMB TypingIndicator] Failed: #{result}" unless result[:success]
  end
end
