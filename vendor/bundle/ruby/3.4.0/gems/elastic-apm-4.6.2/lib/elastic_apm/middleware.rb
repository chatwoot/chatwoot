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

#
# frozen_string_literal: true

module ElasticAPM
  # @api private
  class Middleware
    include Logging

    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        if running? && !path_ignored?(env)
          transaction = start_transaction(env)
        end

        resp = @app.call env
      rescue InternalError
        raise # Don't report ElasticAPM errors
      rescue ::Exception => e
        context = ElasticAPM.build_context(rack_env: env, for_type: :error)
        ElasticAPM.report(e, context: context, handled: false)
        raise
      ensure
        if transaction
          if resp
            status, headers, _body = resp
            transaction.add_response(status, headers: headers.dup)
            transaction&.outcome = Transaction::Outcome.from_http_status(status)
          else
            transaction&.outcome = Transaction::Outcome::FAILURE
          end
        end

        ElasticAPM.end_transaction http_result(status)
      end

      resp
    end

    private

    def http_result(status)
      status && "HTTP #{status.to_s[0]}xx"
    end

    def path_ignored?(env)
      return true if config.ignore_url_patterns.any? do |r|
        r.match(env['PATH_INFO'])
      end

      return true if config.transaction_ignore_urls.any? do |r|
        r.match(env['PATH_INFO'])
      end

      false
    end

    def start_transaction(env)
      context = ElasticAPM.build_context(rack_env: env, for_type: :transaction)

      ElasticAPM.start_transaction 'Rack', 'request',
        context: context,
        trace_context: trace_context(env)
    end

    def trace_context(env)
      TraceContext.parse(env: env)
    rescue TraceContext::InvalidTraceparentHeader => e
      warn e.message
      nil
    end

    def running?
      ElasticAPM.running?
    end

    def config
      @config ||= ElasticAPM.agent.config
    end
  end
end
