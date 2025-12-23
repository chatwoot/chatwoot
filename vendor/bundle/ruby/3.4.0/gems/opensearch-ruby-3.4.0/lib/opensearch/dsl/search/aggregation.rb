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
      # Contains the classes for OpenSearch aggregations
      #
      module Aggregations; end

      class AggregationsCollection < Hash
        # rubocop:disable Naming/MemoizedInstanceVariableName
        def to_hash
          @hash ||= transform_values(&:to_hash)
        end
        # rubocop:enable Naming/MemoizedInstanceVariableName
      end

      # Wraps the `aggregations` part of a search definition
      #
      #
      class Aggregation
        def initialize(*_args, &block)
          @block = block
        end

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

        # Defines an aggregation nested in another one
        #
        def aggregation(*args, &block)
          call
          @value.__send__ :aggregation, *args, &block
        end

        # Returns the aggregations
        #
        def aggregations
          call
          @value.__send__ :aggregations
        end

        # Evaluates the block passed to initializer, ensuring it is called just once
        #
        # @return [self]
        #
        # @api private
        #
        def call
          if @block && !@_block_called
            @block.arity < 1 ? instance_eval(&@block) : @block.call(self)
          end
          @_block_called = true
          self
        end

        # Converts the object to a Hash
        #
        # @return [Hash]
        #
        def to_hash(_options = {})
          call

          if @value
            if @value.respond_to?(:to_hash)
              @value.to_hash
            else
              @value
            end
          else
            {}
          end
        end
      end
    end
  end
end
