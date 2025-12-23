# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/utilization/vendor'

module NewRelic
  module Agent
    module Utilization
      class AWS < Vendor
        IMDS_BASE_URL = 'http://169.254.169.254/latest'.freeze
        IMDS_KEYS = %w[instanceId instanceType availabilityZone].freeze
        IMDS_TOKEN_TTL_SECS = '60'.freeze
        TOKEN_OPEN_TIMEOUT_SECS = 1.freeze
        TOKEN_READ_TIMEOUT_SECS = 1.freeze

        class << self
          def imds_token
            uri = URI.parse("#{IMDS_BASE_URL}/api/token")
            http = Net::HTTP.new(uri.hostname)
            http.open_timeout = TOKEN_OPEN_TIMEOUT_SECS
            http.read_timeout = TOKEN_READ_TIMEOUT_SECS
            response = http.send_request('PUT',
              uri.path,
              '',
              {'X-aws-ec2-metadata-token-ttl-seconds' => IMDS_TOKEN_TTL_SECS})
            unless response.code == Vendor::SUCCESS
              NewRelic::Agent.logger.debug('Failed to obtain an AWS token for use with IMDS - encountered ' \
                                           "#{response.class} with HTTP response code #{response.code} - " \
                                           'assuming non AWS')
              return
            end

            response.body
          rescue Net::OpenTimeout
            NewRelic::Agent.logger.debug('Timed out waiting for AWS IMDS - assuming non AWS')
          end
        end

        vendor_name 'aws'
        endpoint "#{IMDS_BASE_URL}/dynamic/instance-identity/document"
        keys IMDS_KEYS
        headers 'X-aws-ec2-metadata-token' => -> { imds_token }
        key_transforms :to_sym
      end
    end
  end
end
