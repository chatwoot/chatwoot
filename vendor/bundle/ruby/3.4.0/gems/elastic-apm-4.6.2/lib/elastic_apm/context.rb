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

require 'elastic_apm/context/request'
require 'elastic_apm/context/request/socket'
require 'elastic_apm/context/request/url'
require 'elastic_apm/context/response'
require 'elastic_apm/context/user'

module ElasticAPM
  # @api private
  class Context
    def initialize(custom: {}, labels: {}, user: nil, service: nil)
      @custom = custom
      @labels = labels
      @user = user || User.new
      @service = service
    end

    Service = Struct.new(:framework)
    Framework = Struct.new(:name, :version)

    attr_accessor :request, :response, :user
    attr_reader :custom, :labels, :service

    def empty?
      return false if labels.any?
      return false if custom.any?
      return false if user.any?
      return false if service
      return false if request || response

      true
    end

    def set_service(framework_name: nil, framework_version: nil)
      @service = Service.new(
        Framework.new(framework_name, framework_version)
      )
    end
  end
end
