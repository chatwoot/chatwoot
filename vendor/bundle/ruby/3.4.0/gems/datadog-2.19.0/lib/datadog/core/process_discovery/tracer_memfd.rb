# frozen_string_literal: true

module Datadog
  module Core
    class ProcessDiscovery
      class TracerMemfd
        attr_accessor :logger

        def shutdown!
          ProcessDiscovery._native_close_tracer_memfd(self, logger)
        end
      end
    end
  end
end
