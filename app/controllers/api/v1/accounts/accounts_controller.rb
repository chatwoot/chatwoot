class Api::V1::Accounts::AccountsController < Api::BaseController
  include AuthHelper

  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate_user!, :set_current_user, :check_subscription, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :check_authorization, except: [:create]
  before_action :fetch_account, except: [:create]

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
      render 'devise/auth.json', locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def show
    render 'api/v1/accounts/show.json'
  end

  def update
    @account.update!(account_params.slice(:name, :locale, :domain, :support_email, :domain_emails_enabled))
  end

  private

  def check_authorization
    authorize(Account)
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    params.permit(:account_name, :email, :name, :locale, :domain, :support_email, :domain_emails_enabled)
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' if ENV.fetch('ENABLE_ACCOUNT_SIGNUP', true) == 'false'
  end
end
