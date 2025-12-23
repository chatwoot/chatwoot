# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A payment method domain represents a web domain that you have registered with Stripe.
  # Stripe Elements use registered payment method domains to control where certain payment methods are shown.
  #
  # Related guide: [Payment method domains](https://stripe.com/docs/payments/payment-methods/pmd-registration).
  class PaymentMethodDomain < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_method_domain"
    def self.object_name
      "payment_method_domain"
    end

    class AmazonPay < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ApplePay < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class GooglePay < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Klarna < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Link < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Paypal < ::Stripe::StripeObject
      class StatusDetails < ::Stripe::StripeObject
        # The error message associated with the status of the payment method on the domain.
        attr_reader :error_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The status of the payment method on the domain.
      attr_reader :status
      # Contains additional details about the status of a payment method for a specific payment method domain.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :amazon_pay
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :apple_pay
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The domain name that this payment method domain object represents.
    attr_reader :domain_name
    # Whether this payment method domain is enabled. If the domain is not enabled, payment methods that require a payment method domain will not appear in Elements.
    attr_reader :enabled
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :google_pay
    # Unique identifier for the object.
    attr_reader :id
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :klarna
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :link
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Indicates the status of a specific payment method on a payment method domain.
    attr_reader :paypal

    # Creates a payment method domain.
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/payment_method_domains",
        params: params,
        opts: opts
      )
    end

    # Lists the details of existing payment method domains.
    def self.list(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/payment_method_domains",
        params: params,
        opts: opts
      )
    end

    # Updates an existing payment method domain.
    def self.update(payment_method_domain, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s", { payment_method_domain: CGI.escape(payment_method_domain) }),
        params: params,
        opts: opts
      )
    end

    # Some payment methods might require additional steps to register a domain. If the requirements weren't satisfied when the domain was created, the payment method will be inactive on the domain.
    # The payment method doesn't appear in Elements or Embedded Checkout for this domain until it is active.
    #
    # To activate a payment method on an existing payment method domain, complete the required registration steps specific to the payment method, and then validate the payment method domain with this endpoint.
    #
    # Related guides: [Payment method domains](https://docs.stripe.com/docs/payments/payment-methods/pmd-registration).
    def validate(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s/validate", { payment_method_domain: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Some payment methods might require additional steps to register a domain. If the requirements weren't satisfied when the domain was created, the payment method will be inactive on the domain.
    # The payment method doesn't appear in Elements or Embedded Checkout for this domain until it is active.
    #
    # To activate a payment method on an existing payment method domain, complete the required registration steps specific to the payment method, and then validate the payment method domain with this endpoint.
    #
    # Related guides: [Payment method domains](https://docs.stripe.com/docs/payments/payment-methods/pmd-registration).
    def self.validate(payment_method_domain, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s/validate", { payment_method_domain: CGI.escape(payment_method_domain) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        amazon_pay: AmazonPay,
        apple_pay: ApplePay,
        google_pay: GooglePay,
        klarna: Klarna,
        link: Link,
        paypal: Paypal,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
