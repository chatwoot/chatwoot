# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # The `Charge` object represents a single attempt to move money into your Stripe account.
  # PaymentIntent confirmation is the most common way to create Charges, but [Account Debits](https://stripe.com/docs/connect/account-debits) may also create Charges.
  # Some legacy payment flows create Charges directly, which is not recommended for new integrations.
  class Charge < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::NestedResource
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "charge"
    def self.object_name
      "charge"
    end

    nested_resource_class_methods :refund, operations: %i[retrieve list]

    class BillingDetails < ::Stripe::StripeObject
      class Address < ::Stripe::StripeObject
        # City, district, suburb, town, or village.
        attr_reader :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_reader :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_reader :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_reader :line2
        # ZIP or postal code.
        attr_reader :postal_code
        # State, county, province, or region.
        attr_reader :state

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Billing address.
      attr_reader :address
      # Email address.
      attr_reader :email
      # Full name.
      attr_reader :name
      # Billing phone number (including extension).
      attr_reader :phone
      # Taxpayer identification number. Used only for transactions between LATAM buyers and non-LATAM sellers.
      attr_reader :tax_id

      def self.inner_class_types
        @inner_class_types = { address: Address }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class FraudDetails < ::Stripe::StripeObject
      # Assessments from Stripe. If set, the value is `fraudulent`.
      attr_reader :stripe_report
      # Assessments reported by you. If set, possible values of are `safe` and `fraudulent`.
      attr_reader :user_report

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Level3 < ::Stripe::StripeObject
      class LineItem < ::Stripe::StripeObject
        # Attribute for field discount_amount
        attr_reader :discount_amount
        # Attribute for field product_code
        attr_reader :product_code
        # Attribute for field product_description
        attr_reader :product_description
        # Attribute for field quantity
        attr_reader :quantity
        # Attribute for field tax_amount
        attr_reader :tax_amount
        # Attribute for field unit_cost
        attr_reader :unit_cost

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field customer_reference
      attr_reader :customer_reference
      # Attribute for field line_items
      attr_reader :line_items
      # Attribute for field merchant_reference
      attr_reader :merchant_reference
      # Attribute for field shipping_address_zip
      attr_reader :shipping_address_zip
      # Attribute for field shipping_amount
      attr_reader :shipping_amount
      # Attribute for field shipping_from_zip
      attr_reader :shipping_from_zip

      def self.inner_class_types
        @inner_class_types = { line_items: LineItem }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Outcome < ::Stripe::StripeObject
      class Rule < ::Stripe::StripeObject
        # The action taken on the payment.
        attr_reader :action
        # Unique identifier for the object.
        attr_reader :id
        # The predicate to evaluate the payment against.
        attr_reader :predicate

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # An enumerated value providing a more detailed explanation on [how to proceed with an error](https://stripe.com/docs/declines#retrying-issuer-declines).
      attr_reader :advice_code
      # For charges declined by the network, a 2 digit code which indicates the advice returned by the network on how to proceed with an error.
      attr_reader :network_advice_code
      # For charges declined by the network, an alphanumeric code which indicates the reason the charge failed.
      attr_reader :network_decline_code
      # Possible values are `approved_by_network`, `declined_by_network`, `not_sent_to_network`, and `reversed_after_approval`. The value `reversed_after_approval` indicates the payment was [blocked by Stripe](https://stripe.com/docs/declines#blocked-payments) after bank authorization, and may temporarily appear as "pending" on a cardholder's statement.
      attr_reader :network_status
      # An enumerated value providing a more detailed explanation of the outcome's `type`. Charges blocked by Radar's default block rule have the value `highest_risk_level`. Charges placed in review by Radar's default review rule have the value `elevated_risk_level`. Charges blocked because the payment is unlikely to be authorized have the value `low_probability_of_authorization`. Charges authorized, blocked, or placed in review by custom rules have the value `rule`. See [understanding declines](https://stripe.com/docs/declines) for more details.
      attr_reader :reason
      # Stripe Radar's evaluation of the riskiness of the payment. Possible values for evaluated payments are `normal`, `elevated`, `highest`. For non-card payments, and card-based payments predating the public assignment of risk levels, this field will have the value `not_assessed`. In the event of an error in the evaluation, this field will have the value `unknown`. This field is only available with Radar.
      attr_reader :risk_level
      # Stripe Radar's evaluation of the riskiness of the payment. Possible values for evaluated payments are between 0 and 100. For non-card payments, card-based payments predating the public assignment of risk scores, or in the event of an error during evaluation, this field will not be present. This field is only available with Radar for Fraud Teams.
      attr_reader :risk_score
      # The ID of the Radar rule that matched the payment, if applicable.
      attr_reader :rule
      # A human-readable description of the outcome type and reason, designed for you (the recipient of the payment), not your customer.
      attr_reader :seller_message
      # Possible values are `authorized`, `manual_review`, `issuer_declined`, `blocked`, and `invalid`. See [understanding declines](https://stripe.com/docs/declines) and [Radar reviews](https://stripe.com/docs/radar/reviews) for details.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { rule: Rule }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentMethodDetails < ::Stripe::StripeObject
      class AchCreditTransfer < ::Stripe::StripeObject
        # Account number to transfer funds to.
        attr_reader :account_number
        # Name of the bank associated with the routing number.
        attr_reader :bank_name
        # Routing transit number for the bank account to transfer funds to.
        attr_reader :routing_number
        # SWIFT code of the bank associated with the routing number.
        attr_reader :swift_code

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AchDebit < ::Stripe::StripeObject
        # Type of entity that holds the account. This can be either `individual` or `company`.
        attr_reader :account_holder_type
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Two-letter ISO code representing the country the bank account is located in.
        attr_reader :country
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Last four digits of the bank account number.
        attr_reader :last4
        # Routing transit number of the bank account.
        attr_reader :routing_number

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AcssDebit < ::Stripe::StripeObject
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Institution number of the bank account
        attr_reader :institution_number
        # Last four digits of the bank account number.
        attr_reader :last4
        # ID of the mandate used to make this payment.
        attr_reader :mandate
        # Transit number of the bank account.
        attr_reader :transit_number

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Affirm < ::Stripe::StripeObject
        # ID of the [location](https://stripe.com/docs/api/terminal/locations) that this transaction's reader is assigned to.
        attr_reader :location
        # ID of the [reader](https://stripe.com/docs/api/terminal/readers) this transaction was made on.
        attr_reader :reader
        # The Affirm transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AfterpayClearpay < ::Stripe::StripeObject
        # The Afterpay order ID associated with this payment intent.
        attr_reader :order_id
        # Order identifier shown to the merchant in Afterpay’s online portal.
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Alipay < ::Stripe::StripeObject
        # Uniquely identifies this particular Alipay account. You can use this attribute to check whether two Alipay accounts are the same.
        attr_reader :buyer_id
        # Uniquely identifies this particular Alipay account. You can use this attribute to check whether two Alipay accounts are the same.
        attr_reader :fingerprint
        # Transaction ID of this particular Alipay transaction.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Alma < ::Stripe::StripeObject
        class Installments < ::Stripe::StripeObject
          # The number of installments.
          attr_reader :count

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field installments
        attr_reader :installments
        # The Alma transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = { installments: Installments }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AmazonPay < ::Stripe::StripeObject
        class Funding < ::Stripe::StripeObject
          class Card < ::Stripe::StripeObject
            # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
            attr_reader :brand
            # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
            attr_reader :country
            # Two-digit number representing the card's expiration month.
            attr_reader :exp_month
            # Four-digit number representing the card's expiration year.
            attr_reader :exp_year
            # Card funding type. Can be `credit`, `debit`, `prepaid`, or `unknown`.
            attr_reader :funding
            # The last four digits of the card.
            attr_reader :last4

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field card
          attr_reader :card
          # funding type of the underlying payment method.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { card: Card }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field funding
        attr_reader :funding
        # The Amazon Pay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = { funding: Funding }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AuBecsDebit < ::Stripe::StripeObject
        # Bank-State-Branch number of the bank account.
        attr_reader :bsb_number
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Last four digits of the bank account number.
        attr_reader :last4
        # ID of the mandate used to make this payment.
        attr_reader :mandate

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BacsDebit < ::Stripe::StripeObject
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Last four digits of the bank account number.
        attr_reader :last4
        # ID of the mandate used to make this payment.
        attr_reader :mandate
        # Sort code of the bank account. (e.g., `10-20-30`)
        attr_reader :sort_code

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Bancontact < ::Stripe::StripeObject
        # Bank code of bank associated with the bank account.
        attr_reader :bank_code
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Bank Identifier Code of the bank associated with the bank account.
        attr_reader :bic
        # The ID of the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit
        # The mandate for the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit_mandate
        # Last four characters of the IBAN.
        attr_reader :iban_last4
        # Preferred language of the Bancontact authorization page that the customer is redirected to.
        # Can be one of `en`, `de`, `fr`, or `nl`
        attr_reader :preferred_language
        # Owner's verified full name. Values are verified or provided by Bancontact directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Billie < ::Stripe::StripeObject
        # The Billie transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Blik < ::Stripe::StripeObject
        # A unique and immutable identifier assigned by BLIK to every buyer.
        attr_reader :buyer_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Boleto < ::Stripe::StripeObject
        # The tax ID of the customer (CPF for individuals consumers or CNPJ for businesses consumers)
        attr_reader :tax_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Card < ::Stripe::StripeObject
        class Checks < ::Stripe::StripeObject
          # If a address line1 was provided, results of the check, one of `pass`, `fail`, `unavailable`, or `unchecked`.
          attr_reader :address_line1_check
          # If a address postal code was provided, results of the check, one of `pass`, `fail`, `unavailable`, or `unchecked`.
          attr_reader :address_postal_code_check
          # If a CVC was provided, results of the check, one of `pass`, `fail`, `unavailable`, or `unchecked`.
          attr_reader :cvc_check

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ExtendedAuthorization < ::Stripe::StripeObject
          # Indicates whether or not the capture window is extended beyond the standard authorization.
          attr_reader :status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class IncrementalAuthorization < ::Stripe::StripeObject
          # Indicates whether or not the incremental authorization feature is supported.
          attr_reader :status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Installments < ::Stripe::StripeObject
          class Plan < ::Stripe::StripeObject
            # For `fixed_count` installment plans, this is the number of installment payments your customer will make to their credit card.
            attr_reader :count
            # For `fixed_count` installment plans, this is the interval between installment payments your customer will make to their credit card.
            # One of `month`.
            attr_reader :interval
            # Type of installment plan, one of `fixed_count`, `bonus`, or `revolving`.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Installment plan selected for the payment.
          attr_reader :plan

          def self.inner_class_types
            @inner_class_types = { plan: Plan }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Multicapture < ::Stripe::StripeObject
          # Indicates whether or not multiple captures are supported.
          attr_reader :status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class NetworkToken < ::Stripe::StripeObject
          # Indicates if Stripe used a network token, either user provided or Stripe managed when processing the transaction.
          attr_reader :used

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Overcapture < ::Stripe::StripeObject
          # The maximum amount that can be captured.
          attr_reader :maximum_amount_capturable
          # Indicates whether or not the authorized amount can be over-captured.
          attr_reader :status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ThreeDSecure < ::Stripe::StripeObject
          # For authenticated transactions: how the customer was authenticated by
          # the issuing bank.
          attr_reader :authentication_flow
          # The Electronic Commerce Indicator (ECI). A protocol-level field
          # indicating what degree of authentication was performed.
          attr_reader :electronic_commerce_indicator
          # The exemption requested via 3DS and accepted by the issuer at authentication time.
          attr_reader :exemption_indicator
          # Whether Stripe requested the value of `exemption_indicator` in the transaction. This will depend on
          # the outcome of Stripe's internal risk assessment.
          attr_reader :exemption_indicator_applied
          # Indicates the outcome of 3D Secure authentication.
          attr_reader :result
          # Additional information about why 3D Secure succeeded or failed based
          # on the `result`.
          attr_reader :result_reason
          # The 3D Secure 1 XID or 3D Secure 2 Directory Server Transaction ID
          # (dsTransId) for this payment.
          attr_reader :transaction_id
          # The version of 3D Secure that was used.
          attr_reader :version

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Wallet < ::Stripe::StripeObject
          class AmexExpressCheckout < ::Stripe::StripeObject
            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class ApplePay < ::Stripe::StripeObject
            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class GooglePay < ::Stripe::StripeObject
            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Link < ::Stripe::StripeObject
            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Masterpass < ::Stripe::StripeObject
            class BillingAddress < ::Stripe::StripeObject
              # City, district, suburb, town, or village.
              attr_reader :city
              # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
              attr_reader :country
              # Address line 1, such as the street, PO Box, or company name.
              attr_reader :line1
              # Address line 2, such as the apartment, suite, unit, or building.
              attr_reader :line2
              # ZIP or postal code.
              attr_reader :postal_code
              # State, county, province, or region.
              attr_reader :state

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class ShippingAddress < ::Stripe::StripeObject
              # City, district, suburb, town, or village.
              attr_reader :city
              # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
              attr_reader :country
              # Address line 1, such as the street, PO Box, or company name.
              attr_reader :line1
              # Address line 2, such as the apartment, suite, unit, or building.
              attr_reader :line2
              # ZIP or postal code.
              attr_reader :postal_code
              # State, county, province, or region.
              attr_reader :state

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Owner's verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :billing_address
            # Owner's verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :email
            # Owner's verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :name
            # Owner's verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :shipping_address

            def self.inner_class_types
              @inner_class_types = {
                billing_address: BillingAddress,
                shipping_address: ShippingAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class SamsungPay < ::Stripe::StripeObject
            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class VisaCheckout < ::Stripe::StripeObject
            class BillingAddress < ::Stripe::StripeObject
              # City, district, suburb, town, or village.
              attr_reader :city
              # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
              attr_reader :country
              # Address line 1, such as the street, PO Box, or company name.
              attr_reader :line1
              # Address line 2, such as the apartment, suite, unit, or building.
              attr_reader :line2
              # ZIP or postal code.
              attr_reader :postal_code
              # State, county, province, or region.
              attr_reader :state

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

            class ShippingAddress < ::Stripe::StripeObject
              # City, district, suburb, town, or village.
              attr_reader :city
              # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
              attr_reader :country
              # Address line 1, such as the street, PO Box, or company name.
              attr_reader :line1
              # Address line 2, such as the apartment, suite, unit, or building.
              attr_reader :line2
              # ZIP or postal code.
              attr_reader :postal_code
              # State, county, province, or region.
              attr_reader :state

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Owner's verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :billing_address
            # Owner's verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :email
            # Owner's verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :name
            # Owner's verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
            attr_reader :shipping_address

            def self.inner_class_types
              @inner_class_types = {
                billing_address: BillingAddress,
                shipping_address: ShippingAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field amex_express_checkout
          attr_reader :amex_express_checkout
          # Attribute for field apple_pay
          attr_reader :apple_pay
          # (For tokenized numbers only.) The last four digits of the device account number.
          attr_reader :dynamic_last4
          # Attribute for field google_pay
          attr_reader :google_pay
          # Attribute for field link
          attr_reader :link
          # Attribute for field masterpass
          attr_reader :masterpass
          # Attribute for field samsung_pay
          attr_reader :samsung_pay
          # The type of the card wallet, one of `amex_express_checkout`, `apple_pay`, `google_pay`, `masterpass`, `samsung_pay`, `visa_checkout`, or `link`. An additional hash is included on the Wallet subhash with a name matching this value. It contains additional information specific to the card wallet type.
          attr_reader :type
          # Attribute for field visa_checkout
          attr_reader :visa_checkout

          def self.inner_class_types
            @inner_class_types = {
              amex_express_checkout: AmexExpressCheckout,
              apple_pay: ApplePay,
              google_pay: GooglePay,
              link: Link,
              masterpass: Masterpass,
              samsung_pay: SamsungPay,
              visa_checkout: VisaCheckout,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The authorized amount.
        attr_reader :amount_authorized
        # Authorization code on the charge.
        attr_reader :authorization_code
        # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
        attr_reader :brand
        # When using manual capture, a future timestamp at which the charge will be automatically refunded if uncaptured.
        attr_reader :capture_before
        # Check results by Card networks on Card address and CVC at time of payment.
        attr_reader :checks
        # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
        attr_reader :country
        # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
        attr_reader :description
        # Two-digit number representing the card's expiration month.
        attr_reader :exp_month
        # Four-digit number representing the card's expiration year.
        attr_reader :exp_year
        # Attribute for field extended_authorization
        attr_reader :extended_authorization
        # Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example. For payment methods that tokenize card information (Apple Pay, Google Pay), the tokenized number might be provided instead of the underlying card number.
        #
        # *As of May 1, 2021, card fingerprint in India for Connect changed to allow two fingerprints for the same card---one for India and one for the rest of the world.*
        attr_reader :fingerprint
        # Card funding type. Can be `credit`, `debit`, `prepaid`, or `unknown`.
        attr_reader :funding
        # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
        attr_reader :iin
        # Attribute for field incremental_authorization
        attr_reader :incremental_authorization
        # Installment details for this payment.
        #
        # For more information, see the [installments integration guide](https://stripe.com/docs/payments/installments).
        attr_reader :installments
        # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
        attr_reader :issuer
        # The last four digits of the card.
        attr_reader :last4
        # ID of the mandate used to make this payment or created by it.
        attr_reader :mandate
        # True if this payment was marked as MOTO and out of scope for SCA.
        attr_reader :moto
        # Attribute for field multicapture
        attr_reader :multicapture
        # Identifies which network this charge was processed on. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `interac`, `jcb`, `link`, `mastercard`, `unionpay`, `visa`, or `unknown`.
        attr_reader :network
        # If this card has network token credentials, this contains the details of the network token credentials.
        attr_reader :network_token
        # This is used by the financial networks to identify a transaction. Visa calls this the Transaction ID, Mastercard calls this the Trace ID, and American Express calls this the Acquirer Reference Data. This value will be present if it is returned by the financial network in the authorization response, and null otherwise.
        attr_reader :network_transaction_id
        # Attribute for field overcapture
        attr_reader :overcapture
        # Status of a card based on the card issuer.
        attr_reader :regulated_status
        # Populated if this transaction used 3D Secure authentication.
        attr_reader :three_d_secure
        # If this Card is part of a card wallet, this contains the details of the card wallet.
        attr_reader :wallet

        def self.inner_class_types
          @inner_class_types = {
            checks: Checks,
            extended_authorization: ExtendedAuthorization,
            incremental_authorization: IncrementalAuthorization,
            installments: Installments,
            multicapture: Multicapture,
            network_token: NetworkToken,
            overcapture: Overcapture,
            three_d_secure: ThreeDSecure,
            wallet: Wallet,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CardPresent < ::Stripe::StripeObject
        class Offline < ::Stripe::StripeObject
          # Time at which the payment was collected while offline
          attr_reader :stored_at
          # The method used to process this payment method offline. Only deferred is allowed.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Receipt < ::Stripe::StripeObject
          # The type of account being debited or credited
          attr_reader :account_type
          # The Application Cryptogram, a unique value generated by the card to authenticate the transaction with issuers.
          attr_reader :application_cryptogram
          # The Application Identifier (AID) on the card used to determine which networks are eligible to process the transaction. Referenced from EMV tag 9F12, data encoded on the card's chip.
          attr_reader :application_preferred_name
          # Identifier for this transaction.
          attr_reader :authorization_code
          # EMV tag 8A. A code returned by the card issuer.
          attr_reader :authorization_response_code
          # Describes the method used by the cardholder to verify ownership of the card. One of the following: `approval`, `failure`, `none`, `offline_pin`, `offline_pin_and_signature`, `online_pin`, or `signature`.
          attr_reader :cardholder_verification_method
          # Similar to the application_preferred_name, identifying the applications (AIDs) available on the card. Referenced from EMV tag 84.
          attr_reader :dedicated_file_name
          # A 5-byte string that records the checks and validations that occur between the card and the terminal. These checks determine how the terminal processes the transaction and what risk tolerance is acceptable. Referenced from EMV Tag 95.
          attr_reader :terminal_verification_results
          # An indication of which steps were completed during the card read process. Referenced from EMV Tag 9B.
          attr_reader :transaction_status_information

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Wallet < ::Stripe::StripeObject
          # The type of mobile wallet, one of `apple_pay`, `google_pay`, `samsung_pay`, or `unknown`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The authorized amount
        attr_reader :amount_authorized
        # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
        attr_reader :brand
        # The [product code](https://stripe.com/docs/card-product-codes) that identifies the specific program or product associated with a card.
        attr_reader :brand_product
        # When using manual capture, a future timestamp after which the charge will be automatically refunded if uncaptured.
        attr_reader :capture_before
        # The cardholder name as read from the card, in [ISO 7813](https://en.wikipedia.org/wiki/ISO/IEC_7813) format. May include alphanumeric characters, special characters and first/last name separator (`/`). In some cases, the cardholder name may not be available depending on how the issuer has configured the card. Cardholder name is typically not available on swipe or contactless payments, such as those made with Apple Pay and Google Pay.
        attr_reader :cardholder_name
        # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
        attr_reader :country
        # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
        attr_reader :description
        # Authorization response cryptogram.
        attr_reader :emv_auth_data
        # Two-digit number representing the card's expiration month.
        attr_reader :exp_month
        # Four-digit number representing the card's expiration year.
        attr_reader :exp_year
        # Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example. For payment methods that tokenize card information (Apple Pay, Google Pay), the tokenized number might be provided instead of the underlying card number.
        #
        # *As of May 1, 2021, card fingerprint in India for Connect changed to allow two fingerprints for the same card---one for India and one for the rest of the world.*
        attr_reader :fingerprint
        # Card funding type. Can be `credit`, `debit`, `prepaid`, or `unknown`.
        attr_reader :funding
        # ID of a card PaymentMethod generated from the card_present PaymentMethod that may be attached to a Customer for future transactions. Only present if it was possible to generate a card PaymentMethod.
        attr_reader :generated_card
        # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
        attr_reader :iin
        # Whether this [PaymentIntent](https://stripe.com/docs/api/payment_intents) is eligible for incremental authorizations. Request support using [request_incremental_authorization_support](https://stripe.com/docs/api/payment_intents/create#create_payment_intent-payment_method_options-card_present-request_incremental_authorization_support).
        attr_reader :incremental_authorization_supported
        # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
        attr_reader :issuer
        # The last four digits of the card.
        attr_reader :last4
        # Identifies which network this charge was processed on. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `interac`, `jcb`, `link`, `mastercard`, `unionpay`, `visa`, or `unknown`.
        attr_reader :network
        # This is used by the financial networks to identify a transaction. Visa calls this the Transaction ID, Mastercard calls this the Trace ID, and American Express calls this the Acquirer Reference Data. This value will be present if it is returned by the financial network in the authorization response, and null otherwise.
        attr_reader :network_transaction_id
        # Details about payments collected offline.
        attr_reader :offline
        # Defines whether the authorized amount can be over-captured or not
        attr_reader :overcapture_supported
        # The languages that the issuing bank recommends using for localizing any customer-facing text, as read from the card. Referenced from EMV tag 5F2D, data encoded on the card's chip.
        attr_reader :preferred_locales
        # How card details were read in this transaction.
        attr_reader :read_method
        # A collection of fields required to be displayed on receipts. Only required for EMV transactions.
        attr_reader :receipt
        # Attribute for field wallet
        attr_reader :wallet

        def self.inner_class_types
          @inner_class_types = { offline: Offline, receipt: Receipt, wallet: Wallet }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Cashapp < ::Stripe::StripeObject
        # A unique and immutable identifier assigned by Cash App to every buyer.
        attr_reader :buyer_id
        # A public identifier for buyers using Cash App.
        attr_reader :cashtag
        # A unique and immutable identifier of payments assigned by Cash App
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Crypto < ::Stripe::StripeObject
        # The wallet address of the customer.
        attr_reader :buyer_address
        # The blockchain network that the transaction was sent on.
        attr_reader :network
        # The token currency that the transaction was sent with.
        attr_reader :token_currency
        # The blockchain transaction hash of the crypto payment.
        attr_reader :transaction_hash

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CustomerBalance < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Eps < ::Stripe::StripeObject
        # The customer's bank. Should be one of `arzte_und_apotheker_bank`, `austrian_anadi_bank_ag`, `bank_austria`, `bankhaus_carl_spangler`, `bankhaus_schelhammer_und_schattera_ag`, `bawag_psk_ag`, `bks_bank_ag`, `brull_kallmus_bank_ag`, `btv_vier_lander_bank`, `capital_bank_grawe_gruppe_ag`, `deutsche_bank_ag`, `dolomitenbank`, `easybank_ag`, `erste_bank_und_sparkassen`, `hypo_alpeadriabank_international_ag`, `hypo_noe_lb_fur_niederosterreich_u_wien`, `hypo_oberosterreich_salzburg_steiermark`, `hypo_tirol_bank_ag`, `hypo_vorarlberg_bank_ag`, `hypo_bank_burgenland_aktiengesellschaft`, `marchfelder_bank`, `oberbank_ag`, `raiffeisen_bankengruppe_osterreich`, `schoellerbank_ag`, `sparda_bank_wien`, `volksbank_gruppe`, `volkskreditbank_ag`, or `vr_bank_braunau`.
        attr_reader :bank
        # Owner's verified full name. Values are verified or provided by EPS directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        # EPS rarely provides this information so the attribute is usually empty.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Fpx < ::Stripe::StripeObject
        # Account holder type, if provided. Can be one of `individual` or `company`.
        attr_reader :account_holder_type
        # The customer's bank. Can be one of `affin_bank`, `agrobank`, `alliance_bank`, `ambank`, `bank_islam`, `bank_muamalat`, `bank_rakyat`, `bsn`, `cimb`, `hong_leong_bank`, `hsbc`, `kfh`, `maybank2u`, `ocbc`, `public_bank`, `rhb`, `standard_chartered`, `uob`, `deutsche_bank`, `maybank2e`, `pb_enterprise`, or `bank_of_china`.
        attr_reader :bank
        # Unique transaction id generated by FPX for every request from the merchant
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Giropay < ::Stripe::StripeObject
        # Bank code of bank associated with the bank account.
        attr_reader :bank_code
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Bank Identifier Code of the bank associated with the bank account.
        attr_reader :bic
        # Owner's verified full name. Values are verified or provided by Giropay directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        # Giropay rarely provides this information so the attribute is usually empty.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Grabpay < ::Stripe::StripeObject
        # Unique transaction id generated by GrabPay
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Ideal < ::Stripe::StripeObject
        # The customer's bank. Can be one of `abn_amro`, `asn_bank`, `bunq`, `buut`, `finom`, `handelsbanken`, `ing`, `knab`, `moneyou`, `n26`, `nn`, `rabobank`, `regiobank`, `revolut`, `sns_bank`, `triodos_bank`, `van_lanschot`, or `yoursafe`.
        attr_reader :bank
        # The Bank Identifier Code of the customer's bank.
        attr_reader :bic
        # The ID of the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit
        # The mandate for the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit_mandate
        # Last four characters of the IBAN.
        attr_reader :iban_last4
        # Unique transaction ID generated by iDEAL.
        attr_reader :transaction_id
        # Owner's verified full name. Values are verified or provided by iDEAL directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class InteracPresent < ::Stripe::StripeObject
        class Receipt < ::Stripe::StripeObject
          # The type of account being debited or credited
          attr_reader :account_type
          # The Application Cryptogram, a unique value generated by the card to authenticate the transaction with issuers.
          attr_reader :application_cryptogram
          # The Application Identifier (AID) on the card used to determine which networks are eligible to process the transaction. Referenced from EMV tag 9F12, data encoded on the card's chip.
          attr_reader :application_preferred_name
          # Identifier for this transaction.
          attr_reader :authorization_code
          # EMV tag 8A. A code returned by the card issuer.
          attr_reader :authorization_response_code
          # Describes the method used by the cardholder to verify ownership of the card. One of the following: `approval`, `failure`, `none`, `offline_pin`, `offline_pin_and_signature`, `online_pin`, or `signature`.
          attr_reader :cardholder_verification_method
          # Similar to the application_preferred_name, identifying the applications (AIDs) available on the card. Referenced from EMV tag 84.
          attr_reader :dedicated_file_name
          # A 5-byte string that records the checks and validations that occur between the card and the terminal. These checks determine how the terminal processes the transaction and what risk tolerance is acceptable. Referenced from EMV Tag 95.
          attr_reader :terminal_verification_results
          # An indication of which steps were completed during the card read process. Referenced from EMV Tag 9B.
          attr_reader :transaction_status_information

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Card brand. Can be `interac`, `mastercard` or `visa`.
        attr_reader :brand
        # The cardholder name as read from the card, in [ISO 7813](https://en.wikipedia.org/wiki/ISO/IEC_7813) format. May include alphanumeric characters, special characters and first/last name separator (`/`). In some cases, the cardholder name may not be available depending on how the issuer has configured the card. Cardholder name is typically not available on swipe or contactless payments, such as those made with Apple Pay and Google Pay.
        attr_reader :cardholder_name
        # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
        attr_reader :country
        # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
        attr_reader :description
        # Authorization response cryptogram.
        attr_reader :emv_auth_data
        # Two-digit number representing the card's expiration month.
        attr_reader :exp_month
        # Four-digit number representing the card's expiration year.
        attr_reader :exp_year
        # Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example. For payment methods that tokenize card information (Apple Pay, Google Pay), the tokenized number might be provided instead of the underlying card number.
        #
        # *As of May 1, 2021, card fingerprint in India for Connect changed to allow two fingerprints for the same card---one for India and one for the rest of the world.*
        attr_reader :fingerprint
        # Card funding type. Can be `credit`, `debit`, `prepaid`, or `unknown`.
        attr_reader :funding
        # ID of a card PaymentMethod generated from the card_present PaymentMethod that may be attached to a Customer for future transactions. Only present if it was possible to generate a card PaymentMethod.
        attr_reader :generated_card
        # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
        attr_reader :iin
        # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
        attr_reader :issuer
        # The last four digits of the card.
        attr_reader :last4
        # Identifies which network this charge was processed on. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `interac`, `jcb`, `link`, `mastercard`, `unionpay`, `visa`, or `unknown`.
        attr_reader :network
        # This is used by the financial networks to identify a transaction. Visa calls this the Transaction ID, Mastercard calls this the Trace ID, and American Express calls this the Acquirer Reference Data. This value will be present if it is returned by the financial network in the authorization response, and null otherwise.
        attr_reader :network_transaction_id
        # The languages that the issuing bank recommends using for localizing any customer-facing text, as read from the card. Referenced from EMV tag 5F2D, data encoded on the card's chip.
        attr_reader :preferred_locales
        # How card details were read in this transaction.
        attr_reader :read_method
        # A collection of fields required to be displayed on receipts. Only required for EMV transactions.
        attr_reader :receipt

        def self.inner_class_types
          @inner_class_types = { receipt: Receipt }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class KakaoPay < ::Stripe::StripeObject
        # A unique identifier for the buyer as determined by the local payment processor.
        attr_reader :buyer_id
        # The Kakao Pay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Klarna < ::Stripe::StripeObject
        class PayerDetails < ::Stripe::StripeObject
          class Address < ::Stripe::StripeObject
            # The payer address country
            attr_reader :country

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The payer's address
          attr_reader :address

          def self.inner_class_types
            @inner_class_types = { address: Address }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The payer details for this transaction.
        attr_reader :payer_details
        # The Klarna payment method used for this transaction.
        # Can be one of `pay_later`, `pay_now`, `pay_with_financing`, or `pay_in_installments`
        attr_reader :payment_method_category
        # Preferred language of the Klarna authorization page that the customer is redirected to.
        # Can be one of `de-AT`, `en-AT`, `nl-BE`, `fr-BE`, `en-BE`, `de-DE`, `en-DE`, `da-DK`, `en-DK`, `es-ES`, `en-ES`, `fi-FI`, `sv-FI`, `en-FI`, `en-GB`, `en-IE`, `it-IT`, `en-IT`, `nl-NL`, `en-NL`, `nb-NO`, `en-NO`, `sv-SE`, `en-SE`, `en-US`, `es-US`, `fr-FR`, `en-FR`, `cs-CZ`, `en-CZ`, `ro-RO`, `en-RO`, `el-GR`, `en-GR`, `en-AU`, `en-NZ`, `en-CA`, `fr-CA`, `pl-PL`, `en-PL`, `pt-PT`, `en-PT`, `de-CH`, `fr-CH`, `it-CH`, or `en-CH`
        attr_reader :preferred_locale

        def self.inner_class_types
          @inner_class_types = { payer_details: PayerDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Konbini < ::Stripe::StripeObject
        class Store < ::Stripe::StripeObject
          # The name of the convenience store chain where the payment was completed.
          attr_reader :chain

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # If the payment succeeded, this contains the details of the convenience store where the payment was completed.
        attr_reader :store

        def self.inner_class_types
          @inner_class_types = { store: Store }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class KrCard < ::Stripe::StripeObject
        # The local credit or debit card brand.
        attr_reader :brand
        # A unique identifier for the buyer as determined by the local payment processor.
        attr_reader :buyer_id
        # The last four digits of the card. This may not be present for American Express cards.
        attr_reader :last4
        # The Korean Card transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Link < ::Stripe::StripeObject
        # Two-letter ISO code representing the funding source country beneath the Link payment.
        # You could use this attribute to get a sense of international fees.
        attr_reader :country

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class MbWay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Mobilepay < ::Stripe::StripeObject
        class Card < ::Stripe::StripeObject
          # Brand of the card used in the transaction
          attr_reader :brand
          # Two-letter ISO code representing the country of the card
          attr_reader :country
          # Two digit number representing the card's expiration month
          attr_reader :exp_month
          # Two digit number representing the card's expiration year
          attr_reader :exp_year
          # The last 4 digits of the card
          attr_reader :last4

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Internal card details
        attr_reader :card

        def self.inner_class_types
          @inner_class_types = { card: Card }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Multibanco < ::Stripe::StripeObject
        # Entity number associated with this Multibanco payment.
        attr_reader :entity
        # Reference number associated with this Multibanco payment.
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NaverPay < ::Stripe::StripeObject
        # A unique identifier for the buyer as determined by the local payment processor.
        attr_reader :buyer_id
        # The Naver Pay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NzBankAccount < ::Stripe::StripeObject
        # The name on the bank account. Only present if the account holder name is different from the name of the authorized signatory collected in the PaymentMethod’s billing details.
        attr_reader :account_holder_name
        # The numeric code for the bank account's bank.
        attr_reader :bank_code
        # The name of the bank.
        attr_reader :bank_name
        # The numeric code for the bank account's bank branch.
        attr_reader :branch_code
        # Last four digits of the bank account number.
        attr_reader :last4
        # The suffix of the bank account number.
        attr_reader :suffix

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Oxxo < ::Stripe::StripeObject
        # OXXO reference number
        attr_reader :number

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class P24 < ::Stripe::StripeObject
        # The customer's bank. Can be one of `ing`, `citi_handlowy`, `tmobile_usbugi_bankowe`, `plus_bank`, `etransfer_pocztowy24`, `banki_spbdzielcze`, `bank_nowy_bfg_sa`, `getin_bank`, `velobank`, `blik`, `noble_pay`, `ideabank`, `envelobank`, `santander_przelew24`, `nest_przelew`, `mbank_mtransfer`, `inteligo`, `pbac_z_ipko`, `bnp_paribas`, `credit_agricole`, `toyota_bank`, `bank_pekao_sa`, `volkswagen_bank`, `bank_millennium`, `alior_bank`, or `boz`.
        attr_reader :bank
        # Unique reference for this Przelewy24 payment.
        attr_reader :reference
        # Owner's verified full name. Values are verified or provided by Przelewy24 directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        # Przelewy24 rarely provides this information so the attribute is usually empty.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PayByBank < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Payco < ::Stripe::StripeObject
        # A unique identifier for the buyer as determined by the local payment processor.
        attr_reader :buyer_id
        # The Payco transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Paynow < ::Stripe::StripeObject
        # ID of the [location](https://stripe.com/docs/api/terminal/locations) that this transaction's reader is assigned to.
        attr_reader :location
        # ID of the [reader](https://stripe.com/docs/api/terminal/readers) this transaction was made on.
        attr_reader :reader
        # Reference number associated with this PayNow payment
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Paypal < ::Stripe::StripeObject
        class SellerProtection < ::Stripe::StripeObject
          # An array of conditions that are covered for the transaction, if applicable.
          attr_reader :dispute_categories
          # Indicates whether the transaction is eligible for PayPal's seller protection.
          attr_reader :status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Two-letter ISO code representing the buyer's country. Values are provided by PayPal directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :country
        # Owner's email. Values are provided by PayPal directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :payer_email
        # PayPal account PayerID. This identifier uniquely identifies the PayPal customer.
        attr_reader :payer_id
        # Owner's full name. Values provided by PayPal directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :payer_name
        # The level of protection offered as defined by PayPal Seller Protection for Merchants, for this transaction.
        attr_reader :seller_protection
        # A unique ID generated by PayPal for this transaction.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = { seller_protection: SellerProtection }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Pix < ::Stripe::StripeObject
        # Unique transaction id generated by BCB
        attr_reader :bank_transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Promptpay < ::Stripe::StripeObject
        # Bill reference generated by PromptPay
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RevolutPay < ::Stripe::StripeObject
        class Funding < ::Stripe::StripeObject
          class Card < ::Stripe::StripeObject
            # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
            attr_reader :brand
            # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
            attr_reader :country
            # Two-digit number representing the card's expiration month.
            attr_reader :exp_month
            # Four-digit number representing the card's expiration year.
            attr_reader :exp_year
            # Card funding type. Can be `credit`, `debit`, `prepaid`, or `unknown`.
            attr_reader :funding
            # The last four digits of the card.
            attr_reader :last4

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field card
          attr_reader :card
          # funding type of the underlying payment method.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { card: Card }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field funding
        attr_reader :funding
        # The Revolut Pay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = { funding: Funding }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SamsungPay < ::Stripe::StripeObject
        # A unique identifier for the buyer as determined by the local payment processor.
        attr_reader :buyer_id
        # The Samsung Pay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Satispay < ::Stripe::StripeObject
        # The Satispay transaction ID associated with this payment.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SepaCreditTransfer < ::Stripe::StripeObject
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Bank Identifier Code of the bank associated with the bank account.
        attr_reader :bic
        # IBAN of the bank account to transfer funds to.
        attr_reader :iban

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SepaDebit < ::Stripe::StripeObject
        # Bank code of bank associated with the bank account.
        attr_reader :bank_code
        # Branch code of bank associated with the bank account.
        attr_reader :branch_code
        # Two-letter ISO code representing the country the bank account is located in.
        attr_reader :country
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Last four characters of the IBAN.
        attr_reader :last4
        # Find the ID of the mandate used for this payment under the [payment_method_details.sepa_debit.mandate](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-sepa_debit-mandate) property on the Charge. Use this mandate ID to [retrieve the Mandate](https://stripe.com/docs/api/mandates/retrieve).
        attr_reader :mandate

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Sofort < ::Stripe::StripeObject
        # Bank code of bank associated with the bank account.
        attr_reader :bank_code
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Bank Identifier Code of the bank associated with the bank account.
        attr_reader :bic
        # Two-letter ISO code representing the country the bank account is located in.
        attr_reader :country
        # The ID of the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit
        # The mandate for the SEPA Direct Debit PaymentMethod which was generated by this Charge.
        attr_reader :generated_sepa_debit_mandate
        # Last four characters of the IBAN.
        attr_reader :iban_last4
        # Preferred language of the SOFORT authorization page that the customer is redirected to.
        # Can be one of `de`, `en`, `es`, `fr`, `it`, `nl`, or `pl`
        attr_reader :preferred_language
        # Owner's verified full name. Values are verified or provided by SOFORT directly
        # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
        attr_reader :verified_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StripeAccount < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Swish < ::Stripe::StripeObject
        # Uniquely identifies the payer's Swish account. You can use this attribute to check whether two Swish transactions were paid for by the same payer
        attr_reader :fingerprint
        # Payer bank reference number for the payment
        attr_reader :payment_reference
        # The last four digits of the Swish account phone number
        attr_reader :verified_phone_last4

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Twint < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class UsBankAccount < ::Stripe::StripeObject
        # Account holder type: individual or company.
        attr_reader :account_holder_type
        # Account type: checkings or savings. Defaults to checking if omitted.
        attr_reader :account_type
        # Name of the bank associated with the bank account.
        attr_reader :bank_name
        # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
        attr_reader :fingerprint
        # Last four digits of the bank account number.
        attr_reader :last4
        # ID of the mandate used to make this payment.
        attr_reader :mandate
        # Reference number to locate ACH payments with customer's bank.
        attr_reader :payment_reference
        # Routing number of the bank account.
        attr_reader :routing_number

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Wechat < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class WechatPay < ::Stripe::StripeObject
        # Uniquely identifies this particular WeChat Pay account. You can use this attribute to check whether two WeChat accounts are the same.
        attr_reader :fingerprint
        # ID of the [location](https://stripe.com/docs/api/terminal/locations) that this transaction's reader is assigned to.
        attr_reader :location
        # ID of the [reader](https://stripe.com/docs/api/terminal/readers) this transaction was made on.
        attr_reader :reader
        # Transaction ID of this particular WeChat Pay transaction.
        attr_reader :transaction_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Zip < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field ach_credit_transfer
      attr_reader :ach_credit_transfer
      # Attribute for field ach_debit
      attr_reader :ach_debit
      # Attribute for field acss_debit
      attr_reader :acss_debit
      # Attribute for field affirm
      attr_reader :affirm
      # Attribute for field afterpay_clearpay
      attr_reader :afterpay_clearpay
      # Attribute for field alipay
      attr_reader :alipay
      # Attribute for field alma
      attr_reader :alma
      # Attribute for field amazon_pay
      attr_reader :amazon_pay
      # Attribute for field au_becs_debit
      attr_reader :au_becs_debit
      # Attribute for field bacs_debit
      attr_reader :bacs_debit
      # Attribute for field bancontact
      attr_reader :bancontact
      # Attribute for field billie
      attr_reader :billie
      # Attribute for field blik
      attr_reader :blik
      # Attribute for field boleto
      attr_reader :boleto
      # Attribute for field card
      attr_reader :card
      # Attribute for field card_present
      attr_reader :card_present
      # Attribute for field cashapp
      attr_reader :cashapp
      # Attribute for field crypto
      attr_reader :crypto
      # Attribute for field customer_balance
      attr_reader :customer_balance
      # Attribute for field eps
      attr_reader :eps
      # Attribute for field fpx
      attr_reader :fpx
      # Attribute for field giropay
      attr_reader :giropay
      # Attribute for field grabpay
      attr_reader :grabpay
      # Attribute for field ideal
      attr_reader :ideal
      # Attribute for field interac_present
      attr_reader :interac_present
      # Attribute for field kakao_pay
      attr_reader :kakao_pay
      # Attribute for field klarna
      attr_reader :klarna
      # Attribute for field konbini
      attr_reader :konbini
      # Attribute for field kr_card
      attr_reader :kr_card
      # Attribute for field link
      attr_reader :link
      # Attribute for field mb_way
      attr_reader :mb_way
      # Attribute for field mobilepay
      attr_reader :mobilepay
      # Attribute for field multibanco
      attr_reader :multibanco
      # Attribute for field naver_pay
      attr_reader :naver_pay
      # Attribute for field nz_bank_account
      attr_reader :nz_bank_account
      # Attribute for field oxxo
      attr_reader :oxxo
      # Attribute for field p24
      attr_reader :p24
      # Attribute for field pay_by_bank
      attr_reader :pay_by_bank
      # Attribute for field payco
      attr_reader :payco
      # Attribute for field paynow
      attr_reader :paynow
      # Attribute for field paypal
      attr_reader :paypal
      # Attribute for field pix
      attr_reader :pix
      # Attribute for field promptpay
      attr_reader :promptpay
      # Attribute for field revolut_pay
      attr_reader :revolut_pay
      # Attribute for field samsung_pay
      attr_reader :samsung_pay
      # Attribute for field satispay
      attr_reader :satispay
      # Attribute for field sepa_credit_transfer
      attr_reader :sepa_credit_transfer
      # Attribute for field sepa_debit
      attr_reader :sepa_debit
      # Attribute for field sofort
      attr_reader :sofort
      # Attribute for field stripe_account
      attr_reader :stripe_account
      # Attribute for field swish
      attr_reader :swish
      # Attribute for field twint
      attr_reader :twint
      # The type of transaction-specific details of the payment method used in the payment. See [PaymentMethod.type](https://stripe.com/docs/api/payment_methods/object#payment_method_object-type) for the full list of possible types.
      # An additional hash is included on `payment_method_details` with a name matching this value.
      # It contains information specific to the payment method.
      attr_reader :type
      # Attribute for field us_bank_account
      attr_reader :us_bank_account
      # Attribute for field wechat
      attr_reader :wechat
      # Attribute for field wechat_pay
      attr_reader :wechat_pay
      # Attribute for field zip
      attr_reader :zip

      def self.inner_class_types
        @inner_class_types = {
          ach_credit_transfer: AchCreditTransfer,
          ach_debit: AchDebit,
          acss_debit: AcssDebit,
          affirm: Affirm,
          afterpay_clearpay: AfterpayClearpay,
          alipay: Alipay,
          alma: Alma,
          amazon_pay: AmazonPay,
          au_becs_debit: AuBecsDebit,
          bacs_debit: BacsDebit,
          bancontact: Bancontact,
          billie: Billie,
          blik: Blik,
          boleto: Boleto,
          card: Card,
          card_present: CardPresent,
          cashapp: Cashapp,
          crypto: Crypto,
          customer_balance: CustomerBalance,
          eps: Eps,
          fpx: Fpx,
          giropay: Giropay,
          grabpay: Grabpay,
          ideal: Ideal,
          interac_present: InteracPresent,
          kakao_pay: KakaoPay,
          klarna: Klarna,
          konbini: Konbini,
          kr_card: KrCard,
          link: Link,
          mb_way: MbWay,
          mobilepay: Mobilepay,
          multibanco: Multibanco,
          naver_pay: NaverPay,
          nz_bank_account: NzBankAccount,
          oxxo: Oxxo,
          p24: P24,
          pay_by_bank: PayByBank,
          payco: Payco,
          paynow: Paynow,
          paypal: Paypal,
          pix: Pix,
          promptpay: Promptpay,
          revolut_pay: RevolutPay,
          samsung_pay: SamsungPay,
          satispay: Satispay,
          sepa_credit_transfer: SepaCreditTransfer,
          sepa_debit: SepaDebit,
          sofort: Sofort,
          stripe_account: StripeAccount,
          swish: Swish,
          twint: Twint,
          us_bank_account: UsBankAccount,
          wechat: Wechat,
          wechat_pay: WechatPay,
          zip: Zip,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PresentmentDetails < ::Stripe::StripeObject
      # Amount intended to be collected by this payment, denominated in `presentment_currency`.
      attr_reader :presentment_amount
      # Currency presented to the customer during payment.
      attr_reader :presentment_currency

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class RadarOptions < ::Stripe::StripeObject
      # A [Radar Session](https://stripe.com/docs/radar/radar-session) is a snapshot of the browser metadata and device details that help Radar make more accurate predictions on your payments.
      attr_reader :session

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Shipping < ::Stripe::StripeObject
      class Address < ::Stripe::StripeObject
        # City, district, suburb, town, or village.
        attr_reader :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_reader :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_reader :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_reader :line2
        # ZIP or postal code.
        attr_reader :postal_code
        # State, county, province, or region.
        attr_reader :state

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field address
      attr_reader :address
      # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
      attr_reader :carrier
      # Recipient name.
      attr_reader :name
      # Recipient phone (including extension).
      attr_reader :phone
      # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
      attr_reader :tracking_number

      def self.inner_class_types
        @inner_class_types = { address: Address }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TransferData < ::Stripe::StripeObject
      # The amount transferred to the destination account, if specified. By default, the entire charge amount is transferred to the destination account.
      attr_reader :amount
      # ID of an existing, connected Stripe account to transfer funds to if `transfer_data` was specified in the charge request.
      attr_reader :destination

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Amount intended to be collected by this payment. A positive integer representing how much to charge in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or [equivalent in charge currency](https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts). The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).
    attr_reader :amount
    # Amount in cents (or local equivalent) captured (can be less than the amount attribute on the charge if a partial capture was made).
    attr_reader :amount_captured
    # Amount in cents (or local equivalent) refunded (can be less than the amount attribute on the charge if a partial refund was issued).
    attr_reader :amount_refunded
    # ID of the Connect application that created the charge.
    attr_reader :application
    # The application fee (if any) for the charge. [See the Connect documentation](https://stripe.com/docs/connect/direct-charges#collect-fees) for details.
    attr_reader :application_fee
    # The amount of the application fee (if any) requested for the charge. [See the Connect documentation](https://stripe.com/docs/connect/direct-charges#collect-fees) for details.
    attr_reader :application_fee_amount
    # Authorization code on the charge.
    attr_reader :authorization_code
    # ID of the balance transaction that describes the impact of this charge on your account balance (not including refunds or disputes).
    attr_reader :balance_transaction
    # Attribute for field billing_details
    attr_reader :billing_details
    # The full statement descriptor that is passed to card networks, and that is displayed on your customers' credit card and bank statements. Allows you to see what the statement descriptor looks like after the static and dynamic portions are combined. This value only exists for card payments.
    attr_reader :calculated_statement_descriptor
    # If the charge was created without capturing, this Boolean represents whether it is still uncaptured or has since been captured.
    attr_reader :captured
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # ID of the customer this charge is for if one exists.
    attr_reader :customer
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # Whether the charge has been disputed.
    attr_reader :disputed
    # ID of the balance transaction that describes the reversal of the balance on your account due to payment failure.
    attr_reader :failure_balance_transaction
    # Error code explaining reason for charge failure if available (see [the errors section](https://stripe.com/docs/error-codes) for a list of codes).
    attr_reader :failure_code
    # Message to user further explaining reason for charge failure if available.
    attr_reader :failure_message
    # Information on fraud assessments for the charge.
    attr_reader :fraud_details
    # Unique identifier for the object.
    attr_reader :id
    # Attribute for field level3
    attr_reader :level3
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account (if any) the charge was made on behalf of without triggering an automatic transfer. See the [Connect documentation](https://stripe.com/docs/connect/separate-charges-and-transfers) for details.
    attr_reader :on_behalf_of
    # Details about whether the payment was accepted, and why. See [understanding declines](https://stripe.com/docs/declines) for details.
    attr_reader :outcome
    # `true` if the charge succeeded, or was successfully authorized for later capture.
    attr_reader :paid
    # ID of the PaymentIntent associated with this charge, if one exists.
    attr_reader :payment_intent
    # ID of the payment method used in this charge.
    attr_reader :payment_method
    # Details about the payment method at the time of the transaction.
    attr_reader :payment_method_details
    # Attribute for field presentment_details
    attr_reader :presentment_details
    # Options to configure Radar. See [Radar Session](https://stripe.com/docs/radar/radar-session) for more information.
    attr_reader :radar_options
    # This is the email address that the receipt for this charge was sent to.
    attr_reader :receipt_email
    # This is the transaction number that appears on email receipts sent for this charge. This attribute will be `null` until a receipt has been sent.
    attr_reader :receipt_number
    # This is the URL to view the receipt for this charge. The receipt is kept up-to-date to the latest state of the charge, including any refunds. If the charge is for an Invoice, the receipt will be stylized as an Invoice receipt.
    attr_reader :receipt_url
    # Whether the charge has been fully refunded. If the charge is only partially refunded, this attribute will still be false.
    attr_reader :refunded
    # A list of refunds that have been applied to the charge.
    attr_reader :refunds
    # ID of the review associated with this charge if one exists.
    attr_reader :review
    # Shipping information for the charge.
    attr_reader :shipping
    # This is a legacy field that will be removed in the future. It contains the Source, Card, or BankAccount object used for the charge. For details about the payment method used for this charge, refer to `payment_method` or `payment_method_details` instead.
    attr_reader :source
    # The transfer ID which created this charge. Only present if the charge came from another Stripe account. [See the Connect documentation](https://docs.stripe.com/connect/destination-charges) for details.
    attr_reader :source_transfer
    # For a non-card charge, text that appears on the customer's statement as the statement descriptor. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    #
    # For a card charge, this value is ignored unless you don't specify a `statement_descriptor_suffix`, in which case this value is used as the suffix.
    attr_reader :statement_descriptor
    # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement. If the account has no prefix value, the suffix is concatenated to the account's statement descriptor.
    attr_reader :statement_descriptor_suffix
    # The status of the payment is either `succeeded`, `pending`, or `failed`.
    attr_reader :status
    # ID of the transfer to the `destination` account (only applicable if the charge was created using the `destination` parameter).
    attr_reader :transfer
    # An optional dictionary including the account to automatically transfer to as part of a destination charge. [See the Connect documentation](https://stripe.com/docs/connect/destination-charges) for details.
    attr_reader :transfer_data
    # A string that identifies this transaction as part of a group. See the [Connect documentation](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options) for details.
    attr_reader :transfer_group

    # Capture the payment of an existing, uncaptured charge that was created with the capture option set to false.
    #
    # Uncaptured payments expire a set number of days after they are created ([7 by default](https://docs.stripe.com/docs/charges/placing-a-hold)), after which they are marked as refunded and capture attempts will fail.
    #
    # Don't use this method to capture a PaymentIntent-initiated charge. Use [Capture a PaymentIntent](https://docs.stripe.com/docs/api/payment_intents/capture).
    def capture(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/charges/%<charge>s/capture", { charge: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Capture the payment of an existing, uncaptured charge that was created with the capture option set to false.
    #
    # Uncaptured payments expire a set number of days after they are created ([7 by default](https://docs.stripe.com/docs/charges/placing-a-hold)), after which they are marked as refunded and capture attempts will fail.
    #
    # Don't use this method to capture a PaymentIntent-initiated charge. Use [Capture a PaymentIntent](https://docs.stripe.com/docs/api/payment_intents/capture).
    def self.capture(charge, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/charges/%<charge>s/capture", { charge: CGI.escape(charge) }),
        params: params,
        opts: opts
      )
    end

    # This method is no longer recommended—use the [Payment Intents API](https://docs.stripe.com/docs/api/payment_intents)
    # to initiate a new payment instead. Confirmation of the PaymentIntent creates the Charge
    # object used to request payment.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/charges", params: params, opts: opts)
    end

    # Returns a list of charges you've previously created. The charges are returned in sorted order, with the most recent charges appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/charges", params: params, opts: opts)
    end

    def self.search(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/charges/search", params: params, opts: opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end

    # Updates the specified charge by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    def self.update(charge, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/charges/%<charge>s", { charge: CGI.escape(charge) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        billing_details: BillingDetails,
        fraud_details: FraudDetails,
        level3: Level3,
        outcome: Outcome,
        payment_method_details: PaymentMethodDetails,
        presentment_details: PresentmentDetails,
        radar_options: RadarOptions,
        shipping: Shipping,
        transfer_data: TransferData,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
