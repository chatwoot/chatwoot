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
  module Normalizers
    module Grape
      # @api private
      class EndpointRun < Normalizer
        register 'endpoint_run.grape'

        TYPE = 'app'
        SUBTYPE = 'resource'

        FRAMEWORK_NAME = 'Grape'

        def normalize(transaction, _name, payload)
          transaction.name = endpoint(payload[:env])

          if transaction_from_host_app?(transaction)
            transaction.context.set_service(
              framework_name: FRAMEWORK_NAME,
              framework_version: ::Grape::VERSION
            )
          end

          [transaction.name, TYPE, SUBTYPE, nil, nil]
        end

        def backtrace(payload)
          source_location = payload[:endpoint].source.source_location
          ["#{source_location[0]}:#{source_location[1]}"]
        end

        private

        def transaction_from_host_app?(transaction)
          transaction.framework_name != FRAMEWORK_NAME
        end

        def endpoint(env)
          route_name =
            env['api.endpoint']&.routes&.first&.pattern&.origin ||
            env['REQUEST_PATH']
          [env['REQUEST_METHOD'], route_name].join(' ')
        end
      end
    end
  end
end
