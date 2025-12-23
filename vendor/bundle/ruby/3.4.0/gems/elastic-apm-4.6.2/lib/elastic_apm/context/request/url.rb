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
  class Context
    # @api private
    class Request
      # @api private
      class Url
        SKIPPED_PORTS = {
          'http' => 80,
          'https' => 443
        }.freeze

        def initialize(req)
          @protocol = req.scheme
          @hostname = req.host
          @port = req.port.to_s
          @pathname = req.path
          @search = req.query_string
          @hash = nil
          @full = build_full_url req
        end

        attr_reader :protocol, :hostname, :port, :pathname, :search, :hash,
          :full

        private

        def build_full_url(req)
          url = "#{req.scheme}://#{req.host}"

          if req.port != SKIPPED_PORTS[req.scheme]
            url += ":#{req.port}"
          end

          url + req.fullpath
        end
      end
    end
  end
end
