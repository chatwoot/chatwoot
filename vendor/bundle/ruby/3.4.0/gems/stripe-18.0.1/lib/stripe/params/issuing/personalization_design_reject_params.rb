# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class PersonalizationDesignRejectParams < ::Stripe::RequestParams
      class RejectionReasons < ::Stripe::RequestParams
        # The reason(s) the card logo was rejected.
        attr_accessor :card_logo
        # The reason(s) the carrier text was rejected.
        attr_accessor :carrier_text

        def initialize(card_logo: nil, carrier_text: nil)
          @card_logo = card_logo
          @carrier_text = carrier_text
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The reason(s) the personalization design was rejected.
      attr_accessor :rejection_reasons

      def initialize(expand: nil, rejection_reasons: nil)
        @expand = expand
        @rejection_reasons = rejection_reasons
      end
    end
  end
end
