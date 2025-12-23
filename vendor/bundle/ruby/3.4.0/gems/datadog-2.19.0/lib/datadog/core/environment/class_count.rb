# frozen_string_literal: true

module Datadog
  module Core
    module Environment
      # Retrieves number of classes from runtime
      module ClassCount
        def self.value
          ::ObjectSpace.count_objects[:T_CLASS]
        end

        def self.available?
          return @class_count_available if defined?(@class_count_available)

          @class_count_available =
            ::ObjectSpace.respond_to?(:count_objects) && ::ObjectSpace.count_objects.key?(:T_CLASS)
        end
      end
    end
  end
end
