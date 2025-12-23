# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
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

require 'opensearch/version'
require 'opensearch/transport'
require 'opensearch/api'

module OpenSearch
  SECURITY_PRIVILEGES_VALIDATION_WARNING = 'The client is unable to verify distribution due to security privileges on the server side. Some functionality may not be compatible if the server is running an unsupported product.'.freeze
  NOT_SUPPORTED_WARNING = 'The client is not supported for the provided version and distribution combination.'.freeze

  class Client
    include OpenSearch::API
    attr_accessor :transport

    # See OpenSearch::Transport::Client for initializer parameters
    def initialize(arguments = {}, &block)
      @verified = false
      @transport = OpenSearch::Transport::Client.new(arguments, &block)
    end

    def method_missing(name, *args, &block)
      return super unless name == :perform_request
      verify_open_search unless @verified
      @transport.perform_request(*args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name == :perform_request || super
    end

    private

    def verify_open_search
      begin
        response = open_search_validation_request
      rescue OpenSearch::Transport::Transport::Errors::Unauthorized,
             OpenSearch::Transport::Transport::Errors::Forbidden
        @verified = true
        warn(SECURITY_PRIVILEGES_VALIDATION_WARNING)
        return
      end

      body = if response.headers['content-type'] == 'application/yaml'
               require 'yaml'
               YAML.safe_load(response.body)
             else
               response.body
             end
      version = body.dig('version', 'number')
      distribution = body.dig('version', 'distribution')
      verify_version_and_distribution(version, distribution)
    end

    def verify_version_and_distribution(version, distribution)
      raise OpenSearch::UnsupportedProductError if version.nil?

      # The client supports all the versions of OpenSearch
      if distribution != 'opensearch' &&
         (Gem::Version.new(version) < Gem::Version.new('6.0.0') ||
           Gem::Version.new(version) >= Gem::Version.new('8.0.0'))
        raise OpenSearch::UnsupportedProductError
      end

      @verified = true
    end

    def open_search_validation_request
      @transport.perform_request('GET', '/')
    end
  end

  class UnsupportedProductError < StandardError
    def initialize(message = NOT_SUPPORTED_WARNING)
      super(message)
    end
  end
end
