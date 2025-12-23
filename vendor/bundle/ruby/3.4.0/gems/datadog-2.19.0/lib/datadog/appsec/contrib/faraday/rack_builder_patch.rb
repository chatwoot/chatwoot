# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Faraday
        # Handles installation of our middleware if the user has *not*
        # already explicitly configured it for this correction.
        #
        # RackBuilder class was introduced in faraday 0.9.0:
        # https://github.com/lostisland/faraday/commit/77d7546d6d626b91086f427c56bc2cdd951353b3
        module RackBuilderPatch
          def adapter(*args)
            use(:datadog_appsec) unless @handlers.any? { |h| h.klass == SSRFDetectionMiddleware }

            super
          end
        end
      end
    end
  end
end
