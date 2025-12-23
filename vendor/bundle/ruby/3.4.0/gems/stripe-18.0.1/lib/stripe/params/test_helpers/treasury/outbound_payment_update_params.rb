# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Treasury
      class OutboundPaymentUpdateParams < ::Stripe::RequestParams
        class TrackingDetails < ::Stripe::RequestParams
          class Ach < ::Stripe::RequestParams
            # ACH trace ID for funds sent over the `ach` network.
            attr_accessor :trace_id

            def initialize(trace_id: nil)
              @trace_id = trace_id
            end
          end

          class UsDomesticWire < ::Stripe::RequestParams
            # CHIPS System Sequence Number (SSN) for funds sent over the `us_domestic_wire` network.
            attr_accessor :chips
            # IMAD for funds sent over the `us_domestic_wire` network.
            attr_accessor :imad
            # OMAD for funds sent over the `us_domestic_wire` network.
            attr_accessor :omad

            def initialize(chips: nil, imad: nil, omad: nil)
              @chips = chips
              @imad = imad
              @omad = omad
            end
          end
          # ACH network tracking details.
          attr_accessor :ach
          # The US bank account network used to send funds.
          attr_accessor :type
          # US domestic wire network tracking details.
          attr_accessor :us_domestic_wire

          def initialize(ach: nil, type: nil, us_domestic_wire: nil)
            @ach = ach
            @type = type
            @us_domestic_wire = us_domestic_wire
          end
        end
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # Details about network-specific tracking information.
        attr_accessor :tracking_details

        def initialize(expand: nil, tracking_details: nil)
          @expand = expand
          @tracking_details = tracking_details
        end
      end
    end
  end
end
