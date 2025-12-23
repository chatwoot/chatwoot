# frozen_string_literal: true

require_relative 'configuration'
require_relative '../core/configuration'

module Datadog
  module ErrorTracking
    # Extends Datadog tracing with ErrorTracking features
    module Extensions
      # Inject Error Tracking into global objects.
      def self.activate!
        Core::Configuration::Settings.extend(Configuration::Settings)
      end
    end
  end
end
