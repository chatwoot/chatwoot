# frozen_string_literal: true

require_relative '../../configuration/settings'

module Datadog
  module Tracing
    module Contrib
      module Sneakers
        module Configuration
          # Default settings for the Shoryuken integration
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

            option :service_name

            option :on_error do |o|
              o.type :proc, nilable: true
            end

            option :tag_body, default: false, type: :bool
          end
        end
      end
    end
  end
end
