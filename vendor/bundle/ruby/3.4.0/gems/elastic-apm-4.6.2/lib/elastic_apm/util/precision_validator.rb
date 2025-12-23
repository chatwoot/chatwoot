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
    # Rounds half away from zero.
    # If `minimum` is provided, and the value rounds to 0 (but was not zero to
    # begin with), use the minimum instead.
    module PrecisionValidator
      module_function

      def validate(value, precision: 0, minimum: nil)
        float = Float(value)
        return nil unless (0.0..1.0).cover?(float)
        return float if float == 0

        multiplier = Float(10**precision)
        rounded = (float * multiplier + 0.5).floor / multiplier
        if rounded == 0 && minimum
          minimum
        else
          rounded
        end
      rescue ArgumentError
        nil
      end
    end
  end
end
