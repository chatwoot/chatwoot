# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module RestClient
        # Patcher for RestClient gem
        module Patcher
          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            require_relative 'request_ssrf_detection_patch'

            ::RestClient::Request.prepend(RequestSSRFDetectionPatch)
          end
        end
      end
    end
  end
end
