# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    # When an [issued card](https://stripe.com/docs/issuing) is used to make a purchase, an Issuing `Authorization`
    # object is created. [Authorizations](https://stripe.com/docs/issuing/purchases/authorizations) must be approved for the
    # purchase to be completed successfully.
    #
    # Related guide: [Issued card authorizations](https://stripe.com/docs/issuing/purchases/authorizations)
    class Authorization < APIResource
      extend Gem::Deprecate
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.authorization"
      def self.object_name
        "issuing.authorization"
      end

      class AmountDetails < ::Stripe::StripeObject
        # The fee charged by the ATM for the cash withdrawal.
        attr_reader :atm_fee
        # The amount of cash requested by the cardholder.
        attr_reader :cashback_amount

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Fleet < ::Stripe::StripeObject
        class CardholderPromptData < ::Stripe::StripeObject
          # [Deprecated] An alphanumeric ID, though typical point of sales only support numeric entry. The card program can be configured to prompt for a vehicle ID, driver ID, or generic ID.
          attr_reader :alphanumeric_id
          # Driver ID.
          attr_reader :driver_id
          # Odometer reading.
          attr_reader :odometer
          # An alphanumeric ID. This field is used when a vehicle ID, driver ID, or generic ID is entered by the cardholder, but the merchant or card network did not specify the prompt type.
          attr_reader :unspecified_id
          # User ID.
          attr_reader :user_id
          # Vehicle number.
          attr_reader :vehicle_number

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ReportedBreakdown < ::Stripe::StripeObject
          class Fuel < ::Stripe::StripeObject
            # Gross fuel amount that should equal Fuel Quantity multiplied by Fuel Unit Cost, inclusive of taxes.
            attr_reader :gross_amount_decimal

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class NonFuel < ::Stripe::StripeObject
            # Gross non-fuel amount that should equal the sum of the line items, inclusive of taxes.
            attr_reader :gross_amount_decimal

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Tax < ::Stripe::StripeObject
            # Amount of state or provincial Sales Tax included in the transaction amount. `null` if not reported by merchant or not subject to tax.
            attr_reader :local_amount_decimal
            # Amount of national Sales Tax or VAT included in the transaction amount. `null` if not reported by merchant or not subject to tax.
            attr_reader :national_amount_decimal

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Breakdown of fuel portion of the purchase.
          attr_reader :fuel
          # Breakdown of non-fuel portion of the purchase.
          attr_reader :non_fuel
          # Information about tax included in this transaction.
          attr_reader :tax

          def self.inner_class_types
            @inner_class_types = { fuel: Fuel, non_fuel: NonFuel, tax: Tax }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Answers to prompts presented to the cardholder at the point of sale. Prompted fields vary depending on the configuration of your physical fleet cards. Typical points of sale support only numeric entry.
        attr_reader :cardholder_prompt_data
        # The type of purchase.
        attr_reader :purchase_type
        # More information about the total amount. Typically this information is received from the merchant after the authorization has been approved and the fuel dispensed. This information is not guaranteed to be accurate as some merchants may provide unreliable data.
        attr_reader :reported_breakdown
        # The type of fuel service.
        attr_reader :service_type

        def self.inner_class_types
          @inner_class_types = {
            cardholder_prompt_data: CardholderPromptData,
            reported_breakdown: ReportedBreakdown,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FraudChallenge < ::Stripe::StripeObject
        # The method by which the fraud challenge was delivered to the cardholder.
        attr_reader :channel
        # The status of the fraud challenge.
        attr_reader :status
        # If the challenge is not deliverable, the reason why.
        attr_reader :undeliverable_reason

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Fuel < ::Stripe::StripeObject
        # [Conexxus Payment System Product Code](https://www.conexxus.org/conexxus-payment-system-product-codes) identifying the primary fuel product purchased.
        attr_reader :industry_product_code
        # The quantity of `unit`s of fuel that was dispensed, represented as a decimal string with at most 12 decimal places.
        attr_reader :quantity_decimal
        # The type of fuel that was purchased.
        attr_reader :type
        # The units for `quantity_decimal`.
        attr_reader :unit
        # The cost in cents per each unit of fuel, represented as a decimal string with at most 12 decimal places.
        attr_reader :unit_cost_decimal

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class MerchantData < ::Stripe::StripeObject
        # A categorization of the seller's type of business. See our [merchant categories guide](https://stripe.com/docs/issuing/merchant-categories) for a list of possible values.
        attr_reader :category
        # The merchant category code for the seller’s business
        attr_reader :category_code
        # City where the seller is located
        attr_reader :city
        # Country where the seller is located
        attr_reader :country
        # Name of the seller
        attr_reader :name
        # Identifier assigned to the seller by the card network. Different card networks may assign different network_id fields to the same merchant.
        attr_reader :network_id
        # Postal code where the seller is located
        attr_reader :postal_code
        # State where the seller is located
        attr_reader :state
        # The seller's tax identification number. Currently populated for French merchants only.
        attr_reader :tax_id
        # An ID assigned by the seller to the location of the sale.
        attr_reader :terminal_id
        # URL provided by the merchant on a 3DS request
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NetworkData < ::Stripe::StripeObject
        # Identifier assigned to the acquirer by the card network. Sometimes this value is not provided by the network; in this case, the value will be `null`.
        attr_reader :acquiring_institution_id
        # The System Trace Audit Number (STAN) is a 6-digit identifier assigned by the acquirer. Prefer `network_data.transaction_id` if present, unless you have special requirements.
        attr_reader :system_trace_audit_number
        # Unique identifier for the authorization assigned by the card network used to match subsequent messages, disputes, and transactions.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PendingRequest < ::Stripe::StripeObject
        class AmountDetails < ::Stripe::StripeObject
          # The fee charged by the ATM for the cash withdrawal.
          attr_reader :atm_fee
          # The amount of cash requested by the cardholder.
          attr_reader :cashback_amount

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The additional amount Stripe will hold if the authorization is approved, in the card's [currency](https://stripe.com/docs/api#issuing_authorization_object-pending-request-currency) and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :amount
        # Detailed breakdown of amount components. These amounts are denominated in `currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :amount_details
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_reader :currency
        # If set `true`, you may provide [amount](https://stripe.com/docs/api/issuing/authorizations/approve#approve_issuing_authorization-amount) to control how much to hold for the authorization.
        attr_reader :is_amount_controllable
        # The amount the merchant is requesting to be authorized in the `merchant_currency`. The amount is in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :merchant_amount
        # The local currency the merchant is requesting to authorize.
        attr_reader :merchant_currency
        # The card network's estimate of the likelihood that an authorization is fraudulent. Takes on values between 1 and 99.
        attr_reader :network_risk_score

        def self.inner_class_types
          @inner_class_types = { amount_details: AmountDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RequestHistory < ::Stripe::StripeObject
        class AmountDetails < ::Stripe::StripeObject
          # The fee charged by the ATM for the cash withdrawal.
          attr_reader :atm_fee
          # The amount of cash requested by the cardholder.
          attr_reader :cashback_amount

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The `pending_request.amount` at the time of the request, presented in your card's currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Stripe held this amount from your account to fund the authorization if the request was approved.
        attr_reader :amount
        # Detailed breakdown of amount components. These amounts are denominated in `currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :amount_details
        # Whether this request was approved.
        attr_reader :approved
        # A code created by Stripe which is shared with the merchant to validate the authorization. This field will be populated if the authorization message was approved. The code typically starts with the letter "S", followed by a six-digit number. For example, "S498162". Please note that the code is not guaranteed to be unique across authorizations.
        attr_reader :authorization_code
        # Time at which the object was created. Measured in seconds since the Unix epoch.
        attr_reader :created
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_reader :currency
        # The `pending_request.merchant_amount` at the time of the request, presented in the `merchant_currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :merchant_amount
        # The currency that was collected by the merchant and presented to the cardholder for the authorization. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_reader :merchant_currency
        # The card network's estimate of the likelihood that an authorization is fraudulent. Takes on values between 1 and 99.
        attr_reader :network_risk_score
        # When an authorization is approved or declined by you or by Stripe, this field provides additional detail on the reason for the outcome.
        attr_reader :reason
        # If the `request_history.reason` is `webhook_error` because the direct webhook response is invalid (for example, parsing errors or missing parameters), we surface a more detailed error message via this field.
        attr_reader :reason_message
        # Time when the card network received an authorization request from the acquirer in UTC. Referred to by networks as transmission time.
        attr_reader :requested_at

        def self.inner_class_types
          @inner_class_types = { amount_details: AmountDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Treasury < ::Stripe::StripeObject
        # The array of [ReceivedCredits](https://stripe.com/docs/api/treasury/received_credits) associated with this authorization
        attr_reader :received_credits
        # The array of [ReceivedDebits](https://stripe.com/docs/api/treasury/received_debits) associated with this authorization
        attr_reader :received_debits
        # The Treasury [Transaction](https://stripe.com/docs/api/treasury/transactions) associated with this authorization
        attr_reader :transaction

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class VerificationData < ::Stripe::StripeObject
        class AuthenticationExemption < ::Stripe::StripeObject
          # The entity that requested the exemption, either the acquiring merchant or the Issuing user.
          attr_reader :claimed_by
          # The specific exemption claimed for this authorization.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ThreeDSecure < ::Stripe::StripeObject
          # The outcome of the 3D Secure authentication request.
          attr_reader :result

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the cardholder provided an address first line and if it matched the cardholder’s `billing.address.line1`.
        attr_reader :address_line1_check
        # Whether the cardholder provided a postal code and if it matched the cardholder’s `billing.address.postal_code`.
        attr_reader :address_postal_code_check
        # The exemption applied to this authorization.
        attr_reader :authentication_exemption
        # Whether the cardholder provided a CVC and if it matched Stripe’s record.
        attr_reader :cvc_check
        # Whether the cardholder provided an expiry date and if it matched Stripe’s record.
        attr_reader :expiry_check
        # The postal code submitted as part of the authorization used for postal code verification.
        attr_reader :postal_code
        # 3D Secure details.
        attr_reader :three_d_secure

        def self.inner_class_types
          @inner_class_types = {
            authentication_exemption: AuthenticationExemption,
            three_d_secure: ThreeDSecure,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The total amount that was authorized or rejected. This amount is in `currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). `amount` should be the same as `merchant_amount`, unless `currency` and `merchant_currency` are different.
      attr_reader :amount
      # Detailed breakdown of amount components. These amounts are denominated in `currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_reader :amount_details
      # Whether the authorization has been approved.
      attr_reader :approved
      # How the card details were provided.
      attr_reader :authorization_method
      # List of balance transactions associated with this authorization.
      attr_reader :balance_transactions
      # You can [create physical or virtual cards](https://stripe.com/docs/issuing) that are issued to cardholders.
      attr_reader :card
      # The cardholder to whom this authorization belongs.
      attr_reader :cardholder
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The currency of the cardholder. This currency can be different from the currency presented at authorization and the `merchant_currency` field on this authorization. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # Fleet-specific information for authorizations using Fleet cards.
      attr_reader :fleet
      # Fraud challenges sent to the cardholder, if this authorization was declined for fraud risk reasons.
      attr_reader :fraud_challenges
      # Information about fuel that was purchased with this transaction. Typically this information is received from the merchant after the authorization has been approved and the fuel dispensed.
      attr_reader :fuel
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The total amount that was authorized or rejected. This amount is in the `merchant_currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). `merchant_amount` should be the same as `amount`, unless `merchant_currency` and `currency` are different.
      attr_reader :merchant_amount
      # The local currency that was presented to the cardholder for the authorization. This currency can be different from the cardholder currency and the `currency` field on this authorization. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :merchant_currency
      # Attribute for field merchant_data
      attr_reader :merchant_data
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # Details about the authorization, such as identifiers, set by the card network.
      attr_reader :network_data
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The pending authorization request. This field will only be non-null during an `issuing_authorization.request` webhook.
      attr_reader :pending_request
      # History of every time a `pending_request` authorization was approved/declined, either by you directly or by Stripe (e.g. based on your spending_controls). If the merchant changes the authorization by performing an incremental authorization, you can look at this field to see the previous requests for the authorization. This field can be helpful in determining why a given authorization was approved/declined.
      attr_reader :request_history
      # The current status of the authorization in its lifecycle.
      attr_reader :status
      # [Token](https://stripe.com/docs/api/issuing/tokens/object) object used for this authorization. If a network token was not used for this authorization, this field will be null.
      attr_reader :token
      # List of [transactions](https://stripe.com/docs/api/issuing/transactions) associated with this authorization.
      attr_reader :transactions
      # [Treasury](https://stripe.com/docs/api/treasury) details related to this authorization if it was created on a [FinancialAccount](https://stripe.com/docs/api/treasury/financial_accounts).
      attr_reader :treasury
      # Attribute for field verification_data
      attr_reader :verification_data
      # Whether the authorization bypassed fraud risk checks because the cardholder has previously completed a fraud challenge on a similar high-risk authorization from the same merchant.
      attr_reader :verified_by_fraud_challenge
      # The digital wallet used for this transaction. One of `apple_pay`, `google_pay`, or `samsung_pay`. Will populate as `null` when no digital wallet was utilized.
      attr_reader :wallet

      # [Deprecated] Approves a pending Issuing Authorization object. This request should be made within the timeout window of the [real-time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to approve an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def approve(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/approve", { authorization: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      deprecate :approve, :none, 2024, 3
      # [Deprecated] Approves a pending Issuing Authorization object. This request should be made within the timeout window of the [real-time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to approve an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def self.approve(authorization, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/approve", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts
        )
      end

      class << self
        extend Gem::Deprecate
        deprecate :approve, :none, 2024, 3
      end

      # [Deprecated] Declines a pending Issuing Authorization object. This request should be made within the timeout window of the [real time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to decline an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def decline(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/decline", { authorization: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      deprecate :decline, :none, 2024, 3
      # [Deprecated] Declines a pending Issuing Authorization object. This request should be made within the timeout window of the [real time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to decline an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def self.decline(authorization, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/decline", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts
        )
      end

      class << self
        extend Gem::Deprecate
        deprecate :decline, :none, 2024, 3
      end

      # Returns a list of Issuing Authorization objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/issuing/authorizations",
          params: params,
          opts: opts
        )
      end

      # Updates the specified Issuing Authorization object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def self.update(authorization, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = Authorization
        def self.resource_class
          "Authorization"
        end

        # Capture a test-mode authorization.
        def self.capture(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/capture", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Capture a test-mode authorization.
        def capture(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/capture", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Create a test-mode authorization.
        def self.create(params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: "/v1/test_helpers/issuing/authorizations",
            params: params,
            opts: opts
          )
        end

        # Expire a test-mode Authorization.
        def self.expire(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/expire", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Expire a test-mode Authorization.
        def expire(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/expire", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Finalize the amount on an Authorization prior to capture, when the initial authorization was for an estimated amount.
        def self.finalize_amount(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/finalize_amount", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Finalize the amount on an Authorization prior to capture, when the initial authorization was for an estimated amount.
        def finalize_amount(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/finalize_amount", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Increment a test-mode Authorization.
        def self.increment(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/increment", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Increment a test-mode Authorization.
        def increment(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/increment", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Respond to a fraud challenge on a testmode Issuing authorization, simulating either a confirmation of fraud or a correction of legitimacy.
        def self.respond(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/fraud_challenges/respond", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Respond to a fraud challenge on a testmode Issuing authorization, simulating either a confirmation of fraud or a correction of legitimacy.
        def respond(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/fraud_challenges/respond", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Reverse a test-mode Authorization.
        def self.reverse(authorization, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/reverse", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts
          )
        end

        # Reverse a test-mode Authorization.
        def reverse(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/reverse", { authorization: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          amount_details: AmountDetails,
          fleet: Fleet,
          fraud_challenges: FraudChallenge,
          fuel: Fuel,
          merchant_data: MerchantData,
          network_data: NetworkData,
          pending_request: PendingRequest,
          request_history: RequestHistory,
          treasury: Treasury,
          verification_data: VerificationData,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
