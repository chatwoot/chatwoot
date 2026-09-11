module WebsiteTokenHelper
  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers['X-Auth-Token']).decode_token
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @current_account = @web_widget.inbox.account

    render json: { error: 'Account is suspended' }, status: :unauthorized unless @current_account.active?
  end

  def set_contact
    @contact_inbox = find_widget_contact_inbox
    @contact = @contact_inbox&.contact
    raise ActiveRecord::RecordNotFound unless @contact

    Current.contact = @contact
  end

  def find_widget_contact_inbox
    inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    return unless inbox&.valid_widget_token?(auth_token_params)

    inbox
  end

  def permitted_params
    params.permit(:website_token)
  end
end
