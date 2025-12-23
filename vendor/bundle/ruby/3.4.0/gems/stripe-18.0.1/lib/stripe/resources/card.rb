# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # You can store multiple cards on a customer in order to charge the customer
  # later. You can also store multiple debit cards on a recipient in order to
  # transfer to those cards later.
  #
  # Related guide: [Card payments with Sources](https://stripe.com/docs/sources/cards)
  class Card < APIResource
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "card"
    def self.object_name
      "card"
    end

    class Networks < ::Stripe::StripeObject
      # The preferred network for co-branded cards. Can be `cartes_bancaires`, `mastercard`, `visa` or `invalid_preference` if requested network is not valid for the card.
      attr_reader :preferred

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Attribute for field account
    attr_reader :account
    # City/District/Suburb/Town/Village.
    attr_reader :address_city
    # Billing address country, if provided when creating card.
    attr_reader :address_country
    # Address line 1 (Street address/PO Box/Company name).
    attr_reader :address_line1
    # If `address_line1` was provided, results of the check: `pass`, `fail`, `unavailable`, or `unchecked`.
    attr_reader :address_line1_check
    # Address line 2 (Apartment/Suite/Unit/Building).
    attr_reader :address_line2
    # State/County/Province/Region.
    attr_reader :address_state
    # ZIP or postal code.
    attr_reader :address_zip
    # If `address_zip` was provided, results of the check: `pass`, `fail`, `unavailable`, or `unchecked`.
    attr_reader :address_zip_check
    # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow. The field defaults to “unspecified”.
    attr_reader :allow_redisplay
    # A set of available payout methods for this card. Only values from this set should be passed as the `method` when creating a payout.
    attr_reader :available_payout_methods
    # Card brand. Can be `American Express`, `Cartes Bancaires`, `Diners Club`, `Discover`, `Eftpos Australia`, `Girocard`, `JCB`, `MasterCard`, `UnionPay`, `Visa`, or `Unknown`.
    attr_reader :brand
    # Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you've collected.
    attr_reader :country
    # Three-letter [ISO code for currency](https://www.iso.org/iso-4217-currency-codes.html) in lowercase. Must be a [supported currency](https://docs.stripe.com/currencies). Only applicable on accounts (not customers or recipients). The card can be used as a transfer destination for funds in this currency. This property is only available when returned as an [External Account](/api/external_account_cards/object) where [controller.is_controller](/api/accounts/object#account_object-controller-is_controller) is `true`.
    attr_reader :currency
    # The customer that this card belongs to. This attribute will not be in the card object if the card belongs to an account or recipient instead.
    attr_reader :customer
    # If a CVC was provided, results of the check: `pass`, `fail`, `unavailable`, or `unchecked`. A result of unchecked indicates that CVC was provided but hasn't been checked yet. Checks are typically performed when attaching a card to a Customer object, or when creating a charge. For more details, see [Check if a card is valid without a charge](https://support.stripe.com/questions/check-if-a-card-is-valid-without-a-charge).
    attr_reader :cvc_check
    # Whether this card is the default external account for its currency. This property is only available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts.
    attr_reader :default_for_currency
    # A high-level description of the type of cards issued in this range. (For internal use only and not typically available in standard API requests.)
    attr_reader :description
    # (For tokenized numbers only.) The last four digits of the device account number.
    attr_reader :dynamic_last4
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
    # Unique identifier for the object.
    attr_reader :id
    # Issuer identification number of the card. (For internal use only and not typically available in standard API requests.)
    attr_reader :iin
    # The name of the card's issuing bank. (For internal use only and not typically available in standard API requests.)
    attr_reader :issuer
    # The last four digits of the card.
    attr_reader :last4
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Cardholder name.
    attr_reader :name
    # Attribute for field networks
    attr_reader :networks
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Status of a card based on the card issuer.
    attr_reader :regulated_status
    # For external accounts that are cards, possible values are `new` and `errored`. If a payout fails, the status is set to `errored` and [scheduled payouts](https://stripe.com/docs/payouts#payout-schedule) are stopped until account details are updated.
    attr_reader :status
    # If the card number is tokenized, this is the method that was used. Can be `android_pay` (includes Google Pay), `apple_pay`, `masterpass`, `visa_checkout`, or null.
    attr_reader :tokenization_method
    # Always true for a deleted object
    attr_reader :deleted

    def resource_url
      if respond_to?(:customer) && !customer.nil? && !customer.empty?
        "#{Customer.resource_url}/#{CGI.escape(customer)}/sources/#{CGI.escape(id)}"
      elsif respond_to?(:account) && !account.nil? && !account.empty?
        "#{Account.resource_url}/#{CGI.escape(account)}/external_accounts/#{CGI.escape(id)}"
      end
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Card cannot be updated without a customer ID or an account ID. " \
            "Update a card using `Customer.update_source('customer_id', " \
            "'card_id', update_params)` or `Account.update_external_account(" \
            "'account_id', 'card_id', update_params)`"
    end

    def self.retrieve(_id, _opts = nil)
      raise NotImplementedError,
            "Card cannot be retrieved without a customer ID or an account " \
            "ID. Retrieve a card using `Customer.retrieve_source(" \
            "'customer_id', 'card_id')` or " \
            "`Account.retrieve_external_account('account_id', 'card_id')`"
    end

    def self.delete(id, params = {}, opts = {})
      raise NotImplementedError,
            "Card cannot be deleted without a customer ID or an account " \
            "ID. Delete a card using `Customer.delete_source(" \
            "'customer_id', 'card_id')` or " \
            "`Account.delete_external_account('account_id', 'card_id')`"
    end

    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: resource_url.to_s,
        params: params,
        opts: opts
      )
    end

    def self.list(params = {}, opts = {})
      raise NotImplementedError,
            "Cards cannot be listed without a customer ID or an account " \
            "ID. List cards using `Customer.list_sources(" \
            "'customer_id')` or " \
            "`Account.list_external_accounts('account_id')`"
    end

    def self.inner_class_types
      @inner_class_types = { networks: Networks }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
