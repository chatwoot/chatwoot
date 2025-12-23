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
    class Bytes
      MULTIPLIERS = {
        'kb' => 1024,
        'mb' => 1024 * 1_000,
        'gb' => 1024 * 100_000
      }.freeze
      REGEX = /^(\d+)(b|kb|mb|gb)?$/i.freeze

      def initialize(default_unit: 'kb')
        @default_unit = default_unit
      end

      def call(value)
        _, amount, unit = REGEX.match(String(value)).to_a
        unit ||= @default_unit
        MULTIPLIERS.fetch(unit.downcase, 1) * amount.to_i
      end
    end
  end
end
