class Api::V1::Accounts::BillingTrialsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  rescue_from Enterprise::Billing::TrialService::Error, Stripe::StripeError, with: :render_trial_error

  def create
    render json: { redirect_url: Enterprise::Billing::TrialService.new(account: Current.account).portal_url }
  end

  private

  def render_trial_error(error)
    render_could_not_create_error(error.message)
  end
end
