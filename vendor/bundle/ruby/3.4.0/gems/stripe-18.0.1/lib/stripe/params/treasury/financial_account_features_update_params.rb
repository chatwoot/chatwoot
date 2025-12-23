# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class FinancialAccountFeaturesUpdateParams < ::Stripe::RequestParams
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
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
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
        expand: nil,
        financial_addresses: nil,
        inbound_transfers: nil,
        intra_stripe_flows: nil,
        outbound_payments: nil,
        outbound_transfers: nil
      )
        @card_issuing = card_issuing
        @deposit_insurance = deposit_insurance
        @expand = expand
        @financial_addresses = financial_addresses
        @inbound_transfers = inbound_transfers
        @intra_stripe_flows = intra_stripe_flows
        @outbound_payments = outbound_payments
        @outbound_transfers = outbound_transfers
      end
    end
  end
end
