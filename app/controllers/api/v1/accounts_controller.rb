class Api::V1::AccountsController < Api::BaseController
  include AuthHelper

  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate_user!, :set_current_user, :check_subscription, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def create
    @user = AccountBuilder.new(
      account_name: account_params[:account_name],
      email: account_params[:email]
    ).perform
    if @user
      send_auth_headers(@user)
      render json: {
        data: @user.token_validation_response
      }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  private

  def account_params
    params.permit(:account_name, :email)
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' if ENV.fetch('ENABLE_ACCOUNT_SIGNUP', true) == 'false'
  end
end
