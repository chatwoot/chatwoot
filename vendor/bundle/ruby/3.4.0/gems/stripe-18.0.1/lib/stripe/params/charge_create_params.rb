# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ChargeCreateParams < ::Stripe::RequestParams
    class Destination < ::Stripe::RequestParams
      # ID of an existing, connected Stripe account.
      attr_accessor :account
      # The amount to transfer to the destination account without creating an `Application Fee` object. Cannot be combined with the `application_fee` parameter. Must be less than or equal to the charge amount.
      attr_accessor :amount

      def initialize(account: nil, amount: nil)
        @account = account
        @amount = amount
      end
    end

    class RadarOptions < ::Stripe::RequestParams
      # A [Radar Session](https://stripe.com/docs/radar/radar-session) is a snapshot of the browser metadata and device details that help Radar make more accurate predictions on your payments.
      attr_accessor :session

      def initialize(session: nil)
        @session = session
      end
    end

    class Shipping < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end
      # Shipping address.
      attr_accessor :address
      # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
      attr_accessor :carrier
      # Recipient name.
      attr_accessor :name
      # Recipient phone (including extension).
      attr_accessor :phone
      # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
      attr_accessor :tracking_number

      def initialize(address: nil, carrier: nil, name: nil, phone: nil, tracking_number: nil)
        @address = address
        @carrier = carrier
        @name = name
        @phone = phone
        @tracking_number = tracking_number
      end
    end

    class TransferData < ::Stripe::RequestParams
      # The amount transferred to the destination account, if specified. By default, the entire charge amount is transferred to the destination account.
      attr_accessor :amount
      # ID of an existing, connected Stripe account.
      attr_accessor :destination

      def initialize(amount: nil, destination: nil)
        @amount = amount
        @destination = destination
      end
    end
    # Amount intended to be collected by this payment. A positive integer representing how much to charge in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or [equivalent in charge currency](https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts). The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).
    attr_accessor :amount
    # Attribute for param field application_fee
    attr_accessor :application_fee
    # A fee in cents (or local equivalent) that will be applied to the charge and transferred to the application owner's Stripe account. The request must be made with an OAuth key or the `Stripe-Account` header in order to take an application fee. For more information, see the application fees [documentation](https://stripe.com/docs/connect/direct-charges#collect-fees).
    attr_accessor :application_fee_amount
    # Whether to immediately capture the charge. Defaults to `true`. When `false`, the charge issues an authorization (or pre-authorization), and will need to be [captured](https://stripe.com/docs/api#capture_charge) later. Uncaptured charges expire after a set number of days (7 by default). For more information, see the [authorizing charges and settling later](https://stripe.com/docs/charges/placing-a-hold) documentation.
    attr_accessor :capture
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # The ID of an existing customer that will be charged in this request.
    attr_accessor :customer
    # An arbitrary string which you can attach to a `Charge` object. It is displayed when in the web interface alongside the charge. Note that if you use Stripe to send automatic email receipts to your customers, your receipt emails will include the `description` of the charge(s) that they are describing.
    attr_accessor :description
    # Attribute for param field destination
    attr_accessor :destination
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The Stripe account ID for which these funds are intended. Automatically set if you use the `destination` parameter. For details, see [Creating Separate Charges and Transfers](https://stripe.com/docs/connect/separate-charges-and-transfers#settlement-merchant).
    attr_accessor :on_behalf_of
    # Options to configure Radar. See [Radar Session](https://stripe.com/docs/radar/radar-session) for more information.
    attr_accessor :radar_options
    # The email address to which this charge's [receipt](https://stripe.com/docs/dashboard/receipts) will be sent. The receipt will not be sent until the charge is paid, and no receipts will be sent for test mode charges. If this charge is for a [Customer](https://stripe.com/docs/api/customers/object), the email address specified here will override the customer's email address. If `receipt_email` is specified for a charge in live mode, a receipt will be sent regardless of your [email settings](https://dashboard.stripe.com/account/emails).
    attr_accessor :receipt_email
    # Shipping information for the charge. Helps prevent fraud on charges for physical goods.
    attr_accessor :shipping
    # A payment source to be charged. This can be the ID of a [card](https://stripe.com/docs/api#cards) (i.e., credit or debit card), a [bank account](https://stripe.com/docs/api#bank_accounts), a [source](https://stripe.com/docs/api#sources), a [token](https://stripe.com/docs/api#tokens), or a [connected account](https://stripe.com/docs/connect/account-debits#charging-a-connected-account). For certain sources---namely, [cards](https://stripe.com/docs/api#cards), [bank accounts](https://stripe.com/docs/api#bank_accounts), and attached [sources](https://stripe.com/docs/api#sources)---you must also pass the ID of the associated customer.
    attr_accessor :source
    # For a non-card charge, text that appears on the customer's statement as the statement descriptor. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    #
    # For a card charge, this value is ignored unless you don't specify a `statement_descriptor_suffix`, in which case this value is used as the suffix.
    attr_accessor :statement_descriptor
    # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement. If the account has no prefix value, the suffix is concatenated to the account's statement descriptor.
    attr_accessor :statement_descriptor_suffix
    # An optional dictionary including the account to automatically transfer to as part of a destination charge. [See the Connect documentation](https://stripe.com/docs/connect/destination-charges) for details.
    attr_accessor :transfer_data
    # A string that identifies this transaction as part of a group. For details, see [Grouping transactions](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options).
    attr_accessor :transfer_group

    def initialize(
      amount: nil,
      application_fee: nil,
      application_fee_amount: nil,
      capture: nil,
      currency: nil,
      customer: nil,
      description: nil,
      destination: nil,
      expand: nil,
      metadata: nil,
      on_behalf_of: nil,
      radar_options: nil,
      receipt_email: nil,
      shipping: nil,
      source: nil,
      statement_descriptor: nil,
      statement_descriptor_suffix: nil,
      transfer_data: nil,
      transfer_group: nil
    )
      @amount = amount
      @application_fee = application_fee
      @application_fee_amount = application_fee_amount
      @capture = capture
      @currency = currency
      @customer = customer
      @description = description
      @destination = destination
      @expand = expand
      @metadata = metadata
      @on_behalf_of = on_behalf_of
      @radar_options = radar_options
      @receipt_email = receipt_email
      @shipping = shipping
      @source = source
      @statement_descriptor = statement_descriptor
      @statement_descriptor_suffix = statement_descriptor_suffix
      @transfer_data = transfer_data
      @transfer_group = transfer_group
    end
  end
end
