class Enterprise::Billing::V2::ChangePlanService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::ProrationLineItemBuilder
  include Enterprise::Billing::Concerns::StripeV2ClientHelper
  include Enterprise::Billing::Concerns::PlanProvisioningHelper
  include Enterprise::Billing::Concerns::BillingIntentWorkflow
  include Enterprise::Billing::Concerns::SubscriptionDataManager
  include Enterprise::Billing::Concerns::PlanDataHelper

  def change_plan(new_pricing_plan_id: nil, quantity: nil)
    validation_error = validate_parameters(new_pricing_plan_id, quantity)
    return validation_error if validation_error

    with_locked_account do
      perform_subscription_change(new_pricing_plan_id, quantity)
    end
  end

  private

  def validate_parameters(new_pricing_plan_id, quantity)
    return { success: false, message: 'Must specify either new_pricing_plan_id or quantity' } if new_pricing_plan_id.nil? && quantity.nil?
    return { success: false, message: 'Invalid quantity' } if !quantity.nil? && !quantity.positive?

    # Validate customer has a default payment method using common service
    payment_service = Enterprise::Billing::V2::InvoicePaymentService.new(account: account)
    payment_method_validation = payment_service.validate_payment_method
    return payment_method_validation unless payment_method_validation.nil?

    nil
  end

  def perform_subscription_change(new_pricing_plan_id, quantity)
    change_context = build_change_context(new_pricing_plan_id, quantity)
    return no_change_response(change_context) unless change_required?(change_context)

    execute_change(change_context)
  end

  def build_change_context(new_pricing_plan_id, quantity)
    old_plan_id = pricing_plan_id
    old_quantity = subscribed_quantity
    target_plan_id = new_pricing_plan_id || old_plan_id
    target_quantity = quantity || old_quantity

    {
      old_plan_id: old_plan_id,
      old_quantity: old_quantity,
      target_plan_id: target_plan_id,
      target_quantity: target_quantity,
      plan_changed: old_plan_id != target_plan_id,
      seats_changed: old_quantity != target_quantity
    }
  end

  def change_required?(context)
    context[:plan_changed] || context[:seats_changed]
  end

  def no_change_response(context)
    plan_name = plan_display_name(context[:target_plan_id])
    { success: false, message: "Subscription already has plan #{plan_name} with #{context[:target_quantity]} seat(s)" }
  end

  def execute_change(context)
    # Create and execute billing intent to update the Stripe subscription
    intent_params = build_change_plan_params(context[:target_plan_id], context[:target_quantity])
    execute_billing_intent(intent_params)

    next_billing_date = custom_attribute('next_billing_date')
    proration_data = calculate_proration(
      old_plan_id: context[:old_plan_id],
      new_plan_id: context[:target_plan_id],
      old_quantity: context[:old_quantity],
      new_quantity: context[:target_quantity],
      next_billing_date: next_billing_date
    )
    line_items = build_proration_line_items(context, proration_data)
    create_and_charge_invoice(line_items)

    update_account_plan(context[:target_plan_id], context[:target_quantity], next_billing_date)
    provision_new_plan(context[:target_plan_id]) if context[:plan_changed]

    { success: true, message: 'Plan change successful' }
  end

  def build_change_plan_params(new_pricing_plan_id, quantity)
    metadata = fetch_subscription_metadata
    plan_version = fetch_plan_version(new_pricing_plan_id)
    lookup_key = fetch_plan_lookup_key(new_pricing_plan_id)

    {
      cadence: metadata[:cadence_id],
      currency: 'usd',
      actions: [build_modify_action(metadata[:subscription_id], new_pricing_plan_id, plan_version, lookup_key, quantity)]
    }
  end

  def build_modify_action(subscription_id, plan_id, plan_version, lookup_key, quantity)
    {
      type: 'modify',
      modify: {
        type: 'pricing_plan_subscription_details',
        pricing_plan_subscription_details: {
          pricing_plan_subscription: subscription_id,
          new_pricing_plan: plan_id,
          new_pricing_plan_version: plan_version,
          component_configurations: [{ lookup_key: lookup_key, quantity: quantity }]
        }
      }
    }
  end

  def calculate_proration(old_plan_id:, new_plan_id:, old_quantity:, new_quantity:, next_billing_date:)
    old_plan_price = Enterprise::Billing::V2::PlanCatalog.definition_for(old_plan_id)&.dig(:base_fee) || 0.0
    new_plan_price = Enterprise::Billing::V2::PlanCatalog.definition_for(new_plan_id)&.dig(:base_fee) || 0.0

    Enterprise::Billing::V2::ProrationCalculator.calculate(
      old_plan_price: old_plan_price,
      new_plan_price: new_plan_price,
      old_quantity: old_quantity,
      new_quantity: new_quantity,
      next_billing_date: next_billing_date
    )
  end

  def create_and_charge_invoice(line_items)
    # Return success with no invoice if no line items (negligible proration)
    return { success: true, amount: 0.0, message: 'No charges due to negligible proration' } if line_items.empty?

    # Use common invoice payment service
    payment_service = Enterprise::Billing::V2::InvoicePaymentService.new(account: account)
    payment_service.create_and_pay_invoice(
      line_items: line_items,
      description: 'Proration charges for plan/seat changes',
      metadata: {
        account_id: account.id.to_s,
        type: 'proration'
      }
    )
  end

  def update_account_plan(plan_id, quantity, next_billing_date)
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(plan_id)
    plan_name = plan_definition&.dig(:display_name)

    update_custom_attributes({
                               'pricing_plan_id' => plan_id,
                               'subscribed_quantity' => quantity,
                               'plan_name' => plan_name,
                               'next_billing_date' => next_billing_date
                             })
  end
end
