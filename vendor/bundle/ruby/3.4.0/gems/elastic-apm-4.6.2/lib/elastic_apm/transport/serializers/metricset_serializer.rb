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
    module Serializers
      # @api private
      class MetricsetSerializer < Serializer
        def build(metricset)
          payload = {
            timestamp: metricset.timestamp.to_i,
            samples: build_samples(metricset.samples)
          }

          if metricset.tags?
            payload[:tags] = mixed_object(metricset.tags)
          end

          if metricset.transaction
            payload[:transaction] = metricset.transaction
          end

          if metricset.span
            payload[:span] = metricset.span
          end

          { metricset: payload }
        end

        private

        def build_samples(samples)
          samples.transform_values do |value|
            { value: value }
          end
        end
      end
    end
  end
end
