# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Treasury
      class InboundTransferFailParams < ::Stripe::RequestParams
        class FailureDetails < ::Stripe::RequestParams
          # Reason for the failure.
          attr_accessor :code

          def initialize(code: nil)
            @code = code
          end
        end
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # Details about a failed InboundTransfer.
        attr_accessor :failure_details

        def initialize(expand: nil, failure_details: nil)
          @expand = expand
          @failure_details = failure_details
        end
      end
    end
  end
end
