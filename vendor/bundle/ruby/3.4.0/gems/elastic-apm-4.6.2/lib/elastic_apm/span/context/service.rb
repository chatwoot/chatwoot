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
  class Span
    class Context
      # @api private
      class Service
        include Fields

        field :target

        # @api private
        class Target
          include Fields

          field :name, default: ''
          field :type, default: ''
        end

        def initialize(target: nil, **attrs)
          super(**attrs)

          self.target = build_target(target)
        end

        private

        def build_target(target = nil)
          return Target.new unless target
          return target if target.is_a?(Target)

          Target.new(**target)
        end
      end
    end
  end
end
  