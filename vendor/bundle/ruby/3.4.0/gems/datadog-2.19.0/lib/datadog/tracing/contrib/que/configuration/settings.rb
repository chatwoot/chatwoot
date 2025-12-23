# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Que
        module Configuration
          # Default settings for the Que integration
          class Settings < Contrib::Configuration::Settings
            option :service_name
            option :distributed_tracing, default: true, type: :bool

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

            option :tag_args do |o|
              o.type :bool
              o.env Ext::ENV_TAG_ARGS_ENABLED
              o.default false
            end

            option :tag_data do |o|
              o.type :bool
              o.env Ext::ENV_TAG_DATA_ENABLED
              o.default false
            end

            option :on_error do |o|
              o.type :proc, nilable: true
            end
          end
        end
      end
    end
  end
end
