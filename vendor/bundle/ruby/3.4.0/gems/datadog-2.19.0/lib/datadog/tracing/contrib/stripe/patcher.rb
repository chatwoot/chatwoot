# frozen_string_literal: true

require_relative '../patcher'
require_relative 'request'

module Datadog
  module Tracing
    module Contrib
      module Stripe
        # Provides instrumentation for `stripe` through the Stripe instrumentation framework
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Stripe::Instrumentation.subscribe(:request_begin, :datadog_tracing) { |event| Request.start_span(event) }
            ::Stripe::Instrumentation.subscribe(:request_end, :datadog_tracing) { |event| Request.finish_span(event) }
          end
        end
      end
    end
  end
end
