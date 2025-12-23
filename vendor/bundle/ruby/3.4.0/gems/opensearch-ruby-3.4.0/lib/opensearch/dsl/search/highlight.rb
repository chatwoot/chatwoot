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
      # Wraps the `highlight` part of a search definition
      #
      #
      class Highlight
        include BaseComponent

        def initialize(*args, &block)
          @value = args.pop || {}
          super
        end

        # Specify the fields to highlight
        #
        # @example
        #
        #     search do
        #       highlight do
        #         fields [:title, :body]
        #         field  :comments.body if options[:comments]
        #       end
        #     end
        #
        def fields(value_or_name)
          value = case value_or_name
                  when Hash
                    value_or_name
                  when Array
                    value_or_name.each_with_object({}) do |item, sum|
                      sum.update item.to_sym => {}
                    end
                  end

          (@value[:fields] ||= {}).update value
          self
        end

        # Specify a single field to highlight
        #
        # @example
        #
        #     search do
        #       highlight do
        #         field :title, fragment_size: 0
        #         field :body if options[:comments]
        #       end
        #     end
        #
        def field(name, options = {})
          (@value[:fields] ||= {}).update name.to_sym => options
        end

        # Specify the opening tags for the highlighted snippets
        #
        def pre_tags(*value)
          @value[:pre_tags] = value.flatten
        end; alias pre_tags= pre_tags

        # Specify the closing tags for the highlighted snippets
        #
        def post_tags(*value)
          @value[:post_tags] = value.flatten
        end; alias post_tags= post_tags

        # Specify the `encoder` option for highlighting
        #
        def encoder(value)
          @value[:encoder] = value
        end; alias encoder= encoder

        # Specify the `tags_schema` option for highlighting
        #
        def tags_schema(value)
          @value[:tags_schema] = value
        end; alias tags_schema= tags_schema

        # Convert the definition to a Hash
        #
        # @return [Hash]
        #
        def to_hash
          call
          @hash = @value
          @hash
        end
      end
    end
  end
end
