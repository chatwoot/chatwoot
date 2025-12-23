# frozen_string_literal: true

require 'set'

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Rake
        module Configuration
          # Custom settings for the Rake integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            # @!visibility private
            option :analytics_enabled do |o|
              o.type :bool
              o.env Ext::ENV_ANALYTICS_ENABLED
              o.default false
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :quantize, default: {}, type: :hash
            option :service_name

            # A list of rake tasks, using their string names, to be instrumented.
            # An empty list, or not setting this option means no task is instrumented.
            # Automatically instrumenting all Rake tasks can lead to long-running tasks
            # causing undue memory accumulation, as the trace for such tasks is never flushed.
            option :tasks do |o|
              o.type :array
              o.default []
              o.after_set do |value|
                # DEV: It should be possible to modify the value after it's set. E.g. for normalization.
                options[:tasks].instance_variable_set(:@value, value.map(&:to_s).to_set)
              end
            end
          end
        end
      end
    end
  end
end
