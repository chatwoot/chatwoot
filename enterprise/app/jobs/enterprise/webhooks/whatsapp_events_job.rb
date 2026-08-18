module Enterprise::Webhooks::WhatsappEventsJob
  def handle_message_events(channel, params)
    return handle_call_permission_reply(channel, params) if call_permission_reply?(params)

    super
  end

  private

  def call_permission_reply?(params)
    params.dig(:entry, 0, :changes, 0, :value, :messages, 0, :interactive, :type) == 'call_permission_reply'
  end

  def handle_call_permission_reply(channel, params)
    Whatsapp::CallPermissionReplyService.new(inbox: channel.inbox, params: params).perform
  end
end
