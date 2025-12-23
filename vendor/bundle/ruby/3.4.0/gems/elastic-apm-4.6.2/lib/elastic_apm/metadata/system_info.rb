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
    class SystemInfo
      def initialize(config)
        @config = config

        @configured_hostname = @config.hostname
        @detected_hostname = detect_hostname
        @architecture = gem_platform.cpu
        @platform = gem_platform.os

        container_info = ContainerInfo.read!(@detected_hostname)
        @container = container_info.container
        @kubernetes = container_info.kubernetes
      end

      attr_reader(
        :detected_hostname,
        :configured_hostname,
        :architecture,
        :platform,
        :container,
        :kubernetes
      )

      def gem_platform
        @gem_platform ||= Gem::Platform.local
      end

      private

      def detect_hostname
        Socket.gethostname.chomp
      rescue
      end
    end
  end
end

require 'elastic_apm/metadata/system_info/container_info'
