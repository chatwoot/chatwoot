class Api::V1::Accounts::BillingTrialsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  rescue_from Enterprise::Billing::TrialService::Error, Stripe::StripeError, with: :render_trial_error

  def create
    render json: { redirect_url: trial_service.portal_url }
  end

  def update
    trial_service.update_seats(params.require(:quantity))
    head :ok
  end

  private

  def trial_service
    Enterprise::Billing::TrialService.new(account: Current.account)
  end

  def render_trial_error(error)
    render_could_not_create_error(error.message)
  end
end
