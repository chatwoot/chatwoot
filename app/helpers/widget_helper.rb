module WidgetHelper
  def build_contact_inbox_with_token(web_widget, additional_attributes = {})
    contact_inbox = web_widget.create_contact_inbox(additional_attributes)
    token = ::Widget::TokenService.new(payload: ::Widget::TokenService.payload_for(contact_inbox)).generate_token

    [contact_inbox, token]
  end
end
