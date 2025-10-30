class Enterprise::Billing::V2::ChangePlanService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::ProrationLineItemBuilder
  include Enterprise::Billing::Concerns::StripeV2ClientHelper
  include Enterprise::Billing::Concerns::PlanProvisioningHelper

  # Change customer's pricing plan and/or seat quantity using invoice line items for proration
  # Instantly applies the change and creates pending invoice line items
  # for prorated charges that will be added to the next invoice
  #
  # @param new_pricing_plan_id [String, nil] The new Stripe pricing plan ID (nil to keep current plan)
  # @param quantity [Integer] The seat quantity for the plan
  # @return [Hash] { success:, message:, proration:, line_items: }
  #
  def change_plan(new_pricing_plan_id: nil, quantity: nil)
    validation_error = validate_parameters(new_pricing_plan_id, quantity)
    return validation_error if validation_error

    with_locked_account do
      perform_subscription_change(new_pricing_plan_id, quantity)
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  end

  private

  def validate_parameters(new_pricing_plan_id, quantity)
    return { success: false, message: 'Must specify either new_pricing_plan_id or quantity' } if new_pricing_plan_id.nil? && quantity.nil?
    return { success: false, message: 'Invalid quantity' } if quantity && !quantity.positive?

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
    old_plan_id = custom_attribute('stripe_pricing_plan_id')
    old_quantity = custom_attribute('subscribed_quantity').to_i
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
    plan_name = Enterprise::Billing::V2::PlanCatalog.definition_for(context[:target_plan_id])&.dig(:display_name) || 'Unknown Plan'
    { success: false, message: "Subscription already has plan #{plan_name} with #{context[:target_quantity]} seat(s)" }
  end

  def execute_change(context)
    # Create billing intent to update the Stripe subscription
    billing_intent = create_change_plan_intent(context[:target_plan_id], context[:target_quantity])
    reserve_billing_intent(billing_intent)
    commit_billing_intent(billing_intent)

    next_billing_date = custom_attribute('next_billing_date')
    proration_data = calculate_proration(
      old_plan_id: context[:old_plan_id],
      new_plan_id: context[:target_plan_id],
      old_quantity: context[:old_quantity],
      new_quantity: context[:target_quantity],
      next_billing_date: next_billing_date
    )
    line_items = build_proration_line_items(context, proration_data)
    invoice_result = create_and_charge_invoice(line_items)

    update_account_plan(context[:target_plan_id], context[:target_quantity], next_billing_date)
    provision_new_plan(context[:target_plan_id]) if context[:plan_changed]

    success_response(context, proration_data, line_items, invoice_result)
  end

  def fetch_subscription_id
    custom_attribute('stripe_subscription_id').tap do |id|
      raise StandardError, 'No pricing plan subscription ID found' if id.blank?
    end
  end

  def fetch_cadence_from_subscription(subscription_id)
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    extract_attribute(subscription, :billing_cadence).tap do |cadence_id|
      raise StandardError, 'No billing cadence found in subscription' if cadence_id.blank?
    end
  end

  def create_change_plan_intent(new_pricing_plan_id, quantity)
    subscription_id = fetch_subscription_id
    cadence_id = fetch_cadence_from_subscription(subscription_id)
    store_next_billing_date(cadence_id)
    plan_version = fetch_new_plan_version(new_pricing_plan_id)
    lookup_key = fetch_plan_lookup_key(new_pricing_plan_id)
    component_config = { lookup_key: lookup_key, quantity: quantity }

    create_billing_intent(
      build_change_plan_params(subscription_id, cadence_id, new_pricing_plan_id, plan_version, component_config)
    )
  end

  def build_change_plan_params(subscription_id, cadence_id, plan_id, plan_version, component_config)
    {
      cadence: cadence_id,
      currency: 'usd',
      actions: [{
        type: 'modify',
        modify: {
          type: 'pricing_plan_subscription_details',
          pricing_plan_subscription_details: {
            pricing_plan_subscription: subscription_id,
            new_pricing_plan: plan_id,
            new_pricing_plan_version: plan_version,
            component_configurations: [component_config]
          }
        }
      }]
    }
  end

  def store_next_billing_date(cadence_id)
    cadence = retrieve_billing_cadence(cadence_id)
    @next_billing_date = extract_attribute(cadence, :next_billing_date)
    update_custom_attributes({ 'next_billing_date' => @next_billing_date })
  end

  def fetch_new_plan_version(plan_id)
    plan = retrieve_pricing_plan(plan_id)
    extract_attribute(plan, :latest_version).tap do |version|
      raise StandardError, "No version found for pricing plan #{plan_id}" if version.blank?
    end
  end

  def fetch_plan_lookup_key(plan_id)
    Enterprise::Billing::V2::PlanCatalog.lookup_key_for_plan(plan_id).tap do |key|
      raise StandardError, "Lookup key not found for pricing plan #{plan_id}" unless key
    end
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

  def success_response(context, proration_data, line_items, invoice_result)
    {
      success: true,
      pricing_plan_id: context[:target_plan_id],
      quantity: context[:target_quantity],
      old_pricing_plan_id: context[:old_plan_id],
      old_quantity: context[:old_quantity],
      plan_changed: context[:plan_changed],
      seats_changed: context[:seats_changed],
      proration: proration_data,
      line_items: line_items,
      invoice: invoice_result,
      total_proration_amount: proration_data[:net_amount],
      message: build_change_message(context)
    }
  end

  def build_change_message(context)
    plan_name = Enterprise::Billing::V2::PlanCatalog.definition_for(context[:target_plan_id])&.dig(:display_name) || 'Unknown Plan'
    base_message = if context[:plan_changed] && context[:seats_changed]
                     "Plan changed to #{plan_name} and seats updated to #{context[:target_quantity]}"
                   elsif context[:plan_changed]
                     "Plan changed to #{plan_name}"
                   else
                     "Seats updated from #{context[:old_quantity]} to #{context[:target_quantity]}"
                   end

    "#{base_message} - billing intent committed and invoice line items created"
  end
end
