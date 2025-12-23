# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Stripe
        # Stripe integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_STRIPE_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_STRIPE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_STRIPE_ANALYTICS_SAMPLE_RATE'
          SPAN_REQUEST = 'stripe.request'
          SPAN_TYPE_REQUEST = 'custom'
          TAG_COMPONENT = 'stripe'
          TAG_OPERATION_REQUEST = 'request'
          TAG_REQUEST_HTTP_STATUS = 'stripe.request.http_status'
          TAG_REQUEST_ID = 'stripe.request.id'
          TAG_REQUEST_METHOD = 'stripe.request.method'
          TAG_REQUEST_NUM_RETRIES = 'stripe.request.num_retries'
          TAG_REQUEST_PATH = 'stripe.request.path'
        end
      end
    end
  end
end
