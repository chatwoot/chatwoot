# frozen_string_literal: true

module Datadog
  module Core
    module Transport
      # Defines request for transport operations
      class Request
        attr_reader \
          :parcel

        def initialize(parcel = nil)
          @parcel = parcel
        end
      end
    end
  end
end
