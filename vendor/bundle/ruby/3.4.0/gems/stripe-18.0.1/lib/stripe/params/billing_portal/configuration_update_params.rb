# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module BillingPortal
    class ConfigurationUpdateParams < ::Stripe::RequestParams
      class BusinessProfile < ::Stripe::RequestParams
        # The messaging shown to customers in the portal.
        attr_accessor :headline
        # A link to the business’s publicly available privacy policy.
        attr_accessor :privacy_policy_url
        # A link to the business’s publicly available terms of service.
        attr_accessor :terms_of_service_url

        def initialize(headline: nil, privacy_policy_url: nil, terms_of_service_url: nil)
          @headline = headline
          @privacy_policy_url = privacy_policy_url
          @terms_of_service_url = terms_of_service_url
        end
      end

      class Features < ::Stripe::RequestParams
        class CustomerUpdate < ::Stripe::RequestParams
          # The types of customer updates that are supported. When empty, customers are not updateable.
          attr_accessor :allowed_updates
          # Whether the feature is enabled.
          attr_accessor :enabled

          def initialize(allowed_updates: nil, enabled: nil)
            @allowed_updates = allowed_updates
            @enabled = enabled
          end
        end

        class InvoiceHistory < ::Stripe::RequestParams
          # Whether the feature is enabled.
          attr_accessor :enabled

          def initialize(enabled: nil)
            @enabled = enabled
          end
        end

        class PaymentMethodUpdate < ::Stripe::RequestParams
          # Whether the feature is enabled.
          attr_accessor :enabled
          # The [Payment Method Configuration](/api/payment_method_configurations) to use for this portal session. When specified, customers will be able to update their payment method to one of the options specified by the payment method configuration. If not set or set to an empty string, the default payment method configuration is used.
          attr_accessor :payment_method_configuration

          def initialize(enabled: nil, payment_method_configuration: nil)
            @enabled = enabled
            @payment_method_configuration = payment_method_configuration
          end
        end

        class SubscriptionCancel < ::Stripe::RequestParams
          class CancellationReason < ::Stripe::RequestParams
            # Whether the feature is enabled.
            attr_accessor :enabled
            # Which cancellation reasons will be given as options to the customer.
            attr_accessor :options

            def initialize(enabled: nil, options: nil)
              @enabled = enabled
              @options = options
            end
          end
          # Whether the cancellation reasons will be collected in the portal and which options are exposed to the customer
          attr_accessor :cancellation_reason
          # Whether the feature is enabled.
          attr_accessor :enabled
          # Whether to cancel subscriptions immediately or at the end of the billing period.
          attr_accessor :mode
          # Whether to create prorations when canceling subscriptions. Possible values are `none` and `create_prorations`, which is only compatible with `mode=immediately`. Passing `always_invoice` will result in an error. No prorations are generated when canceling a subscription at the end of its natural billing period.
          attr_accessor :proration_behavior

          def initialize(cancellation_reason: nil, enabled: nil, mode: nil, proration_behavior: nil)
            @cancellation_reason = cancellation_reason
            @enabled = enabled
            @mode = mode
            @proration_behavior = proration_behavior
          end
        end

        class SubscriptionUpdate < ::Stripe::RequestParams
          class Product < ::Stripe::RequestParams
            class AdjustableQuantity < ::Stripe::RequestParams
              # Set to true if the quantity can be adjusted to any non-negative integer.
              attr_accessor :enabled
              # The maximum quantity that can be set for the product.
              attr_accessor :maximum
              # The minimum quantity that can be set for the product.
              attr_accessor :minimum

              def initialize(enabled: nil, maximum: nil, minimum: nil)
                @enabled = enabled
                @maximum = maximum
                @minimum = minimum
              end
            end
            # Control whether the quantity of the product can be adjusted.
            attr_accessor :adjustable_quantity
            # The list of price IDs for the product that a subscription can be updated to.
            attr_accessor :prices
            # The product id.
            attr_accessor :product

            def initialize(adjustable_quantity: nil, prices: nil, product: nil)
              @adjustable_quantity = adjustable_quantity
              @prices = prices
              @product = product
            end
          end

          class ScheduleAtPeriodEnd < ::Stripe::RequestParams
            class Condition < ::Stripe::RequestParams
              # The type of condition.
              attr_accessor :type

              def initialize(type: nil)
                @type = type
              end
            end
            # List of conditions. When any condition is true, the update will be scheduled at the end of the current period.
            attr_accessor :conditions

            def initialize(conditions: nil)
              @conditions = conditions
            end
          end
          # The types of subscription updates that are supported. When empty, subscriptions are not updateable.
          attr_accessor :default_allowed_updates
          # Whether the feature is enabled.
          attr_accessor :enabled
          # The list of up to 10 products that support subscription updates.
          attr_accessor :products
          # Determines how to handle prorations resulting from subscription updates. Valid values are `none`, `create_prorations`, and `always_invoice`.
          attr_accessor :proration_behavior
          # Setting to control when an update should be scheduled at the end of the period instead of applying immediately.
          attr_accessor :schedule_at_period_end
          # The behavior when updating a subscription that is trialing.
          attr_accessor :trial_update_behavior

          def initialize(
            default_allowed_updates: nil,
            enabled: nil,
            products: nil,
            proration_behavior: nil,
            schedule_at_period_end: nil,
            trial_update_behavior: nil
          )
            @default_allowed_updates = default_allowed_updates
            @enabled = enabled
            @products = products
            @proration_behavior = proration_behavior
            @schedule_at_period_end = schedule_at_period_end
            @trial_update_behavior = trial_update_behavior
          end
        end
        # Information about updating the customer details in the portal.
        attr_accessor :customer_update
        # Information about showing the billing history in the portal.
        attr_accessor :invoice_history
        # Information about updating payment methods in the portal.
        attr_accessor :payment_method_update
        # Information about canceling subscriptions in the portal.
        attr_accessor :subscription_cancel
        # Information about updating subscriptions in the portal.
        attr_accessor :subscription_update

        def initialize(
          customer_update: nil,
          invoice_history: nil,
          payment_method_update: nil,
          subscription_cancel: nil,
          subscription_update: nil
        )
          @customer_update = customer_update
          @invoice_history = invoice_history
          @payment_method_update = payment_method_update
          @subscription_cancel = subscription_cancel
          @subscription_update = subscription_update
        end
      end

      class LoginPage < ::Stripe::RequestParams
        # Set to `true` to generate a shareable URL [`login_page.url`](https://stripe.com/docs/api/customer_portal/configuration#portal_configuration_object-login_page-url) that will take your customers to a hosted login page for the customer portal.
        #
        # Set to `false` to deactivate the `login_page.url`.
        attr_accessor :enabled

        def initialize(enabled: nil)
          @enabled = enabled
        end
      end
      # Whether the configuration is active and can be used to create portal sessions.
      attr_accessor :active
      # The business information shown to customers in the portal.
      attr_accessor :business_profile
      # The default URL to redirect customers to when they click on the portal's link to return to your website. This can be [overriden](https://stripe.com/docs/api/customer_portal/sessions/create#create_portal_session-return_url) when creating the session.
      attr_accessor :default_return_url
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Information about the features available in the portal.
      attr_accessor :features
      # The hosted login page for this configuration. Learn more about the portal login page in our [integration docs](https://stripe.com/docs/billing/subscriptions/integrating-customer-portal#share).
      attr_accessor :login_page
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The name of the configuration.
      attr_accessor :name

      def initialize(
        active: nil,
        business_profile: nil,
        default_return_url: nil,
        expand: nil,
        features: nil,
        login_page: nil,
        metadata: nil,
        name: nil
      )
        @active = active
        @business_profile = business_profile
        @default_return_url = default_return_url
        @expand = expand
        @features = features
        @login_page = login_page
        @metadata = metadata
        @name = name
      end
    end
  end
end
