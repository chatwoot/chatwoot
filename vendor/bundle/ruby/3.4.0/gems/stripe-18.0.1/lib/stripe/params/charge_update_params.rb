# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ChargeUpdateParams < ::Stripe::RequestParams
    class FraudDetails < ::Stripe::RequestParams
      # Either `safe` or `fraudulent`.
      attr_accessor :user_report

      def initialize(user_report: nil)
        @user_report = user_report
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
    # The ID of an existing customer that will be associated with this request. This field may only be updated if there is no existing associated customer with this charge.
    attr_accessor :customer
    # An arbitrary string which you can attach to a charge object. It is displayed when in the web interface alongside the charge. Note that if you use Stripe to send automatic email receipts to your customers, your receipt emails will include the `description` of the charge(s) that they are describing.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A set of key-value pairs you can attach to a charge giving information about its riskiness. If you believe a charge is fraudulent, include a `user_report` key with a value of `fraudulent`. If you believe a charge is safe, include a `user_report` key with a value of `safe`. Stripe will use the information you send to improve our fraud detection algorithms.
    attr_accessor :fraud_details
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # This is the email address that the receipt for this charge will be sent to. If this field is updated, then a new email receipt will be sent to the updated address.
    attr_accessor :receipt_email
    # Shipping information for the charge. Helps prevent fraud on charges for physical goods.
    attr_accessor :shipping
    # A string that identifies this transaction as part of a group. `transfer_group` may only be provided if it has not been set. See the [Connect documentation](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options) for details.
    attr_accessor :transfer_group

    def initialize(
      customer: nil,
      description: nil,
      expand: nil,
      fraud_details: nil,
      metadata: nil,
      receipt_email: nil,
      shipping: nil,
      transfer_group: nil
    )
      @customer = customer
      @description = description
      @expand = expand
      @fraud_details = fraud_details
      @metadata = metadata
      @receipt_email = receipt_email
      @shipping = shipping
      @transfer_group = transfer_group
    end
  end
end
