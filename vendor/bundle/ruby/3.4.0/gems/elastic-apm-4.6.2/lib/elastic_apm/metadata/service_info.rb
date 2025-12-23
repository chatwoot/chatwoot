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
  class Metadata
    # @api private
    class ServiceInfo
      # @api private
      class Versioned
        def initialize(name: nil, version: nil)
          @name = name
          @version = version
        end

        attr_reader :name, :version
      end

      class Agent < Versioned; end
      class Framework < Versioned; end
      class Language < Versioned; end
      class Runtime < Versioned; end

      def initialize(config)
        @config = config

        @name = @config.service_name
        @node_name = @config.service_node_name
        @environment = @config.environment
        @agent = Agent.new(name: 'ruby', version: VERSION)
        @framework = Framework.new(
          name: @config.framework_name,
          version: @config.framework_version
        )
        @language = Language.new(name: 'ruby', version: RUBY_VERSION)
        @runtime = lookup_runtime
        @version = @config.service_version
      end

      attr_reader :name, :node_name, :environment, :agent, :framework,
        :language, :runtime, :version

      private

      def lookup_runtime
        case RUBY_ENGINE
        when 'ruby'
          Runtime.new(
            name: RUBY_ENGINE,
            version: RUBY_VERSION || RUBY_ENGINE_VERSION
          )
        when 'jruby'
          Runtime.new(
            name: RUBY_ENGINE,
            version: JRUBY_VERSION || RUBY_ENGINE_VERSION
          )
        end
      end
    end
  end
end
