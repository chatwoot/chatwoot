class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:limits, :toggle_deletion]
  before_action :validate_topup_amount, only: [:v2_topup]

  def subscription
    if stripe_customer_id.blank? && @account.custom_attributes['is_creating_customer'].blank?
      @account.update(custom_attributes: { is_creating_customer: true })
      Enterprise::CreateStripeCustomerJob.perform_later(@account)
    end
    head :no_content
  end

  def limits
    limits = if default_plan?(@account)
               {
                 'conversation' => {
                   'allowed' => 500,
                   'consumed' => conversations_this_month(@account)
                 },
                 'non_web_inboxes' => {
                   'allowed' => 0,
                   'consumed' => non_web_inboxes(@account)
                 },
                 'agents' => {
                   'allowed' => 2,
                   'consumed' => agents(@account)
                 }
               }
             else
               default_limits
             end

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def checkout
    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  # V2 Billing Endpoints
  def credits_balance
    service = Enterprise::Billing::V2::CreditManagementService.new(account: @account)
    balance = service.credit_balance

    render json: {
      id: @account.id,
      monthly_credits: balance[:monthly],
      topup_credits: balance[:topup],
      total_credits: balance[:total],
      usage_this_month: balance[:usage_this_month],
      usage_total: balance[:usage_total]
    }
  end

  def v2_pricing_plans
    plans = Enterprise::Billing::V2::PlanCatalog.plans
    render json: { pricing_plans: plans }
  end

  def v2_topup_options
    options = Enterprise::Billing::V2::TopupCatalog.options
    render json: { topup_options: options }
  end

  def v2_topup
    service = Enterprise::Billing::V2::TopupService.new(account: @account)
    result = service.create_topup(credits: params[:credits].to_i)

    if result[:success]
      render json: { success: true, message: result[:message] }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  def v2_subscribe
    service = Enterprise::Billing::V2::CheckoutSessionService.new(account: @account)
    result = service.create_subscription_checkout(
      pricing_plan_id: params[:pricing_plan_id],
      quantity: subscription_quantity
    )

    if result[:success]
      render json: { success: true, redirect_url: result[:redirect_url], checkout_session_id: result[:checkout_session_id] }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  def cancel_subscription
    service = Enterprise::Billing::V2::CancelSubscriptionService.new(account: @account)
    result = service.cancel_subscription

    if result[:success]
      render json: result
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  private

  def check_cloud_env
    render json: { error: 'Not found' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def default_limits
    {
      'conversation' => {},
      'non_web_inboxes' => {},
      'agents' => {
        'allowed' => @account.usage_limits[:agents],
        'consumed' => agents(@account)
      },
      'captain' => @account.usage_limits[:captain]
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
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

  def subscription_quantity
    quantity = params[:quantity].to_i
    quantity.positive? ? quantity : 1
  end

  def validate_topup_amount
    amount = params[:credits].to_i
    return if amount.positive?

    render json: { error: 'Topup amount must be greater than 0' }, status: :unprocessable_entity
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
