class Enterprise::Billing::V2::CheckoutSessionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  def create_subscription_checkout(pricing_plan_id:, quantity: 1)
    @pricing_plan_id = pricing_plan_id
    @quantity = quantity.to_i.positive? ? quantity.to_i : 1

    base_url = ENV.fetch('FRONTEND_URL')
    @success_url = "#{base_url}/app/accounts/#{@account.id}/settings/billing?session_id={CHECKOUT_SESSION_ID}"
    @cancel_url = "#{base_url}/app/accounts/#{@account.id}/settings/billing"

    validate_params
    store_pending_subscription_quantity
    session = create_checkout_session(checkout_session_params)
    session.url
  end

  private

  def validate_params
    raise StandardError, I18n.t('errors.enterprise.billing.stripe_customer_required') if stripe_customer_id.blank?
  end

  def store_pending_subscription_quantity
    # Store quantity in custom_attributes for webhook to use
    # This is more reliable than extracting from subscription component_values
    update_custom_attributes({
                               'pending_subscription_quantity' => @quantity,
                               'pending_subscription_pricing_plan' => @pricing_plan_id
                             })
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
    raise StandardError, I18n.t('errors.enterprise.billing.lookup_key_not_found', pricing_plan_id: @pricing_plan_id) unless lookup_key

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
end
