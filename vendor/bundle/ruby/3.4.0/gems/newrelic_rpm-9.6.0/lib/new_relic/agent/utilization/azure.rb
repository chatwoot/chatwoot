# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Utilization
      class Azure < Vendor
        vendor_name 'azure'
        endpoint 'http://169.254.169.254/metadata/instance/compute?api-version=2017-03-01'
        headers 'Metadata' => 'true'
        keys %w[vmId name vmSize location]
        key_transforms :to_sym
      end
    end
  end
end
