# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      class EventDestinationListParams < ::Stripe::RequestParams
        # Additional fields to include in the response. Currently supports `webhook_endpoint.url`.
        attr_accessor :include
        # The page size.
        attr_accessor :limit

        def initialize(include: nil, limit: nil)
          @include = include
          @limit = limit
        end
      end
    end
  end
end
