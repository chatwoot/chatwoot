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

require 'elastic_apm/transport/filters/hash_sanitizer'

module ElasticAPM
  module Transport
    module Filters
      # @api private
      class SecretsFilter
        def initialize(config)
          @config = config
          @sanitizer =
            HashSanitizer.new(
              key_patterns: config.custom_key_filters +
                            config.sanitize_field_names
            )
        end

        def call(payload)
          @sanitizer.strip_from!(
            payload.dig(:transaction, :context, :request, :body)
          )
          @sanitizer.strip_from!(
            payload.dig(:transaction, :context, :request, :cookies)
          )
          @sanitizer.strip_from!(
            payload.dig(:transaction, :context, :request, :env)
          )
          @sanitizer.strip_from!(
            payload.dig(:transaction, :context, :request, :headers)
          )
          @sanitizer.strip_from!(
            payload.dig(:transaction, :context, :response, :headers)
          )
          @sanitizer.strip_from!(
            payload.dig(:error, :context, :request, :body)
          )
          @sanitizer.strip_from!(
            payload.dig(:error, :context, :request, :cookies)
          )
          @sanitizer.strip_from!(
            payload.dig(:error, :context, :request, :env)
          )
          @sanitizer.strip_from!(
            payload.dig(:error, :context, :request, :headers)
          )
          @sanitizer.strip_from!(
            payload.dig(:error, :context, :response, :headers)
          )
          payload
        end
      end
    end
  end
end
