# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/configuration/manager'
require 'new_relic/agent/configuration/dotted_hash'
require 'new_relic/agent/configuration/manual_source'

# The agent's configuration is accessed through a configuration object exposed
# by ::NewRelic::Agent.config.  It provides a hash like interface to the
# agent's settings.
#
# For example:
# ::NewRelic::Agent.config[:'transaction_tracer.enabled']
# determines whether transaction tracing is enabled.  String and symbol keys
# are treated indifferently and nested keys are collapsed and concatenated with
# a dot (i.e. {:a => {:b => 'c'} becomes { 'a.b' => 'c'}).
#
# The agent reads configuration from a variety of sources. These sources are
# modeled as a set of layers.  The top layer has the highest priority.  If the
# top layer does not contain the requested setting the config object will search
# through the subsequent layers returning the first value it finds.
#
# Configuration layers include EnvironmentSource (which reads settings from
# ENV), ServerSource (which reads Server Side Config from New Relic's servers),
# YamlSource (which reads from newrelic.yml),  ManualSource (which reads
# arguments passed to NewRelic::Agent.manual_start or potentially other
# methods), and Defaults (which contains default settings).
#
module NewRelic
  module Agent
    module Configuration
    end
  end
end
