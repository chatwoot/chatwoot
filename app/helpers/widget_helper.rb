module WidgetHelper
  def build_contact_inbox_with_token(web_widget, additional_attributes = {})
    contact_inbox = ::ContactInboxWithContactBuilder.new(inbox: web_widget.inbox,
                                                         contact_attributes: { additional_attributes: additional_attributes }).perform
    payload = { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }
    token = ::Widget::TokenService.new(payload: payload).generate_token

    [contact_inbox, token]
  end
end
