# frozen_string_literal: true

require_relative 'configuration'
require_relative '../core/configuration'

module Datadog
  module AppSec
    # Extends Datadog tracing with AppSec features
    module Extensions
      # Inject AppSec into global objects.
      def self.activate!
        Core::Configuration::Settings.extend(Configuration::Settings)
      end
    end
  end
end
