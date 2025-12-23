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
      # Contains the classes for OpenSearch queries
      #
      module Queries; end

      # Wraps the `query` part of a search definition
      #
      #
      class Query
        def initialize(*_args, &block)
          @block = block
        end

        # Looks up the corresponding class for a method being invoked, and initializes it
        #
        # @raise [NoMethodError] When the corresponding class cannot be found
        #
        def method_missing(name, *args, &block)
          klass = Utils.__camelize(name)
          raise NoMethodError, "undefined method '#{name}' for #{self}" unless Queries.const_defined? klass
          @value = Queries.const_get(klass).new(*args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          Queries.const_defined?(Utils.__camelize(method_name)) || super
        end

        # Evaluates any block passed to the query
        #
        # @return [self]
        #
        def call
          if @block
            @block.arity < 1 ? instance_eval(&@block) : @block.call(self)
          end
          self
        end

        # Converts the query definition to a Hash
        #
        # @return [Hash]
        #
        def to_hash(_options = {})
          call
          if @value
            @value.to_hash
          else
            {}
          end
        end
      end
    end
  end
end
