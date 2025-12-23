# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Treasury
      class OutboundTransferReturnOutboundTransferParams < ::Stripe::RequestParams
        class ReturnedDetails < ::Stripe::RequestParams
          # Reason for the return.
          attr_accessor :code

          def initialize(code: nil)
            @code = code
          end
        end
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # Details about a returned OutboundTransfer.
        attr_accessor :returned_details

        def initialize(expand: nil, returned_details: nil)
          @expand = expand
          @returned_details = returned_details
        end
      end
    end
  end
end
