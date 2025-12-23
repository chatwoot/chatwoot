# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Contains methods helpful for tracing/annotating HTTP request libraries
      module HttpAnnotationHelper
        def service_name(hostname, configuration_options, pin = nil)
          return hostname if configuration_options[:split_by_domain]
          return pin[:service_name] if pin && pin[:service_name]

          configuration_options[:service_name]
        end
      end
    end
  end
end
