class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include RequestExceptionHandler
  include Pundit::Authorization
  include SwitchLocale

  skip_before_action :verify_authenticity_token

  before_action :set_current_user, unless: :devise_controller?
  around_action :switch_locale
  around_action :handle_with_exception, unless: :devise_controller?

  private

  def set_current_user
    @user ||= current_user
    Current.user = @user
  end

  def pundit_user
    {
      user: Current.user,
      account: Current.account,
      account_user: Current.account_user
    }
  end

  def current_subscription
    @subscription ||= current_account_by_user.account_billing_subscriptions.last
  end

  def current_account_by_user
    if defined? current_account
      current_account
    else
      current_user.accounts.find(params[:account_id] || params[:id])
    end
  rescue StandardError => e
    Rails.logger.info e.message
    current_user.accounts.last
  end

  def verify_subscription
    return if current_super_admin
    return if current_account_by_user.blank?

    if current_subscription.blank?
      render_payment_required('Please subscribe to a Plan') and return
    elsif current_subscription.current_period_end < Time.current
      render_payment_required('Payment Required for the Plan') and return
    end
  end
end
