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
      notify_provider if notify_provider?
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    # Return the head :ok response from the controller
  end

  private

  # Opt-in per request. Only a client that asks for it (a bot engine) reaches the provider;
  # the dashboard never sends the flag, so a human agent's keystrokes never mark the
  # customer's message as read on WhatsApp. Private notes never reach the provider.
  def notify_provider?
    boolean(params[:notify_provider]) && !boolean(params[:is_private])
  end

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) == true
  end

  # Inline on purpose (no job): the indicator is only worth showing in the next few seconds,
  # and a queued job delivered late would show "typing…" after the reply already arrived.
  # The provider call has a 5 s timeout and never raises.
  def notify_provider
    channel = conversation.inbox.channel
    return unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    wamid = conversation.messages.incoming.where.not(source_id: [nil, '']).reorder(created_at: :desc).first&.source_id
    return if wamid.blank?

    channel.provider_service.send_typing_indicator(wamid)
  end
end
