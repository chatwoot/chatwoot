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

require 'elastic_apm/util/precision_validator'

module ElasticAPM
  class TraceContext
    # @api private
    class Tracestate
      # @api private
      class Entry
        def initialize(key, value)
          @key = key
          @value = value
        end

        attr_reader :key, :value

        def to_s
          "#{key}=#{value}"
        end
      end

      # @api private
      class EsEntry
        ASSIGN = ':'
        SPLIT = ';'

        SHORT_TO_LONG = { 's' => 'sample_rate' }.freeze
        LONG_TO_SHORT = { 'sample_rate' => 's' }.freeze

        def initialize(values = nil)
          parse(values)
        end

        attr_reader :sample_rate

        def key
          'es'
        end

        def value
          LONG_TO_SHORT.map do |l, s|
            "#{s}#{ASSIGN}#{send(l)}"
          end.join(SPLIT)
        end

        def empty?
          !sample_rate
        end

        def sample_rate=(val)
          @sample_rate = Util::PrecisionValidator.validate(
            val, precision: 4, minimum: 0.0001
          )
        end

        def to_s
          return nil if empty?

          "es=#{value}"
        end

        private

        def parse(values)
          return unless values

          values.split(SPLIT).map do |kv|
            k, v = kv.split(ASSIGN)
            next unless SHORT_TO_LONG.key?(k)
            send("#{SHORT_TO_LONG[k]}=", v)
          end
        end
      end

      extend Forwardable

      ENTRY_SPLIT_REGEX = /\s*[\n,]+\s*/

      def initialize(entries: {}, sample_rate: nil)
        @entries = entries

        self.sample_rate = sample_rate if sample_rate
      end

      attr_accessor :entries

      def_delegators :es_entry, :sample_rate, :sample_rate=

      def self.parse(header)
        entries =
          split_by_nl_and_comma(header)
          .each_with_object({}) do |entry, hsh|
            k, v = entry.split('=')
            next unless k && v && !k.empty? && !v.empty?
            hsh[k] =
              case k
              when 'es' then EsEntry.new(v)
              else Entry.new(k, v)
              end
          end

        new(entries: entries)
      end

      def to_header
        return "" unless entries.any?

        entries.values.map(&:to_s).join(',')
      end

      private

      def es_entry
        # lazy generate this so we only add it if necessary
        entries['es'] ||= EsEntry.new
      end

      class << self
        private

        def split_by_nl_and_comma(str)
          # HTTP allows multiple headers with the same name, eg. multiple
          # Set-Cookie headers per response.
          # Rack handles this by joining the headers under the same key,
          # separated by newlines.
          # See https://www.rubydoc.info/github/rack/rack/file/SPEC
          String(str).split(ENTRY_SPLIT_REGEX).flatten
        end
      end
    end
  end
end
