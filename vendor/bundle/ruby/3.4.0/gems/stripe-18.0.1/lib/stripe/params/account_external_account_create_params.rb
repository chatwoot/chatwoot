# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountExternalAccountCreateParams < ::Stripe::RequestParams
    class BankAccount < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # The name of the person or business that owns the bank account.This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_name
      # The type of entity that holds the account. It can be `company` or `individual`. This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_type
      # The account number for the bank account, in string form. Must be a checking account.
      attr_accessor :account_number
      # The country in which the bank account is located.
      attr_accessor :country
      # The currency the bank account is in. This must be a country/currency pairing that [Stripe supports.](docs/payouts)
      attr_accessor :currency
      # The routing number, sort code, or other country-appropriate institution number for the bank account. For US bank accounts, this is required and should be the ACH routing number, not the wire routing number. If you are providing an IBAN for `account_number`, this field is not required.
      attr_accessor :routing_number

      def initialize(
        object: nil,
        account_holder_name: nil,
        account_holder_type: nil,
        account_number: nil,
        country: nil,
        currency: nil,
        routing_number: nil
      )
        @object = object
        @account_holder_name = account_holder_name
        @account_holder_type = account_holder_type
        @account_number = account_number
        @country = country
        @currency = currency
        @routing_number = routing_number
      end
    end

    class Card < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # Attribute for param field address_city
      attr_accessor :address_city
      # Attribute for param field address_country
      attr_accessor :address_country
      # Attribute for param field address_line1
      attr_accessor :address_line1
      # Attribute for param field address_line2
      attr_accessor :address_line2
      # Attribute for param field address_state
      attr_accessor :address_state
      # Attribute for param field address_zip
      attr_accessor :address_zip
      # Attribute for param field currency
      attr_accessor :currency
      # Attribute for param field cvc
      attr_accessor :cvc
      # Attribute for param field exp_month
      attr_accessor :exp_month
      # Attribute for param field exp_year
      attr_accessor :exp_year
      # Attribute for param field name
      attr_accessor :name
      # Attribute for param field number
      attr_accessor :number
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_accessor :metadata

      def initialize(
        object: nil,
        address_city: nil,
        address_country: nil,
        address_line1: nil,
        address_line2: nil,
        address_state: nil,
        address_zip: nil,
        currency: nil,
        cvc: nil,
        exp_month: nil,
        exp_year: nil,
        name: nil,
        number: nil,
        metadata: nil
      )
        @object = object
        @address_city = address_city
        @address_country = address_country
        @address_line1 = address_line1
        @address_line2 = address_line2
        @address_state = address_state
        @address_zip = address_zip
        @currency = currency
        @cvc = cvc
        @exp_month = exp_month
        @exp_year = exp_year
        @name = name
        @number = number
        @metadata = metadata
      end
    end

    class CardToken < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # Attribute for param field currency
      attr_accessor :currency
      # Attribute for param field token
      attr_accessor :token

      def initialize(object: nil, currency: nil, token: nil)
        @object = object
        @currency = currency
        @token = token
      end
    end
    # When set to true, or if this is the first external account added in this currency, this account becomes the default external account for its currency.
    attr_accessor :default_for_currency
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A token, like the ones returned by [Stripe.js](https://stripe.com/docs/js) or a dictionary containing a user's external account details (with the options shown below). Please refer to full [documentation](https://stripe.com/docs/api/external_accounts) instead.
    attr_accessor :external_account
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(default_for_currency: nil, expand: nil, external_account: nil, metadata: nil)
      @default_for_currency = default_for_currency
      @expand = expand
      @external_account = external_account
      @metadata = metadata
    end
  end
end
