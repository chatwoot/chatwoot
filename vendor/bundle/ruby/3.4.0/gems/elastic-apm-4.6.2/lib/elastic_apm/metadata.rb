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
  class Metadata
    def initialize(config)
      @service = ServiceInfo.new(config)
      @process = ProcessInfo.new(config)
      @system = SystemInfo.new(config)
      @labels = config.global_labels
      @cloud = CloudInfo.new(config).fetch!
    end

    attr_reader :service, :process, :system, :cloud, :labels
  end
end

require 'elastic_apm/metadata/service_info'
require 'elastic_apm/metadata/system_info'
require 'elastic_apm/metadata/process_info'
require 'elastic_apm/metadata/cloud_info'
