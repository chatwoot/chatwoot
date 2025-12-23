# frozen_string_literal: true

require_relative '../utils/forking'
require_relative '../utils/sequence'

module Datadog
  module Core
    module Telemetry
      # Collection of telemetry events.
      #
      # @api private
      module Event
        extend Core::Utils::Forking

        # returns sequence that increments every time the configuration changes
        def self.configuration_sequence
          after_fork! { @sequence = Datadog::Core::Utils::Sequence.new(1) }
          @sequence ||= Datadog::Core::Utils::Sequence.new(1)
        end
      end
    end
  end
end

require_relative 'event/base'
require_relative 'event/app_client_configuration_change'
require_relative 'event/app_closing'
require_relative 'event/app_dependencies_loaded'
require_relative 'event/app_heartbeat'
require_relative 'event/app_integrations_change'
require_relative 'event/app_started'
require_relative 'event/synth_app_client_configuration_change'
require_relative 'event/generate_metrics'
require_relative 'event/distributions'
require_relative 'event/log'
require_relative 'event/message_batch'
