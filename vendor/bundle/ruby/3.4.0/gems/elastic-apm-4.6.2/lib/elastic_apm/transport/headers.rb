# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  module Transport
    # @api private
    class Headers
      HEADERS = {
        'Content-Type' => 'application/x-ndjson',
        'Transfer-Encoding' => 'chunked'
      }.freeze
      GZIP_HEADERS = HEADERS.merge(
        'Content-Encoding' => 'gzip'
      ).freeze

      def initialize(config, initial: {})
        @config = config
        @hash = build!(initial)
      end

      attr_accessor :hash

      def [](key)
        @hash[key]
      end

      def []=(key, value)
        @hash[key] = value
      end

      def merge(other)
        self.class.new(@config, initial: @hash.merge(other))
      end

      def merge!(other)
        @hash.merge!(other)
        self
      end

      def to_h
        @hash
      end

      def chunked
        merge(
          @config.http_compression? ? GZIP_HEADERS : HEADERS
        )
      end

      private

      def build!(headers)
        headers[:'User-Agent'] = UserAgent.new(@config).to_s

        if (token = @config.secret_token)
          headers[:Authorization] = "Bearer #{token}"
        end

        if (api_key = @config.api_key)
          headers[:Authorization] = "ApiKey #{api_key}"
        end

        headers
      end
    end
  end
end
