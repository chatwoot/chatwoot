# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # Stripe Treasury provides users with a container for money called a FinancialAccount that is separate from their Payments balance.
    # FinancialAccounts serve as the source and destination of Treasury's money movement APIs.
    class FinancialAccount < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "treasury.financial_account"
      def self.object_name
        "treasury.financial_account"
      end

      class Balance < ::Stripe::StripeObject
        # Funds the user can spend right now.
        attr_reader :cash
        # Funds not spendable yet, but will become available at a later time.
        attr_reader :inbound_pending
        # Funds in the account, but not spendable because they are being held for pending outbound flows.
        attr_reader :outbound_pending

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FinancialAddress < ::Stripe::StripeObject
        class Aba < ::Stripe::StripeObject
          # The name of the person or business that owns the bank account.
          attr_reader :account_holder_name
          # The account number.
          attr_reader :account_number
          # The last four characters of the account number.
          attr_reader :account_number_last4
          # Name of the bank.
          attr_reader :bank_name
          # Routing number for the account.
          attr_reader :routing_number

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # ABA Records contain U.S. bank account details per the ABA format.
        attr_reader :aba
        # The list of networks that the address supports
        attr_reader :supported_networks
        # The type of financial address
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = { aba: Aba }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PlatformRestrictions < ::Stripe::StripeObject
        # Restricts all inbound money movement.
        attr_reader :inbound_flows
        # Restricts all outbound money movement.
        attr_reader :outbound_flows

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StatusDetails < ::Stripe::StripeObject
        class Closed < ::Stripe::StripeObject
          # The array that contains reasons for a FinancialAccount closure.
          attr_reader :reasons

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Details related to the closure of this FinancialAccount
        attr_reader :closed

        def self.inner_class_types
          @inner_class_types = { closed: Closed }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The array of paths to active Features in the Features hash.
      attr_reader :active_features
      # Balance information for the FinancialAccount
      attr_reader :balance
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Encodes whether a FinancialAccount has access to a particular Feature, with a `status` enum and associated `status_details`.
      # Stripe or the platform can control Features via the requested field.
      attr_reader :features
      # The set of credentials that resolve to a FinancialAccount.
      attr_reader :financial_addresses
      # Unique identifier for the object.
      attr_reader :id
      # Attribute for field is_default
      attr_reader :is_default
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The nickname for the FinancialAccount.
      attr_reader :nickname
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The array of paths to pending Features in the Features hash.
      attr_reader :pending_features
      # The set of functionalities that the platform can restrict on the FinancialAccount.
      attr_reader :platform_restrictions
      # The array of paths to restricted Features in the Features hash.
      attr_reader :restricted_features
      # Status of this FinancialAccount.
      attr_reader :status
      # Attribute for field status_details
      attr_reader :status_details
      # The currencies the FinancialAccount can hold a balance in. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase.
      attr_reader :supported_currencies

      # Closes a FinancialAccount. A FinancialAccount can only be closed if it has a zero balance, has no pending InboundTransfers, and has canceled all attached Issuing cards.
      def close(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/close", { financial_account: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Closes a FinancialAccount. A FinancialAccount can only be closed if it has a zero balance, has no pending InboundTransfers, and has canceled all attached Issuing cards.
      def self.close(financial_account, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/close", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts
        )
      end

      # Creates a new FinancialAccount. Each connected account can have up to three FinancialAccounts by default.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/treasury/financial_accounts",
          params: params,
          opts: opts
        )
      end

      # Returns a list of FinancialAccounts.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/financial_accounts",
          params: params,
          opts: opts
        )
      end

      # Retrieves Features information associated with the FinancialAccount.
      def retrieve_features(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Retrieves Features information associated with the FinancialAccount.
      def self.retrieve_features(financial_account, params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts
        )
      end

      # Updates the details of a FinancialAccount.
      def self.update(financial_account, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts
        )
      end

      # Updates the Features associated with a FinancialAccount.
      def update_features(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Updates the Features associated with a FinancialAccount.
      def self.update_features(financial_account, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          balance: Balance,
          financial_addresses: FinancialAddress,
          platform_restrictions: PlatformRestrictions,
          status_details: StatusDetails,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
