# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class AlertCreateParams < ::Stripe::RequestParams
      class UsageThreshold < ::Stripe::RequestParams
        class Filter < ::Stripe::RequestParams
          # Limit the scope to this usage alert only to this customer.
          attr_accessor :customer
          # What type of filter is being applied to this usage alert.
          attr_accessor :type

          def initialize(customer: nil, type: nil)
            @customer = customer
            @type = type
          end
        end
        # The filters allows limiting the scope of this usage alert. You can only specify up to one filter at this time.
        attr_accessor :filters
        # Defines at which value the alert will fire.
        attr_accessor :gte
        # The [Billing Meter](/api/billing/meter) ID whose usage is monitored.
        attr_accessor :meter
        # Defines how the alert will behave.
        attr_accessor :recurrence

        def initialize(filters: nil, gte: nil, meter: nil, recurrence: nil)
          @filters = filters
          @gte = gte
          @meter = meter
          @recurrence = recurrence
        end
      end
      # The type of alert to create.
      attr_accessor :alert_type
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The title of the alert.
      attr_accessor :title
      # The configuration of the usage threshold.
      attr_accessor :usage_threshold

      def initialize(alert_type: nil, expand: nil, title: nil, usage_threshold: nil)
        @alert_type = alert_type
        @expand = expand
        @title = title
        @usage_threshold = usage_threshold
      end
    end
  end
end
