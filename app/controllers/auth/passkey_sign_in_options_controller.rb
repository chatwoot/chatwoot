# Lives outside /auth for the same reason as Auth::ResendConfirmationsController:
# OmniAuth intercepts POST /auth/* as provider callbacks.
class Auth::PasskeySignInOptionsController < ActionController::API
  def create
    return head :not_found unless Passkeys.enabled?

    render json: Passkeys::AuthenticationService.options
  end
end
