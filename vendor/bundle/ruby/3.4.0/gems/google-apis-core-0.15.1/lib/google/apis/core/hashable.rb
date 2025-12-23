# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Google
  module Apis
    module Core
      # Adds to_hash to objects
      module Hashable
        # Convert object to hash representation
        #
        # @return [Hash]
        def to_h
          Hash[instance_variables.map { |k| [k[1..-1].to_sym, Hashable.process_value(instance_variable_get(k))] }]
        end

        # Recursively serialize an object
        #
        # @param [Object] val
        # @return [Hash]
        def self.process_value(val)
          case val
          when Hash
            Hash[val.map {|k, v| [k.to_sym, Hashable.process_value(v)] }]
          when Array
            val.map{ |v| Hashable.process_value(v) }
          else
            val.respond_to?(:to_h) ? val.to_h : val
          end
        end
      end
    end
  end
end
