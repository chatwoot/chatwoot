class PasswordsController < Devise::PasswordsController
  skip_before_action :require_no_authentication, raise: false
  skip_before_action :authenticate_user!, raise: false

  def update
    # params: reset_password_token, password, password_confirmation
    original_token = params[:reset_password_token]
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)
    @recoverable = User.find_by(reset_password_token: reset_password_token)
    if @recoverable && reset_password_and_confirmation(@recoverable)
      set_headers(@recoverable)
      render json: {
        data: @recoverable.token_validation_response
      }
    else
      render json: { "message": 'Invalid token', "redirect_url": '/' }, status: 422
    end
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user
      @user.send_reset_password_instructions
      build_response(I18n.t('messages.reset_password_success'), 200)
    else
      build_response(I18n.t('messages.reset_password_failure'), 404)
    end
  end

  protected

  def set_headers(user)
    data = user.create_new_auth_token
    response.headers[DeviseTokenAuth.headers_names[:"access-token"]] = data['access-token']
    response.headers[DeviseTokenAuth.headers_names[:"token-type"]]   = 'Bearer'
    response.headers[DeviseTokenAuth.headers_names[:client]]       = data['client']
    response.headers[DeviseTokenAuth.headers_names[:expiry]]       = data['expiry']
    response.headers[DeviseTokenAuth.headers_names[:uid]]          = data['uid']
  end

  def reset_password_and_confirmation(recoverable)
    recoverable.confirm unless recoverable.confirmed? # confirm if user resets password without confirming anytime before
    recoverable.reset_password(params[:password], params[:password_confirmation])
    recoverable.reset_password_token = nil
    recoverable.confirmation_token = nil
    recoverable.reset_password_sent_at = nil
    recoverable.save!
  end

  def build_response(message, status)
    render json: {
      "message": message
    }, status: status
  end
end
