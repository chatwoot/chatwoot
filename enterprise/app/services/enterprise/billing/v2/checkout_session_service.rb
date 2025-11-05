# V2 Billing Checkout Service
#
# This service creates Checkout Sessions for V2 Billing subscriptions using
# checkout_items with pricing_plan_subscription_item.
#
class Enterprise::Billing::V2::CheckoutSessionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  # Create a subscription checkout session
  #
  # Creates a Checkout Session with checkout_items containing the V2 Pricing Plan
  # and component configurations for the license fee.
  #
  # @param pricing_plan_id [String] V2 Pricing Plan ID
  # @param quantity [Integer] Number of licenses/seats
  # @return [Hash] { success:, session_id:, redirect_url: } or error
  #
  def create_subscription_checkout(pricing_plan_id:, quantity: 1)
    @pricing_plan_id = pricing_plan_id
    @quantity = quantity.to_i.positive? ? quantity.to_i : 1

    base_url = ENV.fetch('FRONTEND_URL')
    @success_url = "#{base_url}/app/accounts/#{@account.id}/settings/billing?session_id={CHECKOUT_SESSION_ID}"
    @cancel_url = "#{base_url}/app/accounts/#{@account.id}/settings/billing"

    validate_params
    store_pending_subscription_quantity
    create_checkout_session
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe API error: #{e.message}", error: e }
  end

  private

  def validate_params
    raise StandardError, 'Customer ID required. Please create a Stripe customer first.' if stripe_customer_id.blank?
  end

  def store_pending_subscription_quantity
    # Store quantity in custom_attributes for webhook to use
    # This is more reliable than extracting from subscription component_values
    update_custom_attributes({
                               'pending_subscription_quantity' => @quantity,
                               'pending_subscription_pricing_plan' => @pricing_plan_id
                             })
  end

  # Create Checkout Session with checkout_items
  #
  # Uses V2 Pricing Plans directly via checkout_items parameter.
  # This creates a subscription with V2 Billing features automatically.
  #
  def create_checkout_session
    session = super(checkout_session_params, api_version: checkout_stripe_version)
    build_success_response(session)
  end

  def checkout_session_params
    {
      customer: stripe_customer_id,
      checkout_items: build_checkout_items,
      automatic_tax: {
        enabled: true
      },
      customer_update: {
        address: 'auto',
        shipping: 'auto'
      },
      success_url: @success_url,
      cancel_url: @cancel_url,
      metadata: session_metadata
    }
  end

  def build_checkout_items
    lookup_key = extract_license_lookup_key
    raise StandardError, "Lookup key not found for pricing plan #{@pricing_plan_id}" unless lookup_key

    [
      {
        type: 'pricing_plan_subscription_item',
        pricing_plan_subscription_item: {
          pricing_plan: @pricing_plan_id,
          component_configurations: {
            lookup_key => {
              type: 'license_fee_component',
              license_fee_component: {
                quantity: @quantity
              }
            }
          }
        }
      }
    ]
  end

  def extract_license_lookup_key
    Enterprise::Billing::V2::PlanCatalog.lookup_key_for_plan(@pricing_plan_id)
  end

  def session_metadata
    {
      account_id: account.id,
      pricing_plan_id: @pricing_plan_id,
      quantity: @quantity,
      billing_version: 'v2'
    }
  end

  def build_success_response(session)
    session_url = session.respond_to?(:url) ? session.url : session['url']

    {
      success: true,
      redirect_url: session_url
    }
  end
end
