module WidgetHelper
  def build_contact_inbox_with_token(web_widget, additional_attributes = {})
    contact_inbox = web_widget.create_contact_inbox(additional_attributes)
    payload = { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }
    token = ::Widget::TokenService.new(payload: payload).generate_token

    [contact_inbox, token]
  end

  def widget_conversation_ai_state(conversation)
    return 'resolved' if conversation.resolved?
    return 'ai' if conversation.pending? && conversation.inbox.active_bot?

    'human'
  end
end
