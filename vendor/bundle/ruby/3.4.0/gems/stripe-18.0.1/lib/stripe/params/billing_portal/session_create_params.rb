# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module BillingPortal
    class SessionCreateParams < ::Stripe::RequestParams
      class FlowData < ::Stripe::RequestParams
        class AfterCompletion < ::Stripe::RequestParams
          class HostedConfirmation < ::Stripe::RequestParams
            # A custom message to display to the customer after the flow is completed.
            attr_accessor :custom_message

            def initialize(custom_message: nil)
              @custom_message = custom_message
            end
          end

          class Redirect < ::Stripe::RequestParams
            # The URL the customer will be redirected to after the flow is completed.
            attr_accessor :return_url

            def initialize(return_url: nil)
              @return_url = return_url
            end
          end
          # Configuration when `after_completion.type=hosted_confirmation`.
          attr_accessor :hosted_confirmation
          # Configuration when `after_completion.type=redirect`.
          attr_accessor :redirect
          # The specified behavior after the flow is completed.
          attr_accessor :type

          def initialize(hosted_confirmation: nil, redirect: nil, type: nil)
            @hosted_confirmation = hosted_confirmation
            @redirect = redirect
            @type = type
          end
        end

        class SubscriptionCancel < ::Stripe::RequestParams
          class Retention < ::Stripe::RequestParams
            class CouponOffer < ::Stripe::RequestParams
              # The ID of the coupon to be offered.
              attr_accessor :coupon

              def initialize(coupon: nil)
                @coupon = coupon
              end
            end
            # Configuration when `retention.type=coupon_offer`.
            attr_accessor :coupon_offer
            # Type of retention strategy to use with the customer.
            attr_accessor :type

            def initialize(coupon_offer: nil, type: nil)
              @coupon_offer = coupon_offer
              @type = type
            end
          end
          # Specify a retention strategy to be used in the cancellation flow.
          attr_accessor :retention
          # The ID of the subscription to be canceled.
          attr_accessor :subscription

          def initialize(retention: nil, subscription: nil)
            @retention = retention
            @subscription = subscription
          end
        end

        class SubscriptionUpdate < ::Stripe::RequestParams
          # The ID of the subscription to be updated.
          attr_accessor :subscription

          def initialize(subscription: nil)
            @subscription = subscription
          end
        end

        class SubscriptionUpdateConfirm < ::Stripe::RequestParams
          class Discount < ::Stripe::RequestParams
            # The ID of the coupon to apply to this subscription update.
            attr_accessor :coupon
            # The ID of a promotion code to apply to this subscription update.
            attr_accessor :promotion_code

            def initialize(coupon: nil, promotion_code: nil)
              @coupon = coupon
              @promotion_code = promotion_code
            end
          end

          class Item < ::Stripe::RequestParams
            # The ID of the [subscription item](https://stripe.com/docs/api/subscriptions/object#subscription_object-items-data-id) to be updated.
            attr_accessor :id
            # The price the customer should subscribe to through this flow. The price must also be included in the configuration's [`features.subscription_update.products`](https://stripe.com/docs/api/customer_portal/configuration#portal_configuration_object-features-subscription_update-products).
            attr_accessor :price
            # [Quantity](https://stripe.com/docs/subscriptions/quantities) for this item that the customer should subscribe to through this flow.
            attr_accessor :quantity

            def initialize(id: nil, price: nil, quantity: nil)
              @id = id
              @price = price
              @quantity = quantity
            end
          end
          # The coupon or promotion code to apply to this subscription update.
          attr_accessor :discounts
          # The [subscription item](https://stripe.com/docs/api/subscription_items) to be updated through this flow. Currently, only up to one may be specified and subscriptions with multiple items are not updatable.
          attr_accessor :items
          # The ID of the subscription to be updated.
          attr_accessor :subscription

          def initialize(discounts: nil, items: nil, subscription: nil)
            @discounts = discounts
            @items = items
            @subscription = subscription
          end
        end
        # Behavior after the flow is completed.
        attr_accessor :after_completion
        # Configuration when `flow_data.type=subscription_cancel`.
        attr_accessor :subscription_cancel
        # Configuration when `flow_data.type=subscription_update`.
        attr_accessor :subscription_update
        # Configuration when `flow_data.type=subscription_update_confirm`.
        attr_accessor :subscription_update_confirm
        # Type of flow that the customer will go through.
        attr_accessor :type

        def initialize(
          after_completion: nil,
          subscription_cancel: nil,
          subscription_update: nil,
          subscription_update_confirm: nil,
          type: nil
        )
          @after_completion = after_completion
          @subscription_cancel = subscription_cancel
          @subscription_update = subscription_update
          @subscription_update_confirm = subscription_update_confirm
          @type = type
        end
      end
      # The ID of an existing [configuration](https://stripe.com/docs/api/customer_portal/configuration) to use for this session, describing its functionality and features. If not specified, the session uses the default configuration.
      attr_accessor :configuration
      # The ID of an existing customer.
      attr_accessor :customer
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Information about a specific flow for the customer to go through. See the [docs](https://stripe.com/docs/customer-management/portal-deep-links) to learn more about using customer portal deep links and flows.
      attr_accessor :flow_data
      # The IETF language tag of the locale customer portal is displayed in. If blank or auto, the customer’s `preferred_locales` or browser’s locale is used.
      attr_accessor :locale
      # The `on_behalf_of` account to use for this session. When specified, only subscriptions and invoices with this `on_behalf_of` account appear in the portal. For more information, see the [docs](https://stripe.com/docs/connect/separate-charges-and-transfers#settlement-merchant). Use the [Accounts API](https://stripe.com/docs/api/accounts/object#account_object-settings-branding) to modify the `on_behalf_of` account's branding settings, which the portal displays.
      attr_accessor :on_behalf_of
      # The default URL to redirect customers to when they click on the portal's link to return to your website.
      attr_accessor :return_url

      def initialize(
        configuration: nil,
        customer: nil,
        expand: nil,
        flow_data: nil,
        locale: nil,
        on_behalf_of: nil,
        return_url: nil
      )
        @configuration = configuration
        @customer = customer
        @expand = expand
        @flow_data = flow_data
        @locale = locale
        @on_behalf_of = on_behalf_of
        @return_url = return_url
      end
    end
  end
end
