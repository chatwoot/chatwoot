module Enterprise::Api::V1::Accounts::Concerns::BillingV2
  extend ActiveSupport::Concern

  included do
    before_action :validate_topup_amount, only: [:v2_topup]
  end

  def credit_grants
    service = Enterprise::Billing::V2::CreditManagementService.new(account: @account)
    grants = service.fetch_credit_grants

    render json: { credit_grants: grants }
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
    render json: { success: true, message: 'Topup successful.' }
  end

  def v2_subscribe
    service = Enterprise::Billing::V2::CheckoutSessionService.new(account: @account)
    result = service.create_subscription_checkout(
      pricing_plan_id: params[:pricing_plan_id],
      quantity: subscription_quantity
    )

    if result[:success]
      render json: { success: true, redirect_url: result[:redirect_url], session_id: result[:session_id] }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  def cancel_subscription
    service = Enterprise::Billing::V2::CancelSubscriptionService.new(account: @account)
    result = service.cancel_subscription

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
    render json: { success: true, message: 'Pricing plan changed.' }
  end

  private

  def subscription_quantity
    [params[:quantity].to_i, 1].max
  end

  def validate_topup_amount
    return if params[:credits].to_i.positive?

    render json: { error: 'Topup amount must be greater than 0' }, status: :unprocessable_entity
  end
end
