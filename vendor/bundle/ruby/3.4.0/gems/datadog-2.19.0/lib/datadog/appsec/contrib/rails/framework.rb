# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Rails
        # Rails specific framework tie
        module Framework
          def self.setup
            Datadog.configuration.appsec.instrument(:rack)
          end
        end
      end
    end
  end
end
