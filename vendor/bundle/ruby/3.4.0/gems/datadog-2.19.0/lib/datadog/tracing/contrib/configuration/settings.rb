# frozen_string_literal: true

require_relative '../../../core/configuration/base'
require_relative '../../../core/utils/only_once'

module Datadog
  module Tracing
    module Contrib
      module Configuration
        # Common settings for all integrations
        # @public_api
        class Settings
          include Core::Configuration::Base

          option :analytics_enabled, default: false
          option :analytics_sample_rate, default: 1.0
          option :enabled, default: true
          # TODO: Deprecate per-integration service name when first-class peer service support is added
          # TODO: We don't want to recommend per-integration service naming, but there are no equivalent alternatives today.
          option :service_name do |o|
            o.type :string, nilable: true
          end

          def configure(options = {})
            self.class.options.each_key do |name|
              self[name] = options[name] if options.key?(name)
            end

            yield(self) if block_given?
          end

          def [](name)
            respond_to?(name) ? send(name) : get_option(name)
          end

          def []=(name, value)
            respond_to?("#{name}=") ? send("#{name}=", value) : set_option(name, value)
          end
        end
      end
    end
  end
end
