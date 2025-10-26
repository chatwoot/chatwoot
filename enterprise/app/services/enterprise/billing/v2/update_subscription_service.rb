class Enterprise::Billing::V2::UpdateSubscriptionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  # Update subscription to a new plan with proration
  #
  # @param pricing_plan_id [String] New V2 Pricing Plan ID
  # @param quantity [Integer] Number of licenses/seats
  # @return [Hash] { success:, subscription_id:, prorated: } or error
  #
  def update_subscription(pricing_plan_id:, quantity: 1)
    @pricing_plan_id = pricing_plan_id
    @quantity = quantity.to_i.positive? ? quantity.to_i : 1

    validate_params
    store_pending_subscription_details
    update_stripe_subscription
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe API error: #{e.message}", error: e }
  rescue StandardError => e
    { success: false, message: "Update error: #{e.message}", error: e }
  end

  private

  def validate_params
    raise StandardError, 'Pricing Plan ID required' if @pricing_plan_id.blank?
    raise StandardError, 'Not a V2 billing account' unless v2_enabled?
    raise StandardError, 'No active subscription to update. Please subscribe to a plan first.' unless active_subscription?
  end

  def v2_enabled?
    custom_attribute('stripe_billing_version')&.to_i == 2
  end

  def active_subscription?
    # Both subscription_status and subscription_id must be present
    custom_attribute('subscription_status') == 'active' &&
      custom_attribute('stripe_subscription_id').present?
  end

  def store_pending_subscription_details
    # Store for webhook to use when it fires
    update_custom_attributes({
                               'pending_subscription_quantity' => @quantity,
                               'pending_subscription_pricing_plan' => @pricing_plan_id
                             })
  end

  def update_stripe_subscription
    subscription_id = custom_attribute('stripe_subscription_id')
    lookup_key = extract_license_lookup_key
    raise StandardError, "Lookup key not found for pricing plan #{@pricing_plan_id}" unless lookup_key

    # Get the current subscription to find the subscription item ID
    current_subscription = fetch_current_subscription(subscription_id)
    item_id = extract_subscription_item_id(current_subscription)

    # Update the subscription with new price and quantity
    updated_subscription = StripeV2Client.request(
      :post,
      "/v1/subscriptions/#{subscription_id}",
      subscription_update_params(item_id, lookup_key),
      stripe_api_options
    )

    build_success_response(updated_subscription)
  end

  def fetch_current_subscription(subscription_id)
    StripeV2Client.request(
      :get,
      "/v1/subscriptions/#{subscription_id}",
      {},
      stripe_api_options
    )
  end

  def extract_subscription_item_id(subscription)
    # Get the first subscription item (we only have one item per subscription)
    items = subscription.respond_to?(:items) ? subscription.items : subscription['items']
    data = items.respond_to?(:data) ? items.data : items['data']
    first_item = data&.first

    raise StandardError, 'No subscription items found' unless first_item

    first_item.respond_to?(:id) ? first_item.id : first_item['id']
  end

  def subscription_update_params(item_id, lookup_key)
    price_id = "price_#{lookup_key}"

    {
      items: [
        {
          id: item_id,
          price: price_id,
          quantity: @quantity
        }
      ],
      proration_behavior: 'create_prorations',
      metadata: {
        account_id: account.id,
        pricing_plan_id: @pricing_plan_id,
        quantity: @quantity,
        billing_version: 'v2'
      }
    }
  end

  def extract_license_lookup_key
    Enterprise::Billing::V2::PlanCatalog.lookup_key_for_plan(@pricing_plan_id)
  end

  def build_success_response(subscription)
    subscription_id = subscription.respond_to?(:id) ? subscription.id : subscription['id']

    {
      success: true,
      subscription_id: subscription_id,
      prorated: true,
      message: 'Subscription updated successfully with prorations'
    }
  end

  def stripe_api_options
    {
      api_key: ENV.fetch('STRIPE_SECRET_KEY', nil),
      stripe_version: '2025-08-27.preview'
    }
  end
end
