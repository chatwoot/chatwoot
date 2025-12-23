# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

#
# A Sampler is used to capture meaningful metrics in a background thread
# periodically.  They will be invoked about once a minute, each time the agent
# sends data to New Relic's servers.
#
# Samplers can be added to New Relic by subclassing NewRelic::Agent::Sampler.
# Instances are created when the agent is enabled and installed.  Subclasses
# are registered for instantiation automatically.
module NewRelic
  module Agent
    class Sampler
      # Exception denotes a sampler is not available and it will not be registered.
      class Unsupported < StandardError; end

      attr_reader :id
      @sampler_classes = []

      class << self
        attr_reader :shorthand_name
      end

      def self.named(new_name)
        @shorthand_name = new_name
      end

      def self.inherited(subclass)
        @sampler_classes << subclass
      end

      # Override with check.  Called before instantiating.
      def self.supported_on_this_platform?
        true
      end

      def self.enabled?
        if shorthand_name
          config_key = "disable_#{shorthand_name}_sampler"
          !(Agent.config[config_key])
        else
          true
        end
      end

      def self.sampler_classes
        @sampler_classes
      end

      # The ID passed in here is unused by our code, but is preserved in case
      # we have clients who are defining their own subclasses of this class, and
      # expecting to be able to call super with an ID.
      def initialize(id = nil)
        @id = id || self.class.shorthand_name
      end

      def poll
        raise 'Implement in the subclass'
      end
    end
  end
end
