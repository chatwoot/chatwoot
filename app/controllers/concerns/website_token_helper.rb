module WebsiteTokenHelper
  def auth_token_params
    @auth_token_params ||= begin
      decoded = ::Widget::TokenService.new(token: request.headers['X-Auth-Token']).decode_token
      # A token only identifies a session in the inbox it was minted for.
      decoded[:inbox_id] == @web_widget.inbox.id ? decoded : {}
    end
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @current_account = @web_widget.inbox.account
    render json: { error: 'Account is suspended' }, status: :unauthorized unless @current_account.active?
  end

  def set_contact
    raise ActiveRecord::RecordNotFound if auth_token_params[:source_id].blank?

    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: auth_token_params[:source_id])
    @contact = @contact_inbox&.contact
    # A row whose contact is gone (dependent: :destroy_async) is not a session; the next page load issues a new one.
    raise ActiveRecord::RecordNotFound if @contact_inbox && @contact.nil?

    Current.contact = @contact
  end

  # A visitor only gets a contact once they do something worth keeping (open the widget, send a
  # message, identify themselves); loading the page is not that. The token carries the ids to use,
  # and the row is only ever created on the stream the widget is already subscribed to.
  def ensure_contact
    return if @contact.present?
    raise ActiveRecord::RecordNotFound if auth_token_params[:pubsub_token].blank?

    additional_attributes = @current_account.feature_enabled?('ip_lookup') ? { created_at_ip: request.remote_ip } : {}
    @contact_inbox = @web_widget.create_contact_inbox(
      source_id: auth_token_params[:source_id], pubsub_token: auth_token_params[:pubsub_token], additional_attributes: additional_attributes
    )
    @contact = @contact_inbox.contact
    Current.contact = @contact
  end

  def permitted_params
    params.permit(:website_token)
  end
end
