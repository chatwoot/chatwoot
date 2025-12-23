# frozen_string_literal: true

require_relative "../core/configuration"
require_relative "configuration"

module Datadog
  module DI
    # Extends Datadog tracing with DI features
    module Extensions
      # Inject DI into global objects.
      def self.activate!
        Core::Configuration::Settings.extend(Configuration::Settings)
      end
    end
  end
end
