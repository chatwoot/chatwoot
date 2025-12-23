# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# == New Relic Initialization
#
# When installed as a gem, you can activate the New Relic agent one of the following ways:
#
# For applications using Bundler, add this to the Gemfile:
#    gem 'newrelic_rpm'
#
# You will also need to install the newrelic.yml configuration file
#
# For applications not using Bundler, and for other installation information, visit:
# https://docs.newrelic.com/docs/agents/ruby-agent/installation/install-new-relic-ruby-agent/
#

require 'new_relic/control'

if defined?(Rails::VERSION)
  module NewRelic
    class Railtie < Rails::Railtie
      if ENV['NEW_RELIC_DEFER_RAILS_INITIALIZATION']
        initializer 'newrelic_rpm.include_method_tracers', before: :load_config_initializers do |app|
          Module.send(:include, NewRelic::Agent::MethodTracer::ClassMethods)
          Module.send(:include, NewRelic::Agent::MethodTracer)
        end

        initializer 'newrelic_rpm.start_plugin', after: :load_config_initializers do |app|
          NewRelic::Control.instance.init_plugin(config: app.config)
        end
      else
        initializer 'newrelic_rpm.start_plugin', before: :load_config_initializers do |app|
          NewRelic::Control.instance.init_plugin(config: app.config)
        end
      end
    end
  end
else
  NewRelic::Control.instance.init_plugin
end
