module Keycloak::Patches::RequestExceptionHandlerExtension
  private

  # Users whose permissions are synced from Keycloak get a 403 (the dashboard treats 401 as a logged-out session)
  def render_unauthorized(message)
    return super unless Current.account_user&.keycloak_managed?

    render json: { error: message }, status: :forbidden
  end
end
