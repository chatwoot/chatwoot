# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class SamplerCollection
      include Enumerable

      def initialize(event_listener)
        @samplers = []
        @event_listener = event_listener
        @event_listener.subscribe(:before_harvest) { poll_samplers }
      end

      def each(&blk)
        @samplers.each(&blk)
      end

      def clear
        @samplers.clear
      end

      def sampler_class_registered?(sampler_class)
        self.any? { |s| s.class == sampler_class }
      end

      # adds samplers to the sampler collection so that they run every
      # minute. This is dynamically recognized by any class that
      # subclasses NewRelic::Agent::Sampler
      def load_samplers
        Sampler.sampler_classes.each do |subclass|
          add_sampler(subclass)
        end
      end

      def poll_samplers
        @samplers.delete_if do |sampler|
          begin
            sampler.poll
            false # it's okay.  don't delete it.
          rescue => e
            ::NewRelic::Agent.logger.warn("Removing #{sampler} from list", e)
            true # remove the sampler
          end
        end
      end

      def add_sampler(sampler_class)
        supported = sampler_class.supported_on_this_platform?
        enabled = sampler_class.enabled?
        if supported && enabled
          if !sampler_class_registered?(sampler_class)
            sampler = sampler_class.new
            sampler.setup_events(@event_listener) if sampler.respond_to?(:setup_events)
            @samplers << sampler
            ::NewRelic::Agent.logger.debug("Registered #{sampler_class.name} for harvest time sampling.")
          else
            ::NewRelic::Agent.logger.warn("Ignoring addition of #{sampler_class.name} because it is already registered.")
          end
        else
          ::NewRelic::Agent.logger.debug("#{sampler_class.name} not supported on this platform.")
        end
      rescue NewRelic::Agent::Sampler::Unsupported => e
        ::NewRelic::Agent.logger.info("#{sampler_class.name} not available: #{e}")
      rescue => e
        ::NewRelic::Agent.logger.error('Error registering sampler:', e)
      end
    end
  end
end
