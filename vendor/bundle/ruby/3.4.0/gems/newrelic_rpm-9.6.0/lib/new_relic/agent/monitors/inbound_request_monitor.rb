# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This class serves as the base for objects wanting to monitor and respond to
# incoming web requests. Examples include cross application tracing and
# synthetics.
#
# Subclasses are expected to define on_finished_configuring(events) which will
# be called when the agent is fully configured. That method is expected to
# subscribe to the necessary request events, such as before_call and after_call
# for the monitor to do its work.

require 'json'

module NewRelic
  module Agent
    class InboundRequestMonitor
      attr_reader :obfuscator

      def initialize(events)
        events.subscribe(:initial_configuration_complete) do
          # This requires :encoding_key, so must wait until :initial_configuration_complete
          setup_obfuscator
          on_finished_configuring(events)
        end
      end

      def setup_obfuscator
        @obfuscator = Obfuscator.new(Agent.config[:encoding_key])
      end

      def deserialize_header(encoded_header, key)
        decoded_header = obfuscator.deobfuscate(encoded_header)
        ::JSON.load(decoded_header)
      rescue => err
        # If we have a failure of any type here, just return nil and carry on
        NewRelic::Agent.logger.debug("Failure deserializing encoded header '#{key}' in #{self.class}, #{err.class}, #{err.message}")
        nil
      end
    end
  end
end
