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
  module Transport
    module Transport
      # Wraps the response from OpenSearch.
      #
      class Response
        attr_reader :status, :body, :headers

        # @param status  [Integer] Response status code
        # @param body    [String]  Response body
        # @param headers [Hash]    Response headers
        def initialize(status, body, headers = {})
          @status = status
          @body = body
          @headers = headers
          @body = body.force_encoding('UTF-8') if body.respond_to?(:force_encoding) && body.encoding != Encoding::UTF_8
        end
      end
    end
  end
end
