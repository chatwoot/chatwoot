# frozen_string_literal: true

require_relative '../analytics'
require_relative 'ext'

module Datadog
  module Tracing
    module Metadata
      # Defines analytics tagging behavior
      module Analytics
        def set_tag(key, value)
          case key
          when Ext::Analytics::TAG_ENABLED
            # If true, set rate to 1.0, otherwise set 0.0.
            value = value == true ? Ext::Analytics::DEFAULT_SAMPLE_RATE : 0.0
            Tracing::Analytics.set_sample_rate(self, value)
          when Ext::Analytics::TAG_SAMPLE_RATE
            Tracing::Analytics.set_sample_rate(self, value)
          else
            super if defined?(super)
          end
        end
      end
    end
  end
end
