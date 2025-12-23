# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module BillingPortal
    # The Billing customer portal is a Stripe-hosted UI for subscription and
    # billing management.
    #
    # A portal configuration describes the functionality and features that you
    # want to provide to your customers through the portal.
    #
    # A portal session describes the instantiation of the customer portal for
    # a particular customer. By visiting the session's URL, the customer
    # can manage their subscriptions and billing details. For security reasons,
    # sessions are short-lived and will expire if the customer does not visit the URL.
    # Create sessions on-demand when customers intend to manage their subscriptions
    # and billing details.
    #
    # Related guide: [Customer management](https://docs.stripe.com/customer-management)
    class Session < APIResource
      extend Stripe::APIOperations::Create

      OBJECT_NAME = "billing_portal.session"
      def self.object_name
        "billing_portal.session"
      end

      class Flow < ::Stripe::StripeObject
        class AfterCompletion < ::Stripe::StripeObject
          class HostedConfirmation < ::Stripe::StripeObject
            # A custom message to display to the customer after the flow is completed.
            attr_reader :custom_message

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Redirect < ::Stripe::StripeObject
            # The URL the customer will be redirected to after the flow is completed.
            attr_reader :return_url

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Configuration when `after_completion.type=hosted_confirmation`.
          attr_reader :hosted_confirmation
          # Configuration when `after_completion.type=redirect`.
          attr_reader :redirect
          # The specified type of behavior after the flow is completed.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { hosted_confirmation: HostedConfirmation, redirect: Redirect }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SubscriptionCancel < ::Stripe::StripeObject
          class Retention < ::Stripe::StripeObject
            class CouponOffer < ::Stripe::StripeObject
              # The ID of the coupon to be offered.
              attr_reader :coupon

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Configuration when `retention.type=coupon_offer`.
            attr_reader :coupon_offer
            # Type of retention strategy that will be used.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = { coupon_offer: CouponOffer }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Specify a retention strategy to be used in the cancellation flow.
          attr_reader :retention
          # The ID of the subscription to be canceled.
          attr_reader :subscription

          def self.inner_class_types
            @inner_class_types = { retention: Retention }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SubscriptionUpdate < ::Stripe::StripeObject
          # The ID of the subscription to be updated.
          attr_reader :subscription

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SubscriptionUpdateConfirm < ::Stripe::StripeObject
          class Discount < ::Stripe::StripeObject
            # The ID of the coupon to apply to this subscription update.
            attr_reader :coupon
            # The ID of a promotion code to apply to this subscription update.
            attr_reader :promotion_code

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Item < ::Stripe::StripeObject
            # The ID of the [subscription item](https://stripe.com/docs/api/subscriptions/object#subscription_object-items-data-id) to be updated.
            attr_reader :id
            # The price the customer should subscribe to through this flow. The price must also be included in the configuration's [`features.subscription_update.products`](https://stripe.com/docs/api/customer_portal/configuration#portal_configuration_object-features-subscription_update-products).
            attr_reader :price
            # [Quantity](https://stripe.com/docs/subscriptions/quantities) for this item that the customer should subscribe to through this flow.
            attr_reader :quantity

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The coupon or promotion code to apply to this subscription update.
          attr_reader :discounts
          # The [subscription item](https://stripe.com/docs/api/subscription_items) to be updated through this flow. Currently, only up to one may be specified and subscriptions with multiple items are not updatable.
          attr_reader :items
          # The ID of the subscription to be updated.
          attr_reader :subscription

          def self.inner_class_types
            @inner_class_types = { discounts: Discount, items: Item }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field after_completion
        attr_reader :after_completion
        # Configuration when `flow.type=subscription_cancel`.
        attr_reader :subscription_cancel
        # Configuration when `flow.type=subscription_update`.
        attr_reader :subscription_update
        # Configuration when `flow.type=subscription_update_confirm`.
        attr_reader :subscription_update_confirm
        # Type of flow that the customer will go through.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {
            after_completion: AfterCompletion,
            subscription_cancel: SubscriptionCancel,
            subscription_update: SubscriptionUpdate,
            subscription_update_confirm: SubscriptionUpdateConfirm,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The configuration used by this session, describing the features available.
      attr_reader :configuration
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The ID of the customer for this session.
      attr_reader :customer
      # Information about a specific flow for the customer to go through. See the [docs](https://stripe.com/docs/customer-management/portal-deep-links) to learn more about using customer portal deep links and flows.
      attr_reader :flow
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The IETF language tag of the locale Customer Portal is displayed in. If blank or auto, the customer’s `preferred_locales` or browser’s locale is used.
      attr_reader :locale
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The account for which the session was created on behalf of. When specified, only subscriptions and invoices with this `on_behalf_of` account appear in the portal. For more information, see the [docs](https://stripe.com/docs/connect/separate-charges-and-transfers#settlement-merchant). Use the [Accounts API](https://stripe.com/docs/api/accounts/object#account_object-settings-branding) to modify the `on_behalf_of` account's branding settings, which the portal displays.
      attr_reader :on_behalf_of
      # The URL to redirect customers to when they click on the portal's link to return to your website.
      attr_reader :return_url
      # The short-lived URL of the session that gives customers access to the customer portal.
      attr_reader :url

      # Creates a session of the customer portal.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/billing_portal/sessions",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { flow: Flow }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
