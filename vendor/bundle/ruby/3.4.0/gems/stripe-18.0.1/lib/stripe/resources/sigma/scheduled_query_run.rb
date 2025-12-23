# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Sigma
    # If you have [scheduled a Sigma query](https://stripe.com/docs/sigma/scheduled-queries), you'll
    # receive a `sigma.scheduled_query_run.created` webhook each time the query
    # runs. The webhook contains a `ScheduledQueryRun` object, which you can use to
    # retrieve the query results.
    class ScheduledQueryRun < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "scheduled_query_run"
      def self.object_name
        "scheduled_query_run"
      end

      class Error < ::Stripe::StripeObject
        # Information about the run failure.
        attr_reader :message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # When the query was run, Sigma contained a snapshot of your Stripe data at this time.
      attr_reader :data_load_time
      # Attribute for field error
      attr_reader :error
      # The file object representing the results of the query.
      attr_reader :file
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Time at which the result expires and is no longer available for download.
      attr_reader :result_available_until
      # SQL for the query.
      attr_reader :sql
      # The query's execution status, which will be `completed` for successful runs, and `canceled`, `failed`, or `timed_out` otherwise.
      attr_reader :status
      # Title of the query.
      attr_reader :title

      # Returns a list of scheduled query runs.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/sigma/scheduled_query_runs",
          params: params,
          opts: opts
        )
      end

      def self.resource_url
        "/v1/sigma/scheduled_query_runs"
      end

      def self.inner_class_types
        @inner_class_types = { error: Error }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
