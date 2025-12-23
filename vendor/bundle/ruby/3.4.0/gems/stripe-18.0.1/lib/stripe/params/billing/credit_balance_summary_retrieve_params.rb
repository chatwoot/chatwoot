# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditBalanceSummaryRetrieveParams < ::Stripe::RequestParams
      class Filter < ::Stripe::RequestParams
        class ApplicabilityScope < ::Stripe::RequestParams
          class Price < ::Stripe::RequestParams
            # The price ID this credit grant should apply to.
            attr_accessor :id

            def initialize(id: nil)
              @id = id
            end
          end
          # The price type that credit grants can apply to. We currently only support the `metered` price type. Cannot be used in combination with `prices`.
          attr_accessor :price_type
          # A list of prices that the credit grant can apply to. We currently only support the `metered` prices. Cannot be used in combination with `price_type`.
          attr_accessor :prices

          def initialize(price_type: nil, prices: nil)
            @price_type = price_type
            @prices = prices
          end
        end
        # The billing credit applicability scope for which to fetch credit balance summary.
        attr_accessor :applicability_scope
        # The credit grant for which to fetch credit balance summary.
        attr_accessor :credit_grant
        # Specify the type of this filter.
        attr_accessor :type

        def initialize(applicability_scope: nil, credit_grant: nil, type: nil)
          @applicability_scope = applicability_scope
          @credit_grant = credit_grant
          @type = type
        end
      end
      # The customer for which to fetch credit balance summary.
      attr_accessor :customer
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The filter criteria for the credit balance summary.
      attr_accessor :filter

      def initialize(customer: nil, expand: nil, filter: nil)
        @customer = customer
        @expand = expand
        @filter = filter
      end
    end
  end
end
