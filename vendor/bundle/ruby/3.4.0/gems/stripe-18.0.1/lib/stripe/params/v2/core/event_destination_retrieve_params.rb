# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      class EventDestinationRetrieveParams < ::Stripe::RequestParams
        # Additional fields to include in the response.
        attr_accessor :include

        def initialize(include: nil)
          @include = include
        end
      end
    end
  end
end
