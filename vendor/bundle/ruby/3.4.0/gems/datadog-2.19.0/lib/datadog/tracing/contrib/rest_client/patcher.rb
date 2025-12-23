# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module RestClient
        # Patcher enables patching of 'rest_client' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'request_patch'

            ::RestClient::Request.include(RequestPatch)
          end
        end
      end
    end
  end
end
