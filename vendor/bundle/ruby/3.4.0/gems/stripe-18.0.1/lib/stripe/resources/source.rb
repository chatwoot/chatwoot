# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # `Source` objects allow you to accept a variety of payment methods. They
  # represent a customer's payment instrument, and can be used with the Stripe API
  # just like a `Card` object: once chargeable, they can be charged, or can be
  # attached to customers.
  #
  # Stripe doesn't recommend using the deprecated [Sources API](https://stripe.com/docs/api/sources).
  # We recommend that you adopt the [PaymentMethods API](https://stripe.com/docs/api/payment_methods).
  # This newer API provides access to our latest features and payment method types.
  #
  # Related guides: [Sources API](https://stripe.com/docs/sources) and [Sources & Customers](https://stripe.com/docs/sources/customers).
  class Source < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::NestedResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "source"
    def self.object_name
      "source"
    end

    nested_resource_class_methods :source_transaction, operations: %i[retrieve list]

    class AchCreditTransfer < ::Stripe::StripeObject
      # Attribute for field account_number
      attr_reader :account_number
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field refund_account_holder_name
      attr_reader :refund_account_holder_name
      # Attribute for field refund_account_holder_type
      attr_reader :refund_account_holder_type
      # Attribute for field refund_routing_number
      attr_reader :refund_routing_number
      # Attribute for field routing_number
      attr_reader :routing_number
      # Attribute for field swift_code
      attr_reader :swift_code

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AchDebit < ::Stripe::StripeObject
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field country
      attr_reader :country
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field routing_number
      attr_reader :routing_number
      # Attribute for field type
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AcssDebit < ::Stripe::StripeObject
      # Attribute for field bank_address_city
      attr_reader :bank_address_city
      # Attribute for field bank_address_line_1
      attr_reader :bank_address_line_1
      # Attribute for field bank_address_line_2
      attr_reader :bank_address_line_2
      # Attribute for field bank_address_postal_code
      attr_reader :bank_address_postal_code
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field category
      attr_reader :category
      # Attribute for field country
      attr_reader :country
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field routing_number
      attr_reader :routing_number

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Alipay < ::Stripe::StripeObject
      # Attribute for field data_string
      attr_reader :data_string
      # Attribute for field native_url
      attr_reader :native_url
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AuBecsDebit < ::Stripe::StripeObject
      # Attribute for field bsb_number
      attr_reader :bsb_number
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field last4
      attr_reader :last4

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Bancontact < ::Stripe::StripeObject
      # Attribute for field bank_code
      attr_reader :bank_code
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field bic
      attr_reader :bic
      # Attribute for field iban_last4
      attr_reader :iban_last4
      # Attribute for field preferred_language
      attr_reader :preferred_language
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Card < ::Stripe::StripeObject
      # Attribute for field address_line1_check
      attr_reader :address_line1_check
      # Attribute for field address_zip_check
      attr_reader :address_zip_check
      # Attribute for field brand
      attr_reader :brand
      # Attribute for field country
      attr_reader :country
      # Attribute for field cvc_check
      attr_reader :cvc_check
      # Attribute for field description
      attr_reader :description
      # Attribute for field dynamic_last4
      attr_reader :dynamic_last4
      # Attribute for field exp_month
      attr_reader :exp_month
      # Attribute for field exp_year
      attr_reader :exp_year
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field funding
      attr_reader :funding
      # Attribute for field iin
      attr_reader :iin
      # Attribute for field issuer
      attr_reader :issuer
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field name
      attr_reader :name
      # Attribute for field three_d_secure
      attr_reader :three_d_secure
      # Attribute for field tokenization_method
      attr_reader :tokenization_method

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CardPresent < ::Stripe::StripeObject
      # Attribute for field application_cryptogram
      attr_reader :application_cryptogram
      # Attribute for field application_preferred_name
      attr_reader :application_preferred_name
      # Attribute for field authorization_code
      attr_reader :authorization_code
      # Attribute for field authorization_response_code
      attr_reader :authorization_response_code
      # Attribute for field brand
      attr_reader :brand
      # Attribute for field country
      attr_reader :country
      # Attribute for field cvm_type
      attr_reader :cvm_type
      # Attribute for field data_type
      attr_reader :data_type
      # Attribute for field dedicated_file_name
      attr_reader :dedicated_file_name
      # Attribute for field description
      attr_reader :description
      # Attribute for field emv_auth_data
      attr_reader :emv_auth_data
      # Attribute for field evidence_customer_signature
      attr_reader :evidence_customer_signature
      # Attribute for field evidence_transaction_certificate
      attr_reader :evidence_transaction_certificate
      # Attribute for field exp_month
      attr_reader :exp_month
      # Attribute for field exp_year
      attr_reader :exp_year
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field funding
      attr_reader :funding
      # Attribute for field iin
      attr_reader :iin
      # Attribute for field issuer
      attr_reader :issuer
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field pos_device_id
      attr_reader :pos_device_id
      # Attribute for field pos_entry_mode
      attr_reader :pos_entry_mode
      # Attribute for field read_method
      attr_reader :read_method
      # Attribute for field reader
      attr_reader :reader
      # Attribute for field terminal_verification_results
      attr_reader :terminal_verification_results
      # Attribute for field transaction_status_information
      attr_reader :transaction_status_information

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CodeVerification < ::Stripe::StripeObject
      # The number of attempts remaining to authenticate the source object with a verification code.
      attr_reader :attempts_remaining
      # The status of the code verification, either `pending` (awaiting verification, `attempts_remaining` should be greater than 0), `succeeded` (successful verification) or `failed` (failed verification, cannot be verified anymore as `attempts_remaining` should be 0).
      attr_reader :status

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Eps < ::Stripe::StripeObject
      # Attribute for field reference
      attr_reader :reference
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Giropay < ::Stripe::StripeObject
      # Attribute for field bank_code
      attr_reader :bank_code
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field bic
      attr_reader :bic
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Ideal < ::Stripe::StripeObject
      # Attribute for field bank
      attr_reader :bank
      # Attribute for field bic
      attr_reader :bic
      # Attribute for field iban_last4
      attr_reader :iban_last4
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Klarna < ::Stripe::StripeObject
      # Attribute for field background_image_url
      attr_reader :background_image_url
      # Attribute for field client_token
      attr_reader :client_token
      # Attribute for field first_name
      attr_reader :first_name
      # Attribute for field last_name
      attr_reader :last_name
      # Attribute for field locale
      attr_reader :locale
      # Attribute for field logo_url
      attr_reader :logo_url
      # Attribute for field page_title
      attr_reader :page_title
      # Attribute for field pay_later_asset_urls_descriptive
      attr_reader :pay_later_asset_urls_descriptive
      # Attribute for field pay_later_asset_urls_standard
      attr_reader :pay_later_asset_urls_standard
      # Attribute for field pay_later_name
      attr_reader :pay_later_name
      # Attribute for field pay_later_redirect_url
      attr_reader :pay_later_redirect_url
      # Attribute for field pay_now_asset_urls_descriptive
      attr_reader :pay_now_asset_urls_descriptive
      # Attribute for field pay_now_asset_urls_standard
      attr_reader :pay_now_asset_urls_standard
      # Attribute for field pay_now_name
      attr_reader :pay_now_name
      # Attribute for field pay_now_redirect_url
      attr_reader :pay_now_redirect_url
      # Attribute for field pay_over_time_asset_urls_descriptive
      attr_reader :pay_over_time_asset_urls_descriptive
      # Attribute for field pay_over_time_asset_urls_standard
      attr_reader :pay_over_time_asset_urls_standard
      # Attribute for field pay_over_time_name
      attr_reader :pay_over_time_name
      # Attribute for field pay_over_time_redirect_url
      attr_reader :pay_over_time_redirect_url
      # Attribute for field payment_method_categories
      attr_reader :payment_method_categories
      # Attribute for field purchase_country
      attr_reader :purchase_country
      # Attribute for field purchase_type
      attr_reader :purchase_type
      # Attribute for field redirect_url
      attr_reader :redirect_url
      # Attribute for field shipping_delay
      attr_reader :shipping_delay
      # Attribute for field shipping_first_name
      attr_reader :shipping_first_name
      # Attribute for field shipping_last_name
      attr_reader :shipping_last_name

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Multibanco < ::Stripe::StripeObject
      # Attribute for field entity
      attr_reader :entity
      # Attribute for field reference
      attr_reader :reference
      # Attribute for field refund_account_holder_address_city
      attr_reader :refund_account_holder_address_city
      # Attribute for field refund_account_holder_address_country
      attr_reader :refund_account_holder_address_country
      # Attribute for field refund_account_holder_address_line1
      attr_reader :refund_account_holder_address_line1
      # Attribute for field refund_account_holder_address_line2
      attr_reader :refund_account_holder_address_line2
      # Attribute for field refund_account_holder_address_postal_code
      attr_reader :refund_account_holder_address_postal_code
      # Attribute for field refund_account_holder_address_state
      attr_reader :refund_account_holder_address_state
      # Attribute for field refund_account_holder_name
      attr_reader :refund_account_holder_name
      # Attribute for field refund_iban
      attr_reader :refund_iban

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Owner < ::Stripe::StripeObject
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

      class VerifiedAddress < ::Stripe::StripeObject
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
      # Owner's address.
      attr_reader :address
      # Owner's email address.
      attr_reader :email
      # Owner's full name.
      attr_reader :name
      # Owner's phone number (including extension).
      attr_reader :phone
      # Verified owner's address. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :verified_address
      # Verified owner's email address. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :verified_email
      # Verified owner's full name. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :verified_name
      # Verified owner's phone number (including extension). Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.
      attr_reader :verified_phone

      def self.inner_class_types
        @inner_class_types = { address: Address, verified_address: VerifiedAddress }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class P24 < ::Stripe::StripeObject
      # Attribute for field reference
      attr_reader :reference

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Receiver < ::Stripe::StripeObject
      # The address of the receiver source. This is the value that should be communicated to the customer to send their funds to.
      attr_reader :address
      # The total amount that was moved to your balance. This is almost always equal to the amount charged. In rare cases when customers deposit excess funds and we are unable to refund those, those funds get moved to your balance and show up in amount_charged as well. The amount charged is expressed in the source's currency.
      attr_reader :amount_charged
      # The total amount received by the receiver source. `amount_received = amount_returned + amount_charged` should be true for consumed sources unless customers deposit excess funds. The amount received is expressed in the source's currency.
      attr_reader :amount_received
      # The total amount that was returned to the customer. The amount returned is expressed in the source's currency.
      attr_reader :amount_returned
      # Type of refund attribute method, one of `email`, `manual`, or `none`.
      attr_reader :refund_attributes_method
      # Type of refund attribute status, one of `missing`, `requested`, or `available`.
      attr_reader :refund_attributes_status

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Redirect < ::Stripe::StripeObject
      # The failure reason for the redirect, either `user_abort` (the customer aborted or dropped out of the redirect flow), `declined` (the authentication failed or the transaction was declined), or `processing_error` (the redirect failed due to a technical error). Present only if the redirect status is `failed`.
      attr_reader :failure_reason
      # The URL you provide to redirect the customer to after they authenticated their payment.
      attr_reader :return_url
      # The status of the redirect, either `pending` (ready to be used by your customer to authenticate the transaction), `succeeded` (successful authentication, cannot be reused) or `not_required` (redirect should not be used) or `failed` (failed authentication, cannot be reused).
      attr_reader :status
      # The URL provided to you to redirect a customer to as part of a `redirect` authentication flow.
      attr_reader :url

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SepaCreditTransfer < ::Stripe::StripeObject
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field bic
      attr_reader :bic
      # Attribute for field iban
      attr_reader :iban
      # Attribute for field refund_account_holder_address_city
      attr_reader :refund_account_holder_address_city
      # Attribute for field refund_account_holder_address_country
      attr_reader :refund_account_holder_address_country
      # Attribute for field refund_account_holder_address_line1
      attr_reader :refund_account_holder_address_line1
      # Attribute for field refund_account_holder_address_line2
      attr_reader :refund_account_holder_address_line2
      # Attribute for field refund_account_holder_address_postal_code
      attr_reader :refund_account_holder_address_postal_code
      # Attribute for field refund_account_holder_address_state
      attr_reader :refund_account_holder_address_state
      # Attribute for field refund_account_holder_name
      attr_reader :refund_account_holder_name
      # Attribute for field refund_iban
      attr_reader :refund_iban

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SepaDebit < ::Stripe::StripeObject
      # Attribute for field bank_code
      attr_reader :bank_code
      # Attribute for field branch_code
      attr_reader :branch_code
      # Attribute for field country
      attr_reader :country
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field mandate_reference
      attr_reader :mandate_reference
      # Attribute for field mandate_url
      attr_reader :mandate_url

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Sofort < ::Stripe::StripeObject
      # Attribute for field bank_code
      attr_reader :bank_code
      # Attribute for field bank_name
      attr_reader :bank_name
      # Attribute for field bic
      attr_reader :bic
      # Attribute for field country
      attr_reader :country
      # Attribute for field iban_last4
      attr_reader :iban_last4
      # Attribute for field preferred_language
      attr_reader :preferred_language
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SourceOrder < ::Stripe::StripeObject
      class Item < ::Stripe::StripeObject
        # The amount (price) for this order item.
        attr_reader :amount
        # This currency of this order item. Required when `amount` is present.
        attr_reader :currency
        # Human-readable description for this order item.
        attr_reader :description
        # The ID of the associated object for this line item. Expandable if not null (e.g., expandable to a SKU).
        attr_reader :parent
        # The quantity of this order item. When type is `sku`, this is the number of instances of the SKU to be ordered.
        attr_reader :quantity
        # The type of this order item. Must be `sku`, `tax`, or `shipping`.
        attr_reader :type

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
      # A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the order.
      attr_reader :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # The email address of the customer placing the order.
      attr_reader :email
      # List of items constituting the order.
      attr_reader :items
      # Attribute for field shipping
      attr_reader :shipping

      def self.inner_class_types
        @inner_class_types = { items: Item, shipping: Shipping }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ThreeDSecure < ::Stripe::StripeObject
      # Attribute for field address_line1_check
      attr_reader :address_line1_check
      # Attribute for field address_zip_check
      attr_reader :address_zip_check
      # Attribute for field authenticated
      attr_reader :authenticated
      # Attribute for field brand
      attr_reader :brand
      # Attribute for field card
      attr_reader :card
      # Attribute for field country
      attr_reader :country
      # Attribute for field customer
      attr_reader :customer
      # Attribute for field cvc_check
      attr_reader :cvc_check
      # Attribute for field description
      attr_reader :description
      # Attribute for field dynamic_last4
      attr_reader :dynamic_last4
      # Attribute for field exp_month
      attr_reader :exp_month
      # Attribute for field exp_year
      attr_reader :exp_year
      # Attribute for field fingerprint
      attr_reader :fingerprint
      # Attribute for field funding
      attr_reader :funding
      # Attribute for field iin
      attr_reader :iin
      # Attribute for field issuer
      attr_reader :issuer
      # Attribute for field last4
      attr_reader :last4
      # Attribute for field name
      attr_reader :name
      # Attribute for field three_d_secure
      attr_reader :three_d_secure
      # Attribute for field tokenization_method
      attr_reader :tokenization_method

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Wechat < ::Stripe::StripeObject
      # Attribute for field prepay_id
      attr_reader :prepay_id
      # Attribute for field qr_code_url
      attr_reader :qr_code_url
      # Attribute for field statement_descriptor
      attr_reader :statement_descriptor

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
    # Attribute for field alipay
    attr_reader :alipay
    # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow. The field defaults to “unspecified”.
    attr_reader :allow_redisplay
    # A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount associated with the source. This is the amount for which the source will be chargeable once ready. Required for `single_use` sources.
    attr_reader :amount
    # Attribute for field au_becs_debit
    attr_reader :au_becs_debit
    # Attribute for field bancontact
    attr_reader :bancontact
    # Attribute for field card
    attr_reader :card
    # Attribute for field card_present
    attr_reader :card_present
    # The client secret of the source. Used for client-side retrieval using a publishable key.
    attr_reader :client_secret
    # Attribute for field code_verification
    attr_reader :code_verification
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO code for the currency](https://stripe.com/docs/currencies) associated with the source. This is the currency for which the source will be chargeable once ready. Required for `single_use` sources.
    attr_reader :currency
    # The ID of the customer to which this source is attached. This will not be present when the source has not been attached to a customer.
    attr_reader :customer
    # Attribute for field eps
    attr_reader :eps
    # The authentication `flow` of the source. `flow` is one of `redirect`, `receiver`, `code_verification`, `none`.
    attr_reader :flow
    # Attribute for field giropay
    attr_reader :giropay
    # Unique identifier for the object.
    attr_reader :id
    # Attribute for field ideal
    attr_reader :ideal
    # Attribute for field klarna
    attr_reader :klarna
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Attribute for field multibanco
    attr_reader :multibanco
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Information about the owner of the payment instrument that may be used or required by particular source types.
    attr_reader :owner
    # Attribute for field p24
    attr_reader :p24
    # Attribute for field receiver
    attr_reader :receiver
    # Attribute for field redirect
    attr_reader :redirect
    # Attribute for field sepa_credit_transfer
    attr_reader :sepa_credit_transfer
    # Attribute for field sepa_debit
    attr_reader :sepa_debit
    # Attribute for field sofort
    attr_reader :sofort
    # Attribute for field source_order
    attr_reader :source_order
    # Extra information about a source. This will appear on your customer's statement every time you charge the source.
    attr_reader :statement_descriptor
    # The status of the source, one of `canceled`, `chargeable`, `consumed`, `failed`, or `pending`. Only `chargeable` sources can be used to create a charge.
    attr_reader :status
    # Attribute for field three_d_secure
    attr_reader :three_d_secure
    # The `type` of the source. The `type` is a payment method, one of `ach_credit_transfer`, `ach_debit`, `alipay`, `bancontact`, `card`, `card_present`, `eps`, `giropay`, `ideal`, `multibanco`, `klarna`, `p24`, `sepa_debit`, `sofort`, `three_d_secure`, or `wechat`. An additional hash is included on the source with a name matching this value. It contains additional information specific to the [payment method](https://stripe.com/docs/sources) used.
    attr_reader :type
    # Either `reusable` or `single_use`. Whether this source should be reusable or not. Some source types may or may not be reusable by construction, while others may leave the option at creation. If an incompatible value is passed, an error will be returned.
    attr_reader :usage
    # Attribute for field wechat
    attr_reader :wechat

    # Creates a new source object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/sources", params: params, opts: opts)
    end

    # Updates the specified source by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request accepts the metadata and owner as arguments. It is also possible to update type specific information for selected payment methods. Please refer to our [payment method guides](https://docs.stripe.com/docs/sources) for more detail.
    def self.update(source, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/sources/%<source>s", { source: CGI.escape(source) }),
        params: params,
        opts: opts
      )
    end

    # Verify a given source.
    def verify(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/sources/%<source>s/verify", { source: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Verify a given source.
    def self.verify(source, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/sources/%<source>s/verify", { source: CGI.escape(source) }),
        params: params,
        opts: opts
      )
    end

    def detach(params = {}, opts = {})
      if !respond_to?(:customer) || customer.nil? || customer.empty?
        raise NotImplementedError,
              "This source object does not appear to be currently attached " \
              "to a customer object."
      end

      url = "#{Customer.resource_url}/#{CGI.escape(customer)}/sources" \
            "/#{CGI.escape(id)}"
      opts = Util.normalize_opts(opts)
      APIRequestor.active_requestor.execute_request_initialize_from(:delete, url, :api, self,
                                                                    params: params, opts: RequestOptions.extract_opts_from_hash(opts))
    end

    def source_transactions(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: resource_url + "/source_transactions",
        params: params,
        opts: opts
      )
    end
    extend Gem::Deprecate
    deprecate :source_transactions, :"Source.list_source_transactions", 2020, 1

    def self.inner_class_types
      @inner_class_types = {
        ach_credit_transfer: AchCreditTransfer,
        ach_debit: AchDebit,
        acss_debit: AcssDebit,
        alipay: Alipay,
        au_becs_debit: AuBecsDebit,
        bancontact: Bancontact,
        card: Card,
        card_present: CardPresent,
        code_verification: CodeVerification,
        eps: Eps,
        giropay: Giropay,
        ideal: Ideal,
        klarna: Klarna,
        multibanco: Multibanco,
        owner: Owner,
        p24: P24,
        receiver: Receiver,
        redirect: Redirect,
        sepa_credit_transfer: SepaCreditTransfer,
        sepa_debit: SepaDebit,
        sofort: Sofort,
        source_order: SourceOrder,
        three_d_secure: ThreeDSecure,
        wechat: Wechat,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
