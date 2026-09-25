module WebsiteTokenHelper
  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers['X-Auth-Token']).decode_token
  end

  def set_web_widget
    if params.key?(:sdk_app_id)
      unless params[:sdk_app_id].is_a?(String) && params[:sdk_app_id].present?
        render json: { error: 'SDK app ID must be a non-empty string' }, status: :unprocessable_entity
        return
      end

      @sdk_app = SdkApp.find_by!(app_id: params[:sdk_app_id])
      @web_widget = @sdk_app.inbox.channel
    else
      @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    end
    @current_account = @web_widget.inbox.account

    render json: { error: 'Account is suspended' }, status: :unauthorized unless @current_account.active?
  end

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    @contact = @contact_inbox&.contact
    raise ActiveRecord::RecordNotFound unless @contact

    Current.contact = @contact
  end

  def permitted_params
    params.permit(:website_token)
  end
end
