class Api::V1::AccountsController < Api::BaseController
  include AuthHelper

  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def create
    @user, @account = AccountBuilder.new(
      account_name: account_params[:account_name],
      email: account_params[:email],
      confirmed: confirmed?,
      user: current_user
    ).perform
    if @user
      send_auth_headers(@user)
      render 'api/v1/accounts/create.json', locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def show
    render 'api/v1/accounts/show.json'
  end

  def update
    @account.update!(account_params.slice(:name, :locale, :domain, :support_email))
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  private

  def check_authorization
    authorize(Account)
  end

  def confirmed?
    super_admin? && params[:confirmed]
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def account_params
    params.permit(:account_name, :email, :name, :locale, :domain, :support_email)
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' if ENV.fetch('ENABLE_ACCOUNT_SIGNUP', true) == 'false'
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
