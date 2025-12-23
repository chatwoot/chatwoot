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
  # @api private
  module Metrics
    NOOP = NoopMetric.new

    # @api private
    class Set
      include Logging

      DISTINCT_LABEL_LIMIT = 1000

      def initialize(config)
        @config = config
        @metrics = {}
        @disabled = false
        @lock = Mutex.new
      end

      attr_reader :metrics

      def disable!
        @disabled = true
      end

      def disabled?
        @disabled
      end

      def counter(key, tags: nil, **args)
        metric(Counter, key, tags: tags, **args)
      end

      def gauge(key, tags: nil, **args)
        metric(Gauge, key, tags: tags, **args)
      end

      def timer(key, tags: nil, **args)
        metric(Timer, key, tags: tags, **args)
      end

      def metric(kls, key, tags: nil, **args)
        if @config.disable_metrics.any? { |p| p.match? key }
          return NOOP
        end

        key = key_with_tags(key, tags)
        return metrics[key] if metrics[key]

        @lock.synchronize do
          return metrics[key] if metrics[key]

          metrics[key] =
            if metrics.length < DISTINCT_LABEL_LIMIT
              kls.new(key, tags: tags, **args)
            else
              unless @label_limit_logged
                warn(
                  'The limit of %d metricsets has been reached, no new ' \
                   'metricsets will be created.', DISTINCT_LABEL_LIMIT
                )
                @label_limit_logged = true
              end

              NOOP
            end
        end
      end

      def collect
        return if disabled?

        @lock.synchronize do
          metrics.each_with_object({}) do |(key, metric), sets|
            next unless (value = metric.collect)

            # metrics have a key of name and flat array of key-value pairs
            #   eg [name, key, value, key, value]
            # they can be sent in the same metricset but not if they have
            # differing tags. So, we split the resulting sets by tags first.
            name, *tags = key
            sets[tags] ||= Metricset.new

            # then we set the `samples` value for the metricset
            set = sets[tags]
            set.samples[name] = value

            # and finally we copy the tags from the Metric to the Metricset
            set.merge_tags! metric.tags
          end.values
        end
      end

      private

      def key_with_tags(key, tags)
        return key unless tags

        tuple = tags.keys.zip(tags.values)
        tuple.flatten!
        tuple.unshift(key)
      end
    end
  end
end
