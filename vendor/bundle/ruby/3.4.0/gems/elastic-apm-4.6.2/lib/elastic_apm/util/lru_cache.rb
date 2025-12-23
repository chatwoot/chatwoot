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
  module Util
    # @api private
    class LruCache
      def initialize(max_size = 512, &block)
        @max_size = max_size
        @data = Hash.new(&block)
        @mutex = Mutex.new
      end

      def [](key)
        @mutex.synchronize do
          val = @data[key]
          return unless val
          add(key, val)
          val
        end
      end

      def []=(key, val)
        @mutex.synchronize do
          add(key, val)
        end
      end

      def length
        @data.length
      end

      def to_a
        @data.to_a
      end

      private

      def add(key, val)
        @data.delete(key)
        @data[key] = val

        return unless @data.length > @max_size

        @data.delete(@data.first[0])
      end
    end
  end
end
