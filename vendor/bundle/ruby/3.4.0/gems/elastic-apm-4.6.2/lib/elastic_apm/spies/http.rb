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
  module Spies
    # @api private
    class HTTPSpy
      TYPE = 'external'
      SUBTYPE = 'http'

      # @api private
      module Ext
        def perform(req, options)
          unless (transaction = ElasticAPM.current_transaction)
            return super(req, options)
          end

          method = req.verb.to_s.upcase
          host = req.uri.host

          context = ElasticAPM::Span::Context.new(
            http: { url: req.uri, method: method },
            destination: ElasticAPM::Span::Context::Destination.from_uri(req.uri, type: SUBTYPE)
          )

          name = "#{method} #{host}"

          ElasticAPM.with_span(
            name,
            TYPE,
            subtype: SUBTYPE,
            context: context
          ) do |span|
            trace_context = span&.trace_context || transaction.trace_context
            trace_context.apply_headers { |key, value| req[key] = value }

            result = super(req, options)

            if (http = span&.context&.http)
              http.status_code = result.status.to_s
            end

            span&.outcome = Span::Outcome.from_http_status(result.status)
            result
          end
        end
      end

      def install
        ::HTTP::Client.prepend(Ext)
      end
    end

    register 'HTTP', 'http', HTTPSpy.new
  end
end
