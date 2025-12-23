# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/sampler'

module NewRelic
  module Agent
    module Samplers
      class ObjectSampler < NewRelic::Agent::Sampler
        named :object

        def self.supported_on_this_platform?
          NewRelic::LanguageSupport.object_space_usable? && ObjectSpace.respond_to?(:live_objects)
        end

        def poll
          live_objects = ObjectSpace.live_objects
          NewRelic::Agent.record_metric('GC/objects', live_objects)
        end
      end
    end
  end
end
