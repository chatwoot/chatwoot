# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Excon
        # AppSec patcher module for Excon
        module Patcher
          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            require_relative 'ssrf_detection_middleware'

            ::Excon.defaults[:middlewares].insert(0, SSRFDetectionMiddleware)
          end
        end
      end
    end
  end
end
