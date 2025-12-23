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
  # TODO: Remove this?
  # @api private
  module NaivelyHashable
    def naively_hashable?
      true
    end

    def to_h
      instance_variables.each_with_object({}) do |name, h|
        key = name.to_s.delete('@').to_sym
        value = instance_variable_get(name)
        is_hashable =
          value.respond_to?(:naively_hashable?) && value.naively_hashable?

        h[key] = is_hashable ? value.to_h : value
      end
    end
  end
end
