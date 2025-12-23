# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    # A test clock enables deterministic control over objects in testmode. With a test clock, you can create
    # objects at a frozen time in the past or future, and advance to a specific future time to observe webhooks and state changes. After the clock advances,
    # you can either validate the current state of your scenario (and test your assumptions), change the current state of your scenario (and test more complex scenarios), or keep advancing forward in time.
    class TestClock < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List

      OBJECT_NAME = "test_helpers.test_clock"
      def self.object_name
        "test_helpers.test_clock"
      end

      class StatusDetails < ::Stripe::StripeObject
        class Advancing < ::Stripe::StripeObject
          # The `frozen_time` that the Test Clock is advancing towards.
          attr_reader :target_frozen_time

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field advancing
        attr_reader :advancing

        def self.inner_class_types
          @inner_class_types = { advancing: Advancing }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Time at which this clock is scheduled to auto delete.
      attr_reader :deletes_after
      # Time at which all objects belonging to this clock are frozen.
      attr_reader :frozen_time
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The custom name supplied at creation.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The status of the Test Clock.
      attr_reader :status
      # Attribute for field status_details
      attr_reader :status_details
      # Always true for a deleted object
      attr_reader :deleted

      # Starts advancing a test clock to a specified time in the future. Advancement is done when status changes to Ready.
      def advance(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/test_clocks/%<test_clock>s/advance", { test_clock: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Starts advancing a test clock to a specified time in the future. Advancement is done when status changes to Ready.
      def self.advance(test_clock, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/test_clocks/%<test_clock>s/advance", { test_clock: CGI.escape(test_clock) }),
          params: params,
          opts: opts
        )
      end

      # Creates a new test clock that can be attached to new customers and quotes.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/test_helpers/test_clocks",
          params: params,
          opts: opts
        )
      end

      # Deletes a test clock.
      def self.delete(test_clock, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/test_helpers/test_clocks/%<test_clock>s", { test_clock: CGI.escape(test_clock) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a test clock.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/test_helpers/test_clocks/%<test_clock>s", { test_clock: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of your test clocks.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/test_helpers/test_clocks",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { status_details: StatusDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
