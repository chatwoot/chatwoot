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
    class NetHTTPSpy
      DISABLE_KEY = :__elastic_apm_net_http_disabled
      TYPE = 'external'
      SUBTYPE = 'http'

      class << self
        def disabled=(disabled)
          Thread.current[DISABLE_KEY] = disabled
        end

        def disabled?
          Thread.current[DISABLE_KEY] ||= false
        end

        def disable_in
          self.disabled = true

          begin
            yield
          ensure
            self.disabled = false
          end
        end
      end

      # @api private
      module Ext
        # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def request(req, body = nil, &block)
          unless (transaction = ElasticAPM.current_transaction)
            return super(req, body, &block)
          end

          if ElasticAPM::Spies::NetHTTPSpy.disabled?
            return super(req, body, &block)
          end

          host = req['host']&.split(':')&.first || address || 'localhost'
          method = req.method.to_s.upcase

          uri_or_path = URI(req.path)

          # Support the case where a whole url is passed as a path to a nil host
          uri =
            if uri_or_path.host
              uri_or_path
            else
              path, query = req.path.split('?')
              url = use_ssl? ? +'https://' : +'http://'
              url << host
              url << ":#{port}" if port
              url << path
              url << "?#{query}" if query
              URI(url)
            end

          context =
            ElasticAPM::Span::Context.new(
              http: { url: uri, method: method },
              destination: ElasticAPM::Span::Context::Destination.from_uri(uri, type: SUBTYPE)
            )

          ElasticAPM.with_span(
            "#{method} #{host}",
            TYPE,
            subtype: SUBTYPE,
            context: context
          ) do |span|
            trace_context = span&.trace_context || transaction.trace_context
            trace_context.apply_headers { |key, value| req[key] = value }

            result = super(req, body, &block)

            if (http = span&.context&.http)
              http.status_code = result.code
            end

            span&.outcome = Span::Outcome.from_http_status(result.code)
            result
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      end

      def install
        Net::HTTP.prepend(Ext)
      end
    end

    register 'Net::HTTP', 'net/http', NetHTTPSpy.new
  end
end
