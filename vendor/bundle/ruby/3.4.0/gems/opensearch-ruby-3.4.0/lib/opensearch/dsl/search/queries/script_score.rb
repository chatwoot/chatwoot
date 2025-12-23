# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.

module OpenSearch
  module DSL
    module Search
      module Queries
        # A query which wraps another query and returns a customized score for matching documents
        #
        # @example
        #
        #     search do
        #       query do
        #         script_score do
        #           query do
        #             match content: 'Twitter'
        #           end
        #
        #           script source: "_score * params['multiplier']",
        #                  params: { multiplier: 2.0 }
        #         end
        #       end
        #     end
        #
        # @see https://opensearch.org/docs/latest/query-dsl/specialized/script-score/
        #
        class ScriptScore
          include BaseComponent

          option_method :script
          option_method :min_score
          option_method :boost

          # DSL method for building the `query` part of the query definition
          #
          # @return [self]
          #
          def query(*args, &block)
            @query = block ? @query = Query.new(*args, &block) : args.first
            self
          end

          # Converts the query definition to a Hash
          #
          # @return [Hash]
          #
          def to_hash
            hash = super
            if @query
              _query = @query.respond_to?(:to_hash) ? @query.to_hash : @query
              hash[name].update(query: _query)
            end
            hash
          end
        end
      end
    end
  end
end
