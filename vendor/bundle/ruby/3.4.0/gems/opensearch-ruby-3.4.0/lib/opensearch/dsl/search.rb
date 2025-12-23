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
    # Provides DSL methods for building the search definition
    # (queries, filters, aggregations, sorting, etc)
    #
    module Search
      # Initialize a new Search object
      #
      # @example Building a search definition declaratively
      #
      #     definition = search do
      #       query do
      #         match title: 'test'
      #       end
      #     end
      #     definition.to_hash
      #     => {:query=>{:match=>{:title=>"test"}}}
      #
      # @example Using the class imperatively
      #
      #     definition = Search.new
      #     query = Queries::Match.new title: 'test'
      #     definition.query query
      #     definition.to_hash
      #     # => {:query=>{:match=>{:title=>"test"}}}
      #
      #
      def search(*args, &block)
        Search.new(*args, &block)
      end

      extend self

      # Wraps the whole search definition (queries, filters, aggregations, sorting, etc)
      #
      class Search
        attr_accessor :aggregations

        def initialize(*args, &block)
          @options = Options.new(*args)
          return unless block
          block.arity < 1 ? instance_eval(&block) : block.call(self)
        end

        # DSL method for building or accessing the `query` part of a search definition
        #
        # @return [self, {Query}]
        #
        def query(*args, &block)
          if block
            @query = Query.new(*args, &block)
            self
          elsif !args.empty?
            @query = args.first
            self
          else
            @query
          end
        end

        # Set the query part of a search definition
        #
        def query=(value)
          query value
        end

        # DSL method for building the `filter` part of a search definition
        #
        # @return [self]
        #
        def filter(*args, &block)
          if block
            @filter = Filter.new(*args, &block)
            self
          elsif !args.empty?
            @filter = args.first
            self
          else
            @filter
          end
        end

        # Set the filter part of a search definition
        #
        def filter=(value)
          filter value
        end

        # DSL method for building the `post_filter` part of a search definition
        #
        # @return [self]
        #
        def post_filter(*args, &block)
          if block
            @post_filter = Filter.new(*args, &block)
            self
          elsif !args.empty?
            @post_filter = args.first
            self
          else
            @post_filter
          end
        end

        # Set the post_filter part of a search definition
        #
        def post_filter=(value)
          post_filter value
        end

        # DSL method for building the `aggregations` part of a search definition
        #
        # @return [self]
        #
        def aggregation(*args, &block)
          @aggregations ||= AggregationsCollection.new

          if block
            @aggregations.update args.first => Aggregation.new(*args, &block)
          else
            name = args.shift
            @aggregations.update name => args.shift
          end
          self
        end

        # Set the aggregations part of a search definition
        #

        # DSL method for building the `highlight` part of a search definition
        #
        # @return [self]
        #
        def highlight(*args, &block)
          if !args.empty? || block
            @highlight = Highlight.new(*args, &block)
            self
          else
            @highlight
          end
        end

        # DSL method for building the `sort` part of a search definition
        #
        # @return [self]
        #
        def sort(*args, &block)
          if !args.empty? || block
            @sort = Sort.new(*args, &block)
            self
          else
            @sort
          end
        end

        # Set the sort part of a search definition
        #
        attr_writer :sort

        # DSL method for building the `stored_fields` part of a search definition
        #
        # @return [self]
        #
        def stored_fields(value = nil)
          if value
            @stored_fields = value
            self
          else
            @stored_fields
          end
        end; alias stored_fields= stored_fields

        # DSL method for building the `size` part of a search definition
        #
        # @return [self]
        #
        def size(value = nil)
          if value
            @size = value
            self
          else
            @size
          end
        end; alias size= size

        # DSL method for building the `from` part of a search definition
        #
        # @return [self]
        #
        def from(value = nil)
          if value
            @from = value
            self
          else
            @from
          end
        end; alias from= from

        # DSL method for building the `suggest` part of a search definition
        #
        # @return [self]
        #
        def suggest(*args, &block)
          if !args.empty? || block
            @suggest ||= {}
            key, options = args
            @suggest.update key => Suggest.new(key, options, &block)
            self
          else
            @suggest
          end
        end

        # Set the suggest part of a search definition
        #
        attr_writer :suggest

        # Delegates to the methods provided by the {Options} class
        #
        def method_missing(name, *args, &block)
          return super unless @options.respond_to? name
          @options.__send__ name, *args, &block
          self
        end

        def respond_to_missing?(method_name, include_private = false)
          @options.respond_to?(method_name) || super
        end

        # Converts the search definition to a Hash
        #
        # @return [Hash]
        #
        def to_hash
          hash = {}
          hash.update(query: @query.to_hash)   if @query
          hash.update(filter: @filter.to_hash) if @filter
          hash.update(post_filter: @post_filter.to_hash) if @post_filter
          if @aggregations
            hash.update(aggregations: @aggregations.reduce({}) do |sum, item|
                                        sum.update item.first => item.last.to_hash
                                      end)
          end
          hash.update(sort: @sort.to_hash) if @sort
          hash.update(size: @size) if @size
          hash.update(stored_fields: @stored_fields) if @stored_fields
          hash.update(from: @from) if @from
          hash.update(suggest: @suggest.reduce({}) { |sum, item| sum.update item.last.to_hash }) if @suggest
          hash.update(highlight: @highlight.to_hash) if @highlight
          hash.update(@options) unless @options.empty?
          hash
        end
      end
    end
  end
end
