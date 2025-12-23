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
    # Class for wrapping a hash that could have sensitive data.
    # When printed, the sensitive values will be redacted.
    #
    # @since 6.1.1
    class Redacted < ::Hash
      def initialize(elements = nil)
        super()
        (elements || {}).each_pair { |key, value| self[key] = value }
      end

      # The keys whose values will be redacted.
      #
      # @since 6.1.1
      SENSITIVE_KEYS = %i[password
                          pwd].freeze

      # The replacement string used in place of the value for sensitive keys.
      #
      # @since 6.1.1
      STRING_REPLACEMENT = '<REDACTED>'.freeze

      # Get a string representation of the hash.
      #
      # @return [ String ] The string representation of the hash.
      #
      # @since 6.1.1
      def inspect
        redacted_string(:inspect)
      end

      # Get a string representation of the hash.
      #
      # @return [ String ] The string representation of the hash.
      #
      # @since 6.1.1
      def to_s
        redacted_string(:to_s)
      end

      private

      def redacted_string(method)
        content = map { |k, v| "#{k.send(method)}=>#{redact(k, v, method)}" }
        "{#{content.join(', ')}}"
      end

      def redact(key, val, method)
        return STRING_REPLACEMENT if SENSITIVE_KEYS.include?(key.to_sym)

        val.send(method)
      end
    end
  end
end
