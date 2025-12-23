# frozen_string_literal: true

module Datadog
  module Core
    module Transport
      module HTTP
        module Adapters
          # List of available adapters
          class Registry
            def initialize
              @adapters = {}
            end

            def get(name)
              @adapters[name]
            end

            def set(klass, name = nil)
              name ||= klass.to_s
              return if name.nil?

              @adapters[name] = klass
            end
          end
        end
      end
    end
  end
end
