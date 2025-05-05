module WebsiteTokenHelper
  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers['X-Auth-Token']).decode_token
  end

  def set_web_widget

    token_parts = permitted_params[:website_token].to_s.split('_')
    website_token = token_parts[0]
    @agency_id = token_parts[1]

    @web_widget = ::Channel::WebWidget.find_by!(website_token: website_token)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error('web widget does not exist')
    render json: { error: 'web widget does not exist' }, status: :not_found
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
