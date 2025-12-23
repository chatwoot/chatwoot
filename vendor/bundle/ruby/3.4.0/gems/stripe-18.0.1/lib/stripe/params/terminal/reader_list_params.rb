# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderListParams < ::Stripe::RequestParams
      # Filters readers by device type
      attr_accessor :device_type
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # A location ID to filter the response list to only readers at the specific location
      attr_accessor :location
      # Filters readers by serial number
      attr_accessor :serial_number
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # A status filter to filter readers to only offline or online readers
      attr_accessor :status

      def initialize(
        device_type: nil,
        ending_before: nil,
        expand: nil,
        limit: nil,
        location: nil,
        serial_number: nil,
        starting_after: nil,
        status: nil
      )
        @device_type = device_type
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @location = location
        @serial_number = serial_number
        @starting_after = starting_after
        @status = status
      end
    end
  end
end
