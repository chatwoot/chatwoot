# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class OutboundPaymentReturnOutboundPaymentParams < ::Stripe::RequestParams
      class ReturnedDetails < ::Stripe::RequestParams
        # The return code to be set on the OutboundPayment object.
        attr_accessor :code

        def initialize(code: nil)
          @code = code
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Optional hash to set the return code.
      attr_accessor :returned_details

      def initialize(expand: nil, returned_details: nil)
        @expand = expand
        @returned_details = returned_details
      end
    end
  end
end
