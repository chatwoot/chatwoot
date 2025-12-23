# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'net/http'

module NewRelic
  module Agent
    module Utilization
      class Vendor
        class << self
          def vendor_name(vendor_name = nil)
            vendor_name ? @vendor_name = vendor_name.freeze : @vendor_name
          end

          def endpoint(endpoint = nil)
            endpoint ? @endpoint = URI(endpoint) : @endpoint
          end

          def headers(headers = nil)
            headers ? @headers = headers.freeze : processed_headers
          end

          def keys(keys = nil)
            keys ? @keys = keys.freeze : @keys
          end

          def key_transforms(key_transforms = nil)
            key_transforms ? @key_transforms = Array(key_transforms).freeze : @key_transforms
          end

          def processed_headers
            return unless @headers

            @headers.each_with_object({}) do |(key, value), processed_hash|
              # Header lambdas are expected to return string values. If nil comes back, replace it with :error
              # to signify that the call failed.
              processed_hash[key] = value.class.eql?(Proc) ? value.call || :error : value
            end
          end
        end

        attr_reader :metadata

        def initialize
          @metadata = {}
        end

        [:vendor_name, :endpoint, :headers, :keys, :key_transforms].each do |method_name|
          define_method(method_name) { self.class.send(method_name) }
        end

        SUCCESS = '200'.freeze

        def detect
          response = request_metadata
          return false unless response

          begin
            if response.code == SUCCESS
              process_response(prepare_response(response))
            else
              false
            end
          rescue => e
            NewRelic::Agent.logger.error("Error occurred detecting: #{vendor_name}", e)
            record_supportability_metric
            false
          end
        end

        private

        def request_metadata
          processed_headers = headers
          raise if processed_headers.value?(:error)

          response = nil
          Net::HTTP.start(endpoint.host, endpoint.port, open_timeout: 1, read_timeout: 1) do |http|
            req = Net::HTTP::Get.new(endpoint, processed_headers)
            response = http.request(req)
          end
          response
        rescue
          NewRelic::Agent.logger.debug("#{vendor_name} environment not detected")
        end

        def prepare_response(response)
          JSON.parse(response.body)
        end

        def process_response(response)
          keys.each do |key|
            normalized = normalize(response[key])
            if normalized
              @metadata[transform_key(key)] = normalized
            else
              @metadata.clear
              record_supportability_metric
              return false
            end
          end
          true
        end

        def normalize(value)
          return if value.nil?

          value = value.to_s
          value = value.dup if value.frozen?

          value.force_encoding(Encoding::UTF_8)
          value.strip!

          return unless valid_length?(value)
          return unless valid_chars?(value)

          value
        end

        def valid_length?(value)
          if value.bytesize <= 255
            true
          else
            NewRelic::Agent.logger.warn("Found invalid length value while detecting: #{vendor_name}")
            false
          end
        end

        VALID_CHARS = /^[0-9a-zA-Z_ .\/-]$/

        def valid_chars?(value)
          value.each_char do |ch|
            next if VALID_CHARS.match?(ch)

            code_point = ch[0].ord # this works in Ruby 1.8.7 - 2.1.2
            next if code_point >= 0x80

            NewRelic::Agent.logger.warn("Found invalid character while detecting: #{vendor_name}")
            return false # it's in neither set of valid characters
          end
          true
        end

        def transform_key(key)
          return key unless key_transforms

          key_transforms.inject(key) { |memo, transform| memo.send(transform) }
        end

        def record_supportability_metric
          NewRelic::Agent.increment_metric("Supportability/utilization/#{vendor_name}/error")
        end
      end
    end
  end
end
