# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/utilization/vendor'

module NewRelic
  module Agent
    module Utilization
      class GCP < Vendor
        vendor_name 'gcp'
        endpoint 'http://metadata.google.internal/computeMetadata/v1/instance/?recursive=true'
        headers 'Metadata-Flavor' => 'Google'
        keys %w[id machineType name zone]
        key_transforms :to_sym

        MACH_TYPE = 'machineType'.freeze
        ZONE = 'zone'.freeze

        def prepare_response(response)
          body = JSON.parse(response.body)
          body[MACH_TYPE] = trim_leading(body[MACH_TYPE])
          body[ZONE] = trim_leading(body[ZONE])
          body
        end

        def trim_leading(value)
          value.split(NewRelic::SLASH).last
        end
      end
    end
  end
end
