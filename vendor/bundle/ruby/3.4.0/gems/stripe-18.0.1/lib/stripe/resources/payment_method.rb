# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # PaymentMethod objects represent your customer's payment instruments.
  # You can use them with [PaymentIntents](https://stripe.com/docs/payments/payment-intents) to collect payments or save them to
  # Customer objects to store instrument details for future payments.
  #
  # Related guides: [Payment Methods](https://stripe.com/docs/payments/payment-methods) and [More Payment Scenarios](https://stripe.com/docs/payments/more-payment-scenarios).
  class PaymentMethod < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_method"
    def self.object_name
      "payment_method"
    end

    class AcssDebit < ::Stripe::StripeObject
      # Name of the bank associated with the bank account.
      attr_reader :bank_name
      # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
      attr_reader :fingerprint
      # Institution number of the bank account.
      attr_reader :institution_number
      # Last four digits of the bank account number.
      attr_reader :last4
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
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AfterpayClearpay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Alipay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Alma < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AmazonPay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AuBecsDebit < ::Stripe::StripeObject
      # Six-digit number identifying bank and branch associated with this bank account.
      attr_reader :bsb_number
      # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
      attr_reader :fingerprint
      # Last four digits of the bank account number.
      attr_reader :last4

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
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Billie < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

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

    class Blik < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Boleto < ::Stripe::StripeObject
      # Uniquely identifies the customer tax id (CNPJ or CPF)
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

      class GeneratedFrom < ::Stripe::StripeObject
        class PaymentMethodDetails < ::Stripe::StripeObject
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
          # Attribute for field card_present
          attr_reader :card_present
          # The type of payment method transaction-specific details from the transaction that generated this `card` payment method. Always `card_present`.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { card_present: CardPresent }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The charge that created this object.
        attr_reader :charge
        # Transaction-specific details of the payment method used in the payment.
        attr_reader :payment_method_details
        # The ID of the SetupAttempt that generated this PaymentMethod, if any.
        attr_reader :setup_attempt

        def self.inner_class_types
          @inner_class_types = { payment_method_details: PaymentMethodDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Networks < ::Stripe::StripeObject
        # All networks available for selection via [payment_method_options.card.network](/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-card-network).
        attr_reader :available
        # The preferred network for co-branded cards. Can be `cartes_bancaires`, `mastercard`, `visa` or `invalid_preference` if requested network is not valid for the card.
        attr_reader :preferred

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ThreeDSecureUsage < ::Stripe::StripeObject
        # Whether 3D Secure is supported on this card.
        attr_reader :supported

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
      # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
      attr_reader :brand
      # Checks on Card address and CVC if provided.
      attr_reader :checks
      # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
      attr_reader :country
      # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
      attr_reader :description
      # The brand to use when displaying the card, this accounts for customer's brand choice on dual-branded cards. Can be `american_express`, `cartes_bancaires`, `diners_club`, `discover`, `eftpos_australia`, `interac`, `jcb`, `mastercard`, `union_pay`, `visa`, or `other` and may contain more values in the future.
      attr_reader :display_brand
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
      # Details of the original PaymentMethod that created this object.
      attr_reader :generated_from
      # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
      attr_reader :iin
      # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
      attr_reader :issuer
      # The last four digits of the card.
      attr_reader :last4
      # Contains information about card networks that can be used to process the payment.
      attr_reader :networks
      # Status of a card based on the card issuer.
      attr_reader :regulated_status
      # Contains details on how this Card may be used for 3D Secure authentication.
      attr_reader :three_d_secure_usage
      # If this Card is part of a card wallet, this contains the details of the card wallet.
      attr_reader :wallet

      def self.inner_class_types
        @inner_class_types = {
          checks: Checks,
          generated_from: GeneratedFrom,
          networks: Networks,
          three_d_secure_usage: ThreeDSecureUsage,
          wallet: Wallet,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CardPresent < ::Stripe::StripeObject
      class Networks < ::Stripe::StripeObject
        # All networks available for selection via [payment_method_options.card.network](/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-card-network).
        attr_reader :available
        # The preferred network for the card.
        attr_reader :preferred

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

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
      # Card brand. Can be `amex`, `cartes_bancaires`, `diners`, `discover`, `eftpos_au`, `jcb`, `link`, `mastercard`, `unionpay`, `visa` or `unknown`.
      attr_reader :brand
      # The [product code](https://stripe.com/docs/card-product-codes) that identifies the specific program or product associated with a card.
      attr_reader :brand_product
      # The cardholder name as read from the card, in [ISO 7813](https://en.wikipedia.org/wiki/ISO/IEC_7813) format. May include alphanumeric characters, special characters and first/last name separator (`/`). In some cases, the cardholder name may not be available depending on how the issuer has configured the card. Cardholder name is typically not available on swipe or contactless payments, such as those made with Apple Pay and Google Pay.
      attr_reader :cardholder_name
      # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
      attr_reader :country
      # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
      attr_reader :description
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
      # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
      attr_reader :iin
      # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
      attr_reader :issuer
      # The last four digits of the card.
      attr_reader :last4
      # Contains information about card networks that can be used to process the payment.
      attr_reader :networks
      # Details about payment methods collected offline.
      attr_reader :offline
      # The languages that the issuing bank recommends using for localizing any customer-facing text, as read from the card. Referenced from EMV tag 5F2D, data encoded on the card's chip.
      attr_reader :preferred_locales
      # How card details were read in this transaction.
      attr_reader :read_method
      # Attribute for field wallet
      attr_reader :wallet

      def self.inner_class_types
        @inner_class_types = { networks: Networks, offline: Offline, wallet: Wallet }
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

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Crypto < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Custom < ::Stripe::StripeObject
      class Logo < ::Stripe::StripeObject
        # Content type of the Dashboard-only CustomPaymentMethodType logo.
        attr_reader :content_type
        # URL of the Dashboard-only CustomPaymentMethodType logo.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Display name of the Dashboard-only CustomPaymentMethodType.
      attr_reader :display_name
      # Contains information about the Dashboard-only CustomPaymentMethodType logo.
      attr_reader :logo
      # ID of the Dashboard-only CustomPaymentMethodType. Not expandable.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { logo: Logo }
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
      # The customer's bank, if provided. Can be one of `affin_bank`, `agrobank`, `alliance_bank`, `ambank`, `bank_islam`, `bank_muamalat`, `bank_rakyat`, `bsn`, `cimb`, `hong_leong_bank`, `hsbc`, `kfh`, `maybank2u`, `ocbc`, `public_bank`, `rhb`, `standard_chartered`, `uob`, `deutsche_bank`, `maybank2e`, `pb_enterprise`, or `bank_of_china`.
      attr_reader :bank

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Giropay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Grabpay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Ideal < ::Stripe::StripeObject
      # The customer's bank, if provided. Can be one of `abn_amro`, `asn_bank`, `bunq`, `buut`, `finom`, `handelsbanken`, `ing`, `knab`, `moneyou`, `n26`, `nn`, `rabobank`, `regiobank`, `revolut`, `sns_bank`, `triodos_bank`, `van_lanschot`, or `yoursafe`.
      attr_reader :bank
      # The Bank Identifier Code of the customer's bank, if the bank was provided.
      attr_reader :bic

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class InteracPresent < ::Stripe::StripeObject
      class Networks < ::Stripe::StripeObject
        # All networks available for selection via [payment_method_options.card.network](/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-card-network).
        attr_reader :available
        # The preferred network for the card.
        attr_reader :preferred

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
      # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
      attr_reader :iin
      # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
      attr_reader :issuer
      # The last four digits of the card.
      attr_reader :last4
      # Contains information about card networks that can be used to process the payment.
      attr_reader :networks
      # The languages that the issuing bank recommends using for localizing any customer-facing text, as read from the card. Referenced from EMV tag 5F2D, data encoded on the card's chip.
      attr_reader :preferred_locales
      # How card details were read in this transaction.
      attr_reader :read_method

      def self.inner_class_types
        @inner_class_types = { networks: Networks }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class KakaoPay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Klarna < ::Stripe::StripeObject
      class Dob < ::Stripe::StripeObject
        # The day of birth, between 1 and 31.
        attr_reader :day
        # The month of birth, between 1 and 12.
        attr_reader :month
        # The four-digit year of birth.
        attr_reader :year

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The customer's date of birth, if provided.
      attr_reader :dob

      def self.inner_class_types
        @inner_class_types = { dob: Dob }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Konbini < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class KrCard < ::Stripe::StripeObject
      # The local credit or debit card brand.
      attr_reader :brand
      # The last four digits of the card. This may not be present for American Express cards.
      attr_reader :last4

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Link < ::Stripe::StripeObject
      # Account owner's email address.
      attr_reader :email
      # [Deprecated] This is a legacy parameter that no longer has any function.
      attr_reader :persistent_token

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
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Multibanco < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NaverPay < ::Stripe::StripeObject
      # Uniquely identifies this particular Naver Pay account. You can use this attribute to check whether two Naver Pay accounts are the same.
      attr_reader :buyer_id
      # Whether to fund this transaction with Naver Pay points or a card.
      attr_reader :funding

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
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class P24 < ::Stripe::StripeObject
      # The customer's bank, if provided.
      attr_reader :bank

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
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Paynow < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Paypal < ::Stripe::StripeObject
      # Two-letter ISO code representing the buyer's country. Values are provided by PayPal directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :country
      # Owner's email. Values are provided by PayPal directly
      # (if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :payer_email
      # PayPal account PayerID. This identifier uniquely identifies the PayPal customer.
      attr_reader :payer_id

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Pix < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Promptpay < ::Stripe::StripeObject
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

    class RevolutPay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
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

    class Satispay < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SepaDebit < ::Stripe::StripeObject
      class GeneratedFrom < ::Stripe::StripeObject
        # The ID of the Charge that generated this PaymentMethod, if any.
        attr_reader :charge
        # The ID of the SetupAttempt that generated this PaymentMethod, if any.
        attr_reader :setup_attempt

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Bank code of bank associated with the bank account.
      attr_reader :bank_code
      # Branch code of bank associated with the bank account.
      attr_reader :branch_code
      # Two-letter ISO code representing the country the bank account is located in.
      attr_reader :country
      # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
      attr_reader :fingerprint
      # Information about the object that generated this PaymentMethod.
      attr_reader :generated_from
      # Last four characters of the IBAN.
      attr_reader :last4

      def self.inner_class_types
        @inner_class_types = { generated_from: GeneratedFrom }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Sofort < ::Stripe::StripeObject
      # Two-letter ISO code representing the country the bank account is located in.
      attr_reader :country

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Swish < ::Stripe::StripeObject
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
      class Networks < ::Stripe::StripeObject
        # The preferred network.
        attr_reader :preferred
        # All supported networks.
        attr_reader :supported

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StatusDetails < ::Stripe::StripeObject
        class Blocked < ::Stripe::StripeObject
          # The ACH network code that resulted in this block.
          attr_reader :network_code
          # The reason why this PaymentMethod's fingerprint has been blocked
          attr_reader :reason

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field blocked
        attr_reader :blocked

        def self.inner_class_types
          @inner_class_types = { blocked: Blocked }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Account holder type: individual or company.
      attr_reader :account_holder_type
      # Account type: checkings or savings. Defaults to checking if omitted.
      attr_reader :account_type
      # The name of the bank.
      attr_reader :bank_name
      # The ID of the Financial Connections Account used to create the payment method.
      attr_reader :financial_connections_account
      # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
      attr_reader :fingerprint
      # Last four digits of the bank account number.
      attr_reader :last4
      # Contains information about US bank account networks that can be used.
      attr_reader :networks
      # Routing number of the bank account.
      attr_reader :routing_number
      # Contains information about the future reusability of this PaymentMethod.
      attr_reader :status_details

      def self.inner_class_types
        @inner_class_types = { networks: Networks, status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class WechatPay < ::Stripe::StripeObject
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
    # Attribute for field acss_debit
    attr_reader :acss_debit
    # Attribute for field affirm
    attr_reader :affirm
    # Attribute for field afterpay_clearpay
    attr_reader :afterpay_clearpay
    # Attribute for field alipay
    attr_reader :alipay
    # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow. The field defaults to “unspecified”.
    attr_reader :allow_redisplay
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
    # Attribute for field billing_details
    attr_reader :billing_details
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
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Attribute for field crypto
    attr_reader :crypto
    # Attribute for field custom
    attr_reader :custom
    # The ID of the Customer to which this PaymentMethod is saved. This will not be set when the PaymentMethod has not been saved to a Customer.
    attr_reader :customer
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
    # Unique identifier for the object.
    attr_reader :id
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
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Attribute for field mb_way
    attr_reader :mb_way
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Attribute for field mobilepay
    attr_reader :mobilepay
    # Attribute for field multibanco
    attr_reader :multibanco
    # Attribute for field naver_pay
    attr_reader :naver_pay
    # Attribute for field nz_bank_account
    attr_reader :nz_bank_account
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
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
    # Options to configure Radar. See [Radar Session](https://stripe.com/docs/radar/radar-session) for more information.
    attr_reader :radar_options
    # Attribute for field revolut_pay
    attr_reader :revolut_pay
    # Attribute for field samsung_pay
    attr_reader :samsung_pay
    # Attribute for field satispay
    attr_reader :satispay
    # Attribute for field sepa_debit
    attr_reader :sepa_debit
    # Attribute for field sofort
    attr_reader :sofort
    # Attribute for field swish
    attr_reader :swish
    # Attribute for field twint
    attr_reader :twint
    # The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.
    attr_reader :type
    # Attribute for field us_bank_account
    attr_reader :us_bank_account
    # Attribute for field wechat_pay
    attr_reader :wechat_pay
    # Attribute for field zip
    attr_reader :zip

    # Attaches a PaymentMethod object to a Customer.
    #
    # To attach a new PaymentMethod to a customer for future payments, we recommend you use a [SetupIntent](https://docs.stripe.com/docs/api/setup_intents)
    # or a PaymentIntent with [setup_future_usage](https://docs.stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage).
    # These approaches will perform any necessary steps to set up the PaymentMethod for future payments. Using the /v1/payment_methods/:id/attach
    # endpoint without first using a SetupIntent or PaymentIntent with setup_future_usage does not optimize the PaymentMethod for
    # future use, which makes later declines and payment friction more likely.
    # See [Optimizing cards for future payments](https://docs.stripe.com/docs/payments/payment-intents#future-usage) for more information about setting up
    # future payments.
    #
    # To use this PaymentMethod as the default for invoice or subscription payments,
    # set [invoice_settings.default_payment_method](https://docs.stripe.com/docs/api/customers/update#update_customer-invoice_settings-default_payment_method),
    # on the Customer to the PaymentMethod's ID.
    def attach(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/attach", { payment_method: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Attaches a PaymentMethod object to a Customer.
    #
    # To attach a new PaymentMethod to a customer for future payments, we recommend you use a [SetupIntent](https://docs.stripe.com/docs/api/setup_intents)
    # or a PaymentIntent with [setup_future_usage](https://docs.stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage).
    # These approaches will perform any necessary steps to set up the PaymentMethod for future payments. Using the /v1/payment_methods/:id/attach
    # endpoint without first using a SetupIntent or PaymentIntent with setup_future_usage does not optimize the PaymentMethod for
    # future use, which makes later declines and payment friction more likely.
    # See [Optimizing cards for future payments](https://docs.stripe.com/docs/payments/payment-intents#future-usage) for more information about setting up
    # future payments.
    #
    # To use this PaymentMethod as the default for invoice or subscription payments,
    # set [invoice_settings.default_payment_method](https://docs.stripe.com/docs/api/customers/update#update_customer-invoice_settings-default_payment_method),
    # on the Customer to the PaymentMethod's ID.
    def self.attach(payment_method, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/attach", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts
      )
    end

    # Creates a PaymentMethod object. Read the [Stripe.js reference](https://docs.stripe.com/docs/stripe-js/reference#stripe-create-payment-method) to learn how to create PaymentMethods via Stripe.js.
    #
    # Instead of creating a PaymentMethod directly, we recommend using the [PaymentIntents API to accept a payment immediately or the <a href="/docs/payments/save-and-reuse">SetupIntent](https://docs.stripe.com/docs/payments/accept-a-payment) API to collect payment method details ahead of a future payment.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/payment_methods", params: params, opts: opts)
    end

    # Detaches a PaymentMethod object from a Customer. After a PaymentMethod is detached, it can no longer be used for a payment or re-attached to a Customer.
    def detach(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/detach", { payment_method: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Detaches a PaymentMethod object from a Customer. After a PaymentMethod is detached, it can no longer be used for a payment or re-attached to a Customer.
    def self.detach(payment_method, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/detach", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of PaymentMethods for Treasury flows. If you want to list the PaymentMethods attached to a Customer for payments, you should use the [List a Customer's PaymentMethods](https://docs.stripe.com/docs/api/payment_methods/customer_list) API instead.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/payment_methods", params: params, opts: opts)
    end

    # Updates a PaymentMethod object. A PaymentMethod must be attached to a customer to be updated.
    def self.update(payment_method, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
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
        billing_details: BillingDetails,
        blik: Blik,
        boleto: Boleto,
        card: Card,
        card_present: CardPresent,
        cashapp: Cashapp,
        crypto: Crypto,
        custom: Custom,
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
        radar_options: RadarOptions,
        revolut_pay: RevolutPay,
        samsung_pay: SamsungPay,
        satispay: Satispay,
        sepa_debit: SepaDebit,
        sofort: Sofort,
        swish: Swish,
        twint: Twint,
        us_bank_account: UsBankAccount,
        wechat_pay: WechatPay,
        zip: Zip,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
