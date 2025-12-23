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

require 'elastic_apm/transport/filters/secrets_filter'

module ElasticAPM
  module Transport
    # @api private
    module Filters
      SKIP = :skip

      def self.new(config)
        Container.new(config)
      end

      # @api private
      class Container
        def initialize(config)
          @filters = { secrets: SecretsFilter.new(config) }
        end

        def add(key, filter)
          @filters = @filters.merge(key => filter)
        end

        def remove(key)
          @filters.delete(key)
        end

        def apply!(payload)
          @filters.reduce(payload) do |result, (_key, filter)|
            result = filter.call(result)
            break SKIP if result.nil?
            result
          end
        end

        def length
          @filters.length
        end
      end
    end
  end
end
