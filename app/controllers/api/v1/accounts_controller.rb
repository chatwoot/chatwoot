class Api::V1::AccountsController < Api::BaseController
  include AuthHelper

  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate_user!, :set_current_user, :check_subscription, :handle_with_exception,
                     only: [:create], raise: false

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def create
    @user = AccountBuilder.new(account_params).perform
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
    params.permit(:account_name, :email).to_h
  end
end
