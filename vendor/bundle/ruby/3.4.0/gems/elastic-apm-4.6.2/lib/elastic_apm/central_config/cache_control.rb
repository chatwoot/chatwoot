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
  class CentralConfig
    # @api private
    class CacheControl
      def initialize(value)
        @header = value
        parse!(value)
      end

      attr_reader(
        :must_revalidate,
        :no_cache,
        :no_store,
        :no_transform,
        :public,
        :private,
        :proxy_revalidate,
        :max_age,
        :s_maxage
      )

      private

      def parse!(value)
        value.split(',').each do |token|
          k, v = token.split('=').map(&:strip)
          instance_variable_set(:"@#{k.tr('-', '_')}", v ? v.to_i : true)
        end
      end
    end
  end
end
