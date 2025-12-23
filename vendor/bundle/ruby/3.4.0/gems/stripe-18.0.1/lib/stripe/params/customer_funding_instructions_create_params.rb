# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerFundingInstructionsCreateParams < ::Stripe::RequestParams
    class BankTransfer < ::Stripe::RequestParams
      class EuBankTransfer < ::Stripe::RequestParams
        # The desired country code of the bank account information. Permitted values include: `BE`, `DE`, `ES`, `FR`, `IE`, or `NL`.
        attr_accessor :country

        def initialize(country: nil)
          @country = country
        end
      end
      # Configuration for eu_bank_transfer funding type.
      attr_accessor :eu_bank_transfer
      # List of address types that should be returned in the financial_addresses response. If not specified, all valid types will be returned.
      #
      # Permitted values include: `sort_code`, `zengin`, `iban`, or `spei`.
      attr_accessor :requested_address_types
      # The type of the `bank_transfer`
      attr_accessor :type

      def initialize(eu_bank_transfer: nil, requested_address_types: nil, type: nil)
        @eu_bank_transfer = eu_bank_transfer
        @requested_address_types = requested_address_types
        @type = type
      end
    end
    # Additional parameters for `bank_transfer` funding types
    attr_accessor :bank_transfer
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The `funding_type` to get the instructions for.
    attr_accessor :funding_type

    def initialize(bank_transfer: nil, currency: nil, expand: nil, funding_type: nil)
      @bank_transfer = bank_transfer
      @currency = currency
      @expand = expand
      @funding_type = funding_type
    end
  end
end
