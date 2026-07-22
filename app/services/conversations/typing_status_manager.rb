class Conversations::TypingStatusManager
  include Events::Types

  attr_reader :conversation, :user, :params

  def initialize(conversation, user, params)
    @conversation = conversation
    @user = user
    @params = params
  end

  def trigger_typing_event(event, is_private)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @user, is_private: is_private)
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
      notify_whatsapp_typing unless ActiveModel::Type::Boolean.new.cast(params[:is_private])
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    # Return the head :ok response from the controller
  end

  private

  def notify_whatsapp_typing
    Whatsapp::TypingIndicatorJob.perform_later(@conversation.id)
  end
end
