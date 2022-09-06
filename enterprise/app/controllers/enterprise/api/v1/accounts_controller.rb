class Enterprise::Api::V1::AccountsController < Api::BaseController
  before_action :fetch_account
  before_action :check_authorization

  def subscription
    if stripe_customer_id.blank? && @account.custom_attributes['is_creating_customer'].blank?
      @account.update(custom_attributes: { is_creating_customer: true })
      Enterprise::CreateStripeCustomerJob.perform_later(@account)
    end
    head :no_content
  end

  def checkout
    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def create_stripe_billing_session(customer_id)
    session = Enterprise::Billing::CreateSessionService.new.create_session(customer_id)
    render_redirect_url(session.url)
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
