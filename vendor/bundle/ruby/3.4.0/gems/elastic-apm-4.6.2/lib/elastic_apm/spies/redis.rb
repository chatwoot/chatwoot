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
  module Spies
    # @api private
    class RedisSpy
      # @api private
      module Ext
        def call(command, &block)
          name = command[0].to_s.upcase

          return super(command, &block) if command[0] == :auth

          ElasticAPM.with_span(name.to_s, 'db.redis') do
            super(command, &block)
          end
        end
      end

      def install
        ::Redis::Client.prepend(Ext)
      end
    end

    register 'Redis', 'redis', RedisSpy.new
  end
end
