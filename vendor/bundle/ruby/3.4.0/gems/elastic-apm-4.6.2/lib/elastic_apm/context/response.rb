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
  class Context
    # @api private
    class Response
      def initialize(
        status_code,
        headers: {},
        headers_sent: true,
        finished: true
      )
        @status_code = status_code
        @headers_sent = headers_sent
        @finished = finished

        self.headers = headers
      end

      attr_accessor :status_code, :headers_sent, :finished
      attr_reader :headers

      def headers=(headers)
        @headers = headers&.transform_values { |v| v.to_s }
      end
    end
  end
end
