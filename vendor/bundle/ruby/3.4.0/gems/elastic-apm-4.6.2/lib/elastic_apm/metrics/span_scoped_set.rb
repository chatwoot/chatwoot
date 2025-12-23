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
  module Metrics
    # @api private
    class SpanScopedSet < Set
      def collect
        super.tap do |sets|
          next unless sets

          sets.each do |set|
            move_transaction(set)
            move_span(set)
          end
        end
      end

      private

      def move_transaction(set)
        name = set.tags&.delete(:'transaction.name')
        type = set.tags&.delete(:'transaction.type')
        return unless name || type

        set.transaction = { name: name, type: type }
        set.tags = nil if set.tags.empty?
      end

      def move_span(set)
        type = set.tags&.delete(:'span.type')
        subtype = set.tags&.delete(:'span.subtype')
        return unless type

        set.span = { type: type, subtype: subtype }
        set.tags = nil if set.tags.empty?
      end
    end
  end
end
