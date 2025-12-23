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
    module Serializers
      # @api private
      class UnrecognizedResource < InternalError; end

      # @api private
      class Serializer
        def initialize(config)
          @config = config
        end

        attr_reader :config

        private

        def ms(micros)
          micros.to_f / 1_000
        end

        def keyword_field(value)
          Util.truncate(value)
        end

        def keyword_object(hash)
          return unless hash

          hash.each do |k, v|
            hash[k] =
              case v
              when Hash then keyword_object(v)
              else keyword_field(v)
              end
          end
        end

        def mixed_object(hash)
          return unless hash

          hash.each do |k, v|
            hash[k] = v.is_a?(String) ? keyword_field(v) : v
          end
        end
      end

      # @api private
      class Container
        def initialize(config)
          @transaction = Serializers::TransactionSerializer.new(config)
          @span = Serializers::SpanSerializer.new(config)
          @error = Serializers::ErrorSerializer.new(config)
          @metadata = Serializers::MetadataSerializer.new(config)
          @metricset = Serializers::MetricsetSerializer.new(config)
        end

        attr_reader :transaction, :span, :error, :metadata, :metricset

        def serialize(resource)
          case resource
          when Transaction
            transaction.build(resource)
          when Span
            span.build(resource)
          when Error
            error.build(resource)
          when Metricset
            metricset.build(resource)
          when Metadata
            metadata.build(resource)
          else
            raise UnrecognizedResource, resource.inspect
          end
        end
      end

      def self.new(config)
        Container.new(config)
      end
    end
  end
end

require 'elastic_apm/transport/serializers/context_serializer'
require 'elastic_apm/transport/serializers/transaction_serializer'
require 'elastic_apm/transport/serializers/span_serializer'
require 'elastic_apm/transport/serializers/error_serializer'
require 'elastic_apm/transport/serializers/metricset_serializer'
require 'elastic_apm/transport/serializers/metadata_serializer'
