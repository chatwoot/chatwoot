# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      class EventListParams < ::Stripe::RequestParams
        class Created < ::Stripe::RequestParams
          # Filter for events created after the specified timestamp.
          attr_accessor :gt
          # Filter for events created at or after the specified timestamp.
          attr_accessor :gte
          # Filter for events created before the specified timestamp.
          attr_accessor :lt
          # Filter for events created at or before the specified timestamp.
          attr_accessor :lte

          def initialize(gt: nil, gte: nil, lt: nil, lte: nil)
            @gt = gt
            @gte = gte
            @lt = lt
            @lte = lte
          end
        end
        # Set of filters to query events within a range of `created` timestamps.
        attr_accessor :created
        # The page size.
        attr_accessor :limit
        # Primary object ID used to retrieve related events.
        #
        # To avoid conflict with Ruby's ':object_id', this attribute has been renamed. If using a hash parameter map instead, please use the original name ':object_id' with NO trailing underscore as the provided param key.
        attr_accessor :object_id_
        # An array of up to 20 strings containing specific event names.
        attr_accessor :types

        def initialize(created: nil, limit: nil, object_id_: nil, types: nil)
          @created = created
          @limit = limit
          @object_id_ = object_id_
          @types = types
        end
      end
    end
  end
end
