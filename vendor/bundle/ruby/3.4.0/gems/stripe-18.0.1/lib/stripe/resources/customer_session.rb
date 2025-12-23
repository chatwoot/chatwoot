# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A Customer Session allows you to grant Stripe's frontend SDKs (like Stripe.js) client-side access
  # control over a Customer.
  #
  # Related guides: [Customer Session with the Payment Element](https://docs.stripe.com/payments/accept-a-payment-deferred?platform=web&type=payment#save-payment-methods),
  # [Customer Session with the Pricing Table](https://docs.stripe.com/payments/checkout/pricing-table#customer-session),
  # [Customer Session with the Buy Button](https://docs.stripe.com/payment-links/buy-button#pass-an-existing-customer).
  class CustomerSession < APIResource
    extend Stripe::APIOperations::Create

    OBJECT_NAME = "customer_session"
    def self.object_name
      "customer_session"
    end

    class Components < ::Stripe::StripeObject
      class BuyButton < ::Stripe::StripeObject
        # Whether the buy button is enabled.
        attr_reader :enabled

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CustomerSheet < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # A list of [`allow_redisplay`](https://docs.stripe.com/api/payment_methods/object#payment_method_object-allow_redisplay) values that controls which saved payment methods the customer sheet displays by filtering to only show payment methods with an `allow_redisplay` value that is present in this list.
          #
          # If not specified, defaults to ["always"]. In order to display all saved payment methods, specify ["always", "limited", "unspecified"].
          attr_reader :payment_method_allow_redisplay_filters
          # Controls whether the customer sheet displays the option to remove a saved payment method."
          #
          # Allowing buyers to remove their saved payment methods impacts subscriptions that depend on that payment method. Removing the payment method detaches the [`customer` object](https://docs.stripe.com/api/payment_methods/object#payment_method_object-customer) from that [PaymentMethod](https://docs.stripe.com/api/payment_methods).
          attr_reader :payment_method_remove

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the customer sheet is enabled.
        attr_reader :enabled
        # This hash defines whether the customer sheet supports certain features.
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class MobilePaymentElement < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # A list of [`allow_redisplay`](https://docs.stripe.com/api/payment_methods/object#payment_method_object-allow_redisplay) values that controls which saved payment methods the mobile payment element displays by filtering to only show payment methods with an `allow_redisplay` value that is present in this list.
          #
          # If not specified, defaults to ["always"]. In order to display all saved payment methods, specify ["always", "limited", "unspecified"].
          attr_reader :payment_method_allow_redisplay_filters
          # Controls whether or not the mobile payment element shows saved payment methods.
          attr_reader :payment_method_redisplay
          # Controls whether the mobile payment element displays the option to remove a saved payment method."
          #
          # Allowing buyers to remove their saved payment methods impacts subscriptions that depend on that payment method. Removing the payment method detaches the [`customer` object](https://docs.stripe.com/api/payment_methods/object#payment_method_object-customer) from that [PaymentMethod](https://docs.stripe.com/api/payment_methods).
          attr_reader :payment_method_remove
          # Controls whether the mobile payment element displays a checkbox offering to save a new payment method.
          #
          # If a customer checks the box, the [`allow_redisplay`](https://docs.stripe.com/api/payment_methods/object#payment_method_object-allow_redisplay) value on the PaymentMethod is set to `'always'` at confirmation time. For PaymentIntents, the [`setup_future_usage`](https://docs.stripe.com/api/payment_intents/object#payment_intent_object-setup_future_usage) value is also set to the value defined in `payment_method_save_usage`.
          attr_reader :payment_method_save
          # Allows overriding the value of allow_override when saving a new payment method when payment_method_save is set to disabled. Use values: "always", "limited", or "unspecified".
          #
          # If not specified, defaults to `nil` (no override value).
          attr_reader :payment_method_save_allow_redisplay_override

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the mobile payment element is enabled.
        attr_reader :enabled
        # This hash defines whether the mobile payment element supports certain features.
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PaymentElement < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # A list of [`allow_redisplay`](https://docs.stripe.com/api/payment_methods/object#payment_method_object-allow_redisplay) values that controls which saved payment methods the Payment Element displays by filtering to only show payment methods with an `allow_redisplay` value that is present in this list.
          #
          # If not specified, defaults to ["always"]. In order to display all saved payment methods, specify ["always", "limited", "unspecified"].
          attr_reader :payment_method_allow_redisplay_filters
          # Controls whether or not the Payment Element shows saved payment methods. This parameter defaults to `disabled`.
          attr_reader :payment_method_redisplay
          # Determines the max number of saved payment methods for the Payment Element to display. This parameter defaults to `3`. The maximum redisplay limit is `10`.
          attr_reader :payment_method_redisplay_limit
          # Controls whether the Payment Element displays the option to remove a saved payment method. This parameter defaults to `disabled`.
          #
          # Allowing buyers to remove their saved payment methods impacts subscriptions that depend on that payment method. Removing the payment method detaches the [`customer` object](https://docs.stripe.com/api/payment_methods/object#payment_method_object-customer) from that [PaymentMethod](https://docs.stripe.com/api/payment_methods).
          attr_reader :payment_method_remove
          # Controls whether the Payment Element displays a checkbox offering to save a new payment method. This parameter defaults to `disabled`.
          #
          # If a customer checks the box, the [`allow_redisplay`](https://docs.stripe.com/api/payment_methods/object#payment_method_object-allow_redisplay) value on the PaymentMethod is set to `'always'` at confirmation time. For PaymentIntents, the [`setup_future_usage`](https://docs.stripe.com/api/payment_intents/object#payment_intent_object-setup_future_usage) value is also set to the value defined in `payment_method_save_usage`.
          attr_reader :payment_method_save
          # When using PaymentIntents and the customer checks the save checkbox, this field determines the [`setup_future_usage`](https://docs.stripe.com/api/payment_intents/object#payment_intent_object-setup_future_usage) value used to confirm the PaymentIntent.
          #
          # When using SetupIntents, directly configure the [`usage`](https://docs.stripe.com/api/setup_intents/object#setup_intent_object-usage) value on SetupIntent creation.
          attr_reader :payment_method_save_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the Payment Element is enabled.
        attr_reader :enabled
        # This hash defines whether the Payment Element supports certain features.
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PricingTable < ::Stripe::StripeObject
        # Whether the pricing table is enabled.
        attr_reader :enabled

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # This hash contains whether the buy button is enabled.
      attr_reader :buy_button
      # This hash contains whether the customer sheet is enabled and the features it supports.
      attr_reader :customer_sheet
      # This hash contains whether the mobile payment element is enabled and the features it supports.
      attr_reader :mobile_payment_element
      # This hash contains whether the Payment Element is enabled and the features it supports.
      attr_reader :payment_element
      # This hash contains whether the pricing table is enabled.
      attr_reader :pricing_table

      def self.inner_class_types
        @inner_class_types = {
          buy_button: BuyButton,
          customer_sheet: CustomerSheet,
          mobile_payment_element: MobilePaymentElement,
          payment_element: PaymentElement,
          pricing_table: PricingTable,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The client secret of this Customer Session. Used on the client to set up secure access to the given `customer`.
    #
    # The client secret can be used to provide access to `customer` from your frontend. It should not be stored, logged, or exposed to anyone other than the relevant customer. Make sure that you have TLS enabled on any page that includes the client secret.
    attr_reader :client_secret
    # Configuration for the components supported by this Customer Session.
    attr_reader :components
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The Customer the Customer Session was created for.
    attr_reader :customer
    # The timestamp at which this Customer Session will expire.
    attr_reader :expires_at
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    # Creates a Customer Session object that includes a single-use client secret that you can use on your front-end to grant client-side API access for certain customer resources.
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/customer_sessions",
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { components: Components }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
