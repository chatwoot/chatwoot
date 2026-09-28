module WidgetHelper
  # Token and pubsub_token for the visitor's session. A current token is handed back as is;
  # otherwise one is minted, continuing the row's ids when there is a row and fresh ones when not.
  # A token without a pubsub_token predates lazy creation: with a row it is reissued from the row,
  # without one it is not a session. Nothing is written to the database until
  # WebsiteTokenHelper#ensure_contact.
  def visitor_session(web_widget, token, auth_token_params, contact_inbox)
    session = contact_inbox ? contact_inbox.slice(:source_id, :pubsub_token) : auth_token_params
    session = {} if session[:pubsub_token].blank?
    return [token, session[:pubsub_token]] if session.present? && session[:pubsub_token] == auth_token_params[:pubsub_token]

    source_id = session[:source_id] || SecureRandom.uuid
    pubsub_token = session[:pubsub_token] || ContactInbox.generate_unique_secure_token
    [visitor_token(web_widget, source_id, pubsub_token), pubsub_token]
  end

  def build_contact_inbox_with_token(web_widget)
    contact_inbox = web_widget.create_contact_inbox
    [contact_inbox, visitor_token(web_widget, contact_inbox.source_id, contact_inbox.pubsub_token)]
  end

  private

  def visitor_token(web_widget, source_id, pubsub_token)
    payload = { source_id: source_id, inbox_id: web_widget.inbox.id, pubsub_token: pubsub_token }
    ::Widget::TokenService.new(payload: payload).generate_token
  end
end
