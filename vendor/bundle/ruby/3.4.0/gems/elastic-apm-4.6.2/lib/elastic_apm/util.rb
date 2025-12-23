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
  module Util
    def self.micros(target = Time.now)
      utc = target.utc
      utc.to_i * 1_000_000 + utc.usec
    end

    def self.monotonic_micros
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
    end

    def self.git_sha
      sha = `git rev-parse --verify HEAD 2>&1`.chomp
      $?&.success? ? sha : nil
    end

    def self.hex_to_bits(str)
      str.hex.to_s(2).rjust(str.size * 4, '0')
    end

    def self.reverse_merge!(first, *others)
      others.reduce(first) do |curr, other|
        curr.merge!(other) { |_, _, new| new }
      end
    end

    def self.truncate(value, max_length: 1024)
      return unless value

      value = String(value)
      return value if value.length <= max_length

      value[0...(max_length - 1)] + '…'
    end
  end
end
