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
    #
    # Makes a deep copy of an Array or Hash
    # NB: Not guaranteed to work well with complex objects, only simple Hash,
    # Array, String, Number, etc.
    class DeepDup
      def initialize(obj)
        @obj = obj
      end

      def dup
        deep_dup(@obj)
      end

      def self.dup(obj)
        new(obj).dup
      end

      private

      def deep_dup(obj)
        case obj
        when Hash then hash(obj)
        when Array then array(obj)
        else obj.dup
        end
      end

      def array(arr)
        arr.map { |obj| deep_dup(obj) }
      end

      def hash(hsh)
        result = hsh.dup

        hsh.each_pair do |key, value|
          result[key] = deep_dup(value)
        end

        result
      end
    end
  end
end
