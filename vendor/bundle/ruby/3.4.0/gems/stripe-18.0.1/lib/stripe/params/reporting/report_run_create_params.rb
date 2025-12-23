# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Reporting
    class ReportRunCreateParams < ::Stripe::RequestParams
      class Parameters < ::Stripe::RequestParams
        # The set of report columns to include in the report output. If omitted, the Report Type is run with its default column set.
        attr_accessor :columns
        # Connected account ID to filter for in the report run.
        attr_accessor :connected_account
        # Currency of objects to be included in the report run.
        attr_accessor :currency
        # Ending timestamp of data to be included in the report run (exclusive).
        attr_accessor :interval_end
        # Starting timestamp of data to be included in the report run.
        attr_accessor :interval_start
        # Payout ID by which to filter the report run.
        attr_accessor :payout
        # Category of balance transactions to be included in the report run.
        attr_accessor :reporting_category
        # Defaults to `Etc/UTC`. The output timezone for all timestamps in the report. A list of possible time zone values is maintained at the [IANA Time Zone Database](http://www.iana.org/time-zones). Has no effect on `interval_start` or `interval_end`.
        attr_accessor :timezone

        def initialize(
          columns: nil,
          connected_account: nil,
          currency: nil,
          interval_end: nil,
          interval_start: nil,
          payout: nil,
          reporting_category: nil,
          timezone: nil
        )
          @columns = columns
          @connected_account = connected_account
          @currency = currency
          @interval_end = interval_end
          @interval_start = interval_start
          @payout = payout
          @reporting_category = reporting_category
          @timezone = timezone
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Parameters specifying how the report should be run. Different Report Types have different required and optional parameters, listed in the [API Access to Reports](https://stripe.com/docs/reporting/statements/api) documentation.
      attr_accessor :parameters
      # The ID of the [report type](https://stripe.com/docs/reporting/statements/api#report-types) to run, such as `"balance.summary.1"`.
      attr_accessor :report_type

      def initialize(expand: nil, parameters: nil, report_type: nil)
        @expand = expand
        @parameters = parameters
        @report_type = report_type
      end
    end
  end
end
