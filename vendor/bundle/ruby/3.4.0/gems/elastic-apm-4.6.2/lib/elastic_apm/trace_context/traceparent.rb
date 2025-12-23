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
  class TraceContext
    # @api private
    class Traceparent
      VERSION = '00'
      NON_HEX_REGEX = /[^[:xdigit:]]/.freeze

      TRACE_ID_LENGTH = 16
      ID_LENGTH = 8

      def initialize(
        version: VERSION,
        trace_id: nil,
        parent_id: nil,
        id: nil,
        recorded: true
      )
        @version = version
        @trace_id = trace_id || hex(TRACE_ID_LENGTH)
        @parent_id = parent_id
        @id = id || hex(ID_LENGTH)
        @recorded = recorded
      end

      attr_accessor :version, :id, :trace_id, :parent_id, :recorded

      alias :recorded? :recorded

      def self.parse(header)
        raise_invalid(header) unless header.length == 55
        raise_invalid(header) unless header[0..1] == VERSION

        new.tap do |t|
          t.version, t.trace_id, t.parent_id, t.flags =
            header.split('-').tap do |values|
              values[-1] = Util.hex_to_bits(values[-1])
            end

          raise_invalid(header) if NON_HEX_REGEX.match?(t.trace_id)
          raise_invalid(header) if NON_HEX_REGEX.match?(t.parent_id)
        end
      end

      class << self
        private

        def raise_invalid(header)
          raise InvalidTraceparentHeader,
            "Couldn't parse invalid traceparent header: #{header.inspect}"
        end
      end

      def flags=(flags)
        @flags = flags

        self.recorded = flags[7] == '1'
      end

      def flags
        format('0000000%d', recorded? ? 1 : 0)
      end

      def hex_flags
        format('%02x', flags.to_i(2))
      end

      def ensure_parent_id
        @parent_id ||= hex(ID_LENGTH)
      end

      def child
        dup.tap do |copy|
          copy.parent_id = id
          copy.id = hex(ID_LENGTH)
        end
      end

      def to_header
        format('%s-%s-%s-%s', version, trace_id, id, hex_flags)
      end

      private

      def hex(len)
        SecureRandom.hex(len)
      end
    end
  end
end
