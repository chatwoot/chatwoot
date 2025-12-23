# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # Encodes whether a FinancialAccount has access to a particular Feature, with a `status` enum and associated `status_details`.
    # Stripe or the platform can control Features via the requested field.
    class FinancialAccountFeatures < APIResource
      OBJECT_NAME = "treasury.financial_account_features"
      def self.object_name
        "treasury.financial_account_features"
      end

      class CardIssuing < ::Stripe::StripeObject
        class StatusDetail < ::Stripe::StripeObject
          # Represents the reason why the status is `pending` or `restricted`.
          attr_reader :code
          # Represents what the user should do, if anything, to activate the Feature.
          attr_reader :resolution
          # The `platform_restrictions` that are restricting this Feature.
          attr_reader :restriction

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the FinancialAccount should have the Feature.
        attr_reader :requested
        # Whether the Feature is operational.
        attr_reader :status
        # Additional details; includes at least one entry when the status is not `active`.
        attr_reader :status_details

        def self.inner_class_types
          @inner_class_types = { status_details: StatusDetail }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class DepositInsurance < ::Stripe::StripeObject
        class StatusDetail < ::Stripe::StripeObject
          # Represents the reason why the status is `pending` or `restricted`.
          attr_reader :code
          # Represents what the user should do, if anything, to activate the Feature.
          attr_reader :resolution
          # The `platform_restrictions` that are restricting this Feature.
          attr_reader :restriction

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the FinancialAccount should have the Feature.
        attr_reader :requested
        # Whether the Feature is operational.
        attr_reader :status
        # Additional details; includes at least one entry when the status is not `active`.
        attr_reader :status_details

        def self.inner_class_types
          @inner_class_types = { status_details: StatusDetail }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FinancialAddresses < ::Stripe::StripeObject
        class Aba < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Toggle settings for enabling/disabling the ABA address feature
        attr_reader :aba

        def self.inner_class_types
          @inner_class_types = { aba: Aba }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class InboundTransfers < ::Stripe::StripeObject
        class Ach < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Toggle settings for enabling/disabling an inbound ACH specific feature
        attr_reader :ach

        def self.inner_class_types
          @inner_class_types = { ach: Ach }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class IntraStripeFlows < ::Stripe::StripeObject
        class StatusDetail < ::Stripe::StripeObject
          # Represents the reason why the status is `pending` or `restricted`.
          attr_reader :code
          # Represents what the user should do, if anything, to activate the Feature.
          attr_reader :resolution
          # The `platform_restrictions` that are restricting this Feature.
          attr_reader :restriction

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the FinancialAccount should have the Feature.
        attr_reader :requested
        # Whether the Feature is operational.
        attr_reader :status
        # Additional details; includes at least one entry when the status is not `active`.
        attr_reader :status_details

        def self.inner_class_types
          @inner_class_types = { status_details: StatusDetail }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class OutboundPayments < ::Stripe::StripeObject
        class Ach < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsDomesticWire < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Toggle settings for enabling/disabling an outbound ACH specific feature
        attr_reader :ach
        # Toggle settings for enabling/disabling a feature
        attr_reader :us_domestic_wire

        def self.inner_class_types
          @inner_class_types = { ach: Ach, us_domestic_wire: UsDomesticWire }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class OutboundTransfers < ::Stripe::StripeObject
        class Ach < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsDomesticWire < ::Stripe::StripeObject
          class StatusDetail < ::Stripe::StripeObject
            # Represents the reason why the status is `pending` or `restricted`.
            attr_reader :code
            # Represents what the user should do, if anything, to activate the Feature.
            attr_reader :resolution
            # The `platform_restrictions` that are restricting this Feature.
            attr_reader :restriction

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Whether the FinancialAccount should have the Feature.
          attr_reader :requested
          # Whether the Feature is operational.
          attr_reader :status
          # Additional details; includes at least one entry when the status is not `active`.
          attr_reader :status_details

          def self.inner_class_types
            @inner_class_types = { status_details: StatusDetail }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Toggle settings for enabling/disabling an outbound ACH specific feature
        attr_reader :ach
        # Toggle settings for enabling/disabling a feature
        attr_reader :us_domestic_wire

        def self.inner_class_types
          @inner_class_types = { ach: Ach, us_domestic_wire: UsDomesticWire }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Toggle settings for enabling/disabling a feature
      attr_reader :card_issuing
      # Toggle settings for enabling/disabling a feature
      attr_reader :deposit_insurance
      # Settings related to Financial Addresses features on a Financial Account
      attr_reader :financial_addresses
      # InboundTransfers contains inbound transfers features for a FinancialAccount.
      attr_reader :inbound_transfers
      # Toggle settings for enabling/disabling a feature
      attr_reader :intra_stripe_flows
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Settings related to Outbound Payments features on a Financial Account
      attr_reader :outbound_payments
      # OutboundTransfers contains outbound transfers features for a FinancialAccount.
      attr_reader :outbound_transfers

      def self.inner_class_types
        @inner_class_types = {
          card_issuing: CardIssuing,
          deposit_insurance: DepositInsurance,
          financial_addresses: FinancialAddresses,
          inbound_transfers: InboundTransfers,
          intra_stripe_flows: IntraStripeFlows,
          outbound_payments: OutboundPayments,
          outbound_transfers: OutboundTransfers,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
