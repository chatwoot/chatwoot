# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class FinancialAccountUpdateParams < ::Stripe::RequestParams
      class Features < ::Stripe::RequestParams
        class CardIssuing < ::Stripe::RequestParams
          # Whether the FinancialAccount should have the Feature.
          attr_accessor :requested

          def initialize(requested: nil)
            @requested = requested
          end
        end

        class DepositInsurance < ::Stripe::RequestParams
          # Whether the FinancialAccount should have the Feature.
          attr_accessor :requested

          def initialize(requested: nil)
            @requested = requested
          end
        end

        class FinancialAddresses < ::Stripe::RequestParams
          class Aba < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end
          # Adds an ABA FinancialAddress to the FinancialAccount.
          attr_accessor :aba

          def initialize(aba: nil)
            @aba = aba
          end
        end

        class InboundTransfers < ::Stripe::RequestParams
          class Ach < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end
          # Enables ACH Debits via the InboundTransfers API.
          attr_accessor :ach

          def initialize(ach: nil)
            @ach = ach
          end
        end

        class IntraStripeFlows < ::Stripe::RequestParams
          # Whether the FinancialAccount should have the Feature.
          attr_accessor :requested

          def initialize(requested: nil)
            @requested = requested
          end
        end

        class OutboundPayments < ::Stripe::RequestParams
          class Ach < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end

          class UsDomesticWire < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end
          # Enables ACH transfers via the OutboundPayments API.
          attr_accessor :ach
          # Enables US domestic wire transfers via the OutboundPayments API.
          attr_accessor :us_domestic_wire

          def initialize(ach: nil, us_domestic_wire: nil)
            @ach = ach
            @us_domestic_wire = us_domestic_wire
          end
        end

        class OutboundTransfers < ::Stripe::RequestParams
          class Ach < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end

          class UsDomesticWire < ::Stripe::RequestParams
            # Whether the FinancialAccount should have the Feature.
            attr_accessor :requested

            def initialize(requested: nil)
              @requested = requested
            end
          end
          # Enables ACH transfers via the OutboundTransfers API.
          attr_accessor :ach
          # Enables US domestic wire transfers via the OutboundTransfers API.
          attr_accessor :us_domestic_wire

          def initialize(ach: nil, us_domestic_wire: nil)
            @ach = ach
            @us_domestic_wire = us_domestic_wire
          end
        end
        # Encodes the FinancialAccount's ability to be used with the Issuing product, including attaching cards to and drawing funds from the FinancialAccount.
        attr_accessor :card_issuing
        # Represents whether this FinancialAccount is eligible for deposit insurance. Various factors determine the insurance amount.
        attr_accessor :deposit_insurance
        # Contains Features that add FinancialAddresses to the FinancialAccount.
        attr_accessor :financial_addresses
        # Contains settings related to adding funds to a FinancialAccount from another Account with the same owner.
        attr_accessor :inbound_transfers
        # Represents the ability for the FinancialAccount to send money to, or receive money from other FinancialAccounts (for example, via OutboundPayment).
        attr_accessor :intra_stripe_flows
        # Includes Features related to initiating money movement out of the FinancialAccount to someone else's bucket of money.
        attr_accessor :outbound_payments
        # Contains a Feature and settings related to moving money out of the FinancialAccount into another Account with the same owner.
        attr_accessor :outbound_transfers

        def initialize(
          card_issuing: nil,
          deposit_insurance: nil,
          financial_addresses: nil,
          inbound_transfers: nil,
          intra_stripe_flows: nil,
          outbound_payments: nil,
          outbound_transfers: nil
        )
          @card_issuing = card_issuing
          @deposit_insurance = deposit_insurance
          @financial_addresses = financial_addresses
          @inbound_transfers = inbound_transfers
          @intra_stripe_flows = intra_stripe_flows
          @outbound_payments = outbound_payments
          @outbound_transfers = outbound_transfers
        end
      end

      class ForwardingSettings < ::Stripe::RequestParams
        # The financial_account id
        attr_accessor :financial_account
        # The payment_method or bank account id. This needs to be a verified bank account.
        attr_accessor :payment_method
        # The type of the bank account provided. This can be either "financial_account" or "payment_method"
        attr_accessor :type

        def initialize(financial_account: nil, payment_method: nil, type: nil)
          @financial_account = financial_account
          @payment_method = payment_method
          @type = type
        end
      end

      class PlatformRestrictions < ::Stripe::RequestParams
        # Restricts all inbound money movement.
        attr_accessor :inbound_flows
        # Restricts all outbound money movement.
        attr_accessor :outbound_flows

        def initialize(inbound_flows: nil, outbound_flows: nil)
          @inbound_flows = inbound_flows
          @outbound_flows = outbound_flows
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Encodes whether a FinancialAccount has access to a particular feature, with a status enum and associated `status_details`. Stripe or the platform may control features via the requested field.
      attr_accessor :features
      # A different bank account where funds can be deposited/debited in order to get the closing FA's balance to $0
      attr_accessor :forwarding_settings
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The nickname for the FinancialAccount.
      attr_accessor :nickname
      # The set of functionalities that the platform can restrict on the FinancialAccount.
      attr_accessor :platform_restrictions

      def initialize(
        expand: nil,
        features: nil,
        forwarding_settings: nil,
        metadata: nil,
        nickname: nil,
        platform_restrictions: nil
      )
        @expand = expand
        @features = features
        @forwarding_settings = forwarding_settings
        @metadata = metadata
        @nickname = nickname
        @platform_restrictions = platform_restrictions
      end
    end
  end
end
