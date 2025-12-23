# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Reporting
    # The Report Run object represents an instance of a report type generated with
    # specific run parameters. Once the object is created, Stripe begins processing the report.
    # When the report has finished running, it will give you a reference to a file
    # where you can retrieve your results. For an overview, see
    # [API Access to Reports](https://stripe.com/docs/reporting/statements/api).
    #
    # Note that certain report types can only be run based on your live-mode data (not test-mode
    # data), and will error when queried without a [live-mode API key](https://stripe.com/docs/keys#test-live-modes).
    class ReportRun < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "reporting.report_run"
      def self.object_name
        "reporting.report_run"
      end

      class Parameters < ::Stripe::StripeObject
        # The set of output columns requested for inclusion in the report run.
        attr_reader :columns
        # Connected account ID by which to filter the report run.
        attr_reader :connected_account
        # Currency of objects to be included in the report run.
        attr_reader :currency
        # Ending timestamp of data to be included in the report run. Can be any UTC timestamp between 1 second after the user specified `interval_start` and 1 second before this report's last `data_available_end` value.
        attr_reader :interval_end
        # Starting timestamp of data to be included in the report run. Can be any UTC timestamp between 1 second after this report's `data_available_start` and 1 second before the user specified `interval_end` value.
        attr_reader :interval_start
        # Payout ID by which to filter the report run.
        attr_reader :payout
        # Category of balance transactions to be included in the report run.
        attr_reader :reporting_category
        # Defaults to `Etc/UTC`. The output timezone for all timestamps in the report. A list of possible time zone values is maintained at the [IANA Time Zone Database](http://www.iana.org/time-zones). Has no effect on `interval_start` or `interval_end`.
        attr_reader :timezone

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # If something should go wrong during the run, a message about the failure (populated when
      #  `status=failed`).
      attr_reader :error
      # Unique identifier for the object.
      attr_reader :id
      # `true` if the report is run on live mode data and `false` if it is run on test mode data.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Attribute for field parameters
      attr_reader :parameters
      # The ID of the [report type](https://stripe.com/docs/reports/report-types) to run, such as `"balance.summary.1"`.
      attr_reader :report_type
      # The file object representing the result of the report run (populated when
      #  `status=succeeded`).
      attr_reader :result
      # Status of this report run. This will be `pending` when the run is initially created.
      #  When the run finishes, this will be set to `succeeded` and the `result` field will be populated.
      #  Rarely, we may encounter an error, at which point this will be set to `failed` and the `error` field will be populated.
      attr_reader :status
      # Timestamp at which this run successfully finished (populated when
      #  `status=succeeded`). Measured in seconds since the Unix epoch.
      attr_reader :succeeded_at

      # Creates a new object and begin running the report. (Certain report types require a [live-mode API key](https://stripe.com/docs/keys#test-live-modes).)
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/reporting/report_runs",
          params: params,
          opts: opts
        )
      end

      # Returns a list of Report Runs, with the most recent appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/reporting/report_runs",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { parameters: Parameters }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
