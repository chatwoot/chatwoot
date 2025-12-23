# frozen_string_literal: true

module Datadog
  module Core
    module Logging
      module Ext
        # The technology from which the log originated.
        # @see https://docs.datadoghq.com/api/latest/logs/#send-logs
        DD_SOURCE = 'ruby'
      end
    end
  end
end
