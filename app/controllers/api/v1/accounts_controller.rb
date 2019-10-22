class Api::V1::AccountsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate_user!, :set_current_user, :check_subscription, :handle_with_exception,
                     only: [:create], raise: false

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def create
    @user = AccountBuilder.new(params).perform
    if @user
      set_headers(@user)
      render json: {
        data: @user.token_validation_response
      }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  private

  def set_headers(user)
    data = user.create_new_auth_token
    response.headers[DeviseTokenAuth.headers_names[:"access-token"]] = data['access-token']
    response.headers[DeviseTokenAuth.headers_names[:"token-type"]]   = 'Bearer'
    response.headers[DeviseTokenAuth.headers_names[:client]]       = data['client']
    response.headers[DeviseTokenAuth.headers_names[:expiry]]       = data['expiry']
    response.headers[DeviseTokenAuth.headers_names[:uid]]          = data['uid']
  end
end
