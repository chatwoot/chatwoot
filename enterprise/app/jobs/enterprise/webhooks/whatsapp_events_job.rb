module Enterprise::Webhooks::WhatsappEventsJob
  def handle_message_events(channel, params)
    if call_event?(params)
      handle_call_events(channel, params)
      return
    end

    if call_permission_reply?(params)
      handle_call_permission_reply(channel, params)
      return
    end

    super
  end

  private

  def call_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'calls'
  end

  def call_permission_reply?(params)
    message = params.dig(:entry, 0, :changes, 0, :value, :messages, 0)
    message&.dig(:type) == 'interactive' && message&.dig(:interactive, :type) == 'call_permission_reply'
  end

  def handle_call_events(channel, params)
    Whatsapp::IncomingCallService.new(
      inbox: channel.inbox,
      params: extract_call_params(params)
    ).perform
  end

  def handle_call_permission_reply(channel, params)
    Whatsapp::CallPermissionReplyService.new(inbox: channel.inbox, params: params).perform
  end

  def extract_call_params(params)
    params.dig(:entry, 0, :changes, 0, :value) || {}
  end
end
