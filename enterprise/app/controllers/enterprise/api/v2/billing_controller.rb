class Enterprise::Api::V2::BillingController < Api::BaseController
  before_action :fetch_account
  before_action :check_billing_authorization
  before_action :validate_topup_amount, only: [:topup]

  rescue_from StandardError, with: :render_error
  rescue_from NotImplementedError, with: :render_not_implemented

  def credit_grants
    service = Enterprise::Billing::V2::CreditManagementService.new(account: @account)
    grants = service.fetch_credit_grants

    render json: { credit_grants: grants }
  end

  def pricing_plans
    plans = Enterprise::Billing::V2::PlanCatalog.plans
    render json: { pricing_plans: plans }
  end

  def topup_options
    options = Enterprise::Billing::V2::TopupCatalog.options
    render json: { topup_options: options }
  end

  def topup
    service = Enterprise::Billing::V2::TopupService.new(account: @account)
    result = service.create_topup(credits: params[:credits].to_i)

    if result[:success]
      render json: { success: true, message: result[:message] }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  def subscribe
    service = Enterprise::Billing::V2::CheckoutSessionService.new(account: @account)
    redirect_url = service.create_subscription_checkout(
      pricing_plan_id: params[:pricing_plan_id],
      quantity: subscription_quantity
    )

    render json: { redirect_url: redirect_url }
  end

  def cancel_subscription
    service = Enterprise::Billing::V2::CancelSubscriptionService.new(account: @account)
    result = service.cancel_subscription(
      reason: params[:reason],
      feedback: params[:feedback]
    )

    if result[:success]
      # Include account ID and updated attributes for frontend store update
      @account.reload
      render json: result.merge(
        id: @account.id,
        custom_attributes: @account.custom_attributes
      )
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  def change_pricing_plan
    service = Enterprise::Billing::V2::ChangePlanService.new(account: @account)
    result = service.change_plan(
      new_pricing_plan_id: params[:pricing_plan_id],
      quantity: params[:quantity]&.to_i
    )

    if result[:success]
      # Include account ID and updated attributes for frontend store update
      @account.reload
      render json: result.merge(
        id: @account.id,
        custom_attributes: @account.custom_attributes
      )
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def subscription_quantity
    [params[:quantity].to_i, 1].max
  end

  def validate_topup_amount
    return if params[:credits].to_i.positive?

    render json: { error: I18n.t('errors.enterprise.billing.topup_amount_invalid') }, status: :unprocessable_entity
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end

  def render_error(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def render_not_implemented(exception)
    render json: { error: exception.message }, status: :not_implemented
  end

  def check_billing_authorization
    authorize(@account, "#{action_name}?".to_sym)
  end
end
