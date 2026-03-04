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
      send_whatsapp_typing_indicator unless params[:is_private]
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    # Return the head :ok response from the controller
  end

  private

  def send_whatsapp_typing_indicator
    channel = conversation.inbox&.channel
    return unless channel.is_a?(Channel::Whatsapp)
    return unless channel.provider == 'whatsapp_cloud'

    last_incoming = conversation.messages.incoming.where.not(source_id: nil).last
    return if last_incoming.blank?

    Whatsapp::SendTypingIndicatorJob.perform_later(channel, last_incoming.source_id)
  end
end
