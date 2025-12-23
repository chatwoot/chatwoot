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
  class Config
    # @api private
    class WildcardPatternList
      # @api private
      class WildcardPattern
        def initialize(str)
          @pattern = convert(str)
        end

        attr_reader :pattern

        def match?(other)
          !!@pattern.match(other)
        end

        alias :match :match?

        private

        def convert(str)
          case_sensitive = false

          if str.start_with?('(?-i)')
            str = str.gsub(/^\(\?-\i\)/, '')
            case_sensitive = true
          end

          parts =
            str.chars.each_with_object([]) do |char, arr|
              arr << (char == '*' ? '.*' : Regexp.escape(char))
            end

          Regexp.new(
            '\A' + parts.join + '\Z',
            case_sensitive ? nil : Regexp::IGNORECASE
          )
        end
      end

      def call(value)
        value = value.is_a?(String) ? value.split(',') : Array(value)
        value.map { |p| WildcardPattern.new(p) }
      end
    end
  end
end
