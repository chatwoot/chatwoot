# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Each customer has a [`balance`](https://stripe.com/docs/api/customers/object#customer_object-balance) that is
  # automatically applied to future invoices and payments using the `customer_balance` payment method.
  # Customers can fund this balance by initiating a bank transfer to any account in the
  # `financial_addresses` field.
  # Related guide: [Customer balance funding instructions](https://stripe.com/docs/payments/customer-balance/funding-instructions)
  class FundingInstructions < APIResource
    OBJECT_NAME = "funding_instructions"
    def self.object_name
      "funding_instructions"
    end

    class BankTransfer < ::Stripe::StripeObject
      class FinancialAddress < ::Stripe::StripeObject
        class Aba < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The account holder name
          attr_reader :account_holder_name
          # The ABA account number
          attr_reader :account_number
          # The account type
          attr_reader :account_type
          # Attribute for field bank_address
          attr_reader :bank_address
          # The bank name
          attr_reader :bank_name
          # The ABA routing number
          attr_reader :routing_number

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Iban < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The name of the person or business that owns the bank account
          attr_reader :account_holder_name
          # Attribute for field bank_address
          attr_reader :bank_address
          # The BIC/SWIFT code of the account.
          attr_reader :bic
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_reader :country
          # The IBAN of the account.
          attr_reader :iban

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SortCode < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The name of the person or business that owns the bank account
          attr_reader :account_holder_name
          # The account number
          attr_reader :account_number
          # Attribute for field bank_address
          attr_reader :bank_address
          # The six-digit sort code
          attr_reader :sort_code

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Spei < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The account holder name
          attr_reader :account_holder_name
          # Attribute for field bank_address
          attr_reader :bank_address
          # The three-digit bank code
          attr_reader :bank_code
          # The short banking institution name
          attr_reader :bank_name
          # The CLABE number
          attr_reader :clabe

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Swift < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The account holder name
          attr_reader :account_holder_name
          # The account number
          attr_reader :account_number
          # The account type
          attr_reader :account_type
          # Attribute for field bank_address
          attr_reader :bank_address
          # The bank name
          attr_reader :bank_name
          # The SWIFT code
          attr_reader :swift_code

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Zengin < ::Stripe::StripeObject
          class AccountHolderAddress < ::Stripe::StripeObject
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

          class BankAddress < ::Stripe::StripeObject
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
          # Attribute for field account_holder_address
          attr_reader :account_holder_address
          # The account holder name
          attr_reader :account_holder_name
          # The account number
          attr_reader :account_number
          # The bank account type. In Japan, this can only be `futsu` or `toza`.
          attr_reader :account_type
          # Attribute for field bank_address
          attr_reader :bank_address
          # The bank code of the account
          attr_reader :bank_code
          # The bank name of the account
          attr_reader :bank_name
          # The branch code of the account
          attr_reader :branch_code
          # The branch name of the account
          attr_reader :branch_name

          def self.inner_class_types
            @inner_class_types = {
              account_holder_address: AccountHolderAddress,
              bank_address: BankAddress,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # ABA Records contain U.S. bank account details per the ABA format.
        attr_reader :aba
        # Iban Records contain E.U. bank account details per the SEPA format.
        attr_reader :iban
        # Sort Code Records contain U.K. bank account details per the sort code format.
        attr_reader :sort_code
        # SPEI Records contain Mexico bank account details per the SPEI format.
        attr_reader :spei
        # The payment networks supported by this FinancialAddress
        attr_reader :supported_networks
        # SWIFT Records contain U.S. bank account details per the SWIFT format.
        attr_reader :swift
        # The type of financial address
        attr_reader :type
        # Zengin Records contain Japan bank account details per the Zengin format.
        attr_reader :zengin

        def self.inner_class_types
          @inner_class_types = {
            aba: Aba,
            iban: Iban,
            sort_code: SortCode,
            spei: Spei,
            swift: Swift,
            zengin: Zengin,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The country of the bank account to fund
      attr_reader :country
      # A list of financial addresses that can be used to fund a particular balance
      attr_reader :financial_addresses
      # The bank_transfer type
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { financial_addresses: FinancialAddress }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Attribute for field bank_transfer
    attr_reader :bank_transfer
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # The `funding_type` of the returned instructions
    attr_reader :funding_type
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    def resource_url
      if !respond_to?(:customer) || customer.nil?
        raise NotImplementedError,
              "FundingInstructions cannot be accessed without a customer ID."
      end
      "#{Customer.resource_url}/#{CGI.escape(customer)}/funding_instructions" + "/#{CGI.escape(id)}"
    end

    def self.inner_class_types
      @inner_class_types = { bank_transfer: BankTransfer }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
