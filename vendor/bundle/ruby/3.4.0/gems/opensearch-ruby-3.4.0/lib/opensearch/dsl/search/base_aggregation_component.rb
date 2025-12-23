# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
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

module OpenSearch
  module DSL
    module Search
      # Module containing common functionality for aggregation DSL classes
      #
      module BaseAggregationComponent
        def self.included(base)
          base.__send__ :include, BaseComponent
          base.__send__ :include, InstanceMethods
        end

        module InstanceMethods
          attr_reader :aggregations

          # Looks up the corresponding class for a method being invoked, and initializes it
          #
          # @raise [NoMethodError] When the corresponding class cannot be found
          #
          def method_missing(name, *args, &block)
            klass = Utils.__camelize(name)
            raise NoMethodError, "undefined method '#{name}' for #{self}" unless Aggregations.const_defined? klass
            @value = Aggregations.const_get(klass).new(*args, &block)
          end

          def respond_to_missing?(method_name, include_private = false)
            Aggregations.const_defined?(Utils.__camelize(method_name)) || super
          end

          # Adds a nested aggregation into the aggregation definition
          #
          # @return [self]
          #
          def aggregation(*args, &block)
            @aggregations ||= AggregationsCollection.new
            @aggregations.update args.first => Aggregation.new(*args, &block)
            self
          end

          # Convert the aggregations to a Hash
          #
          # A default implementation, DSL classes can overload it.
          #
          # @return [Hash]
          #
          def to_hash(_options = {})
            call

            @hash = { name => @args } unless @hash && @hash[name] && !@hash[name].empty?

            @hash[:aggregations] = @aggregations.to_hash if @aggregations
            @hash
          end
        end
      end
    end
  end
end
