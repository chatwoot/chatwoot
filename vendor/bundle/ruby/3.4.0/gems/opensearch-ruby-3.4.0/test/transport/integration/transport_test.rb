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

require_relative '../test_helper'

class OpenSearch::Transport::ClientIntegrationTest < Minitest::Test
  context "Transport" do
    setup do
      @host, @port = OPENSEARCH_HOSTS.first.split(':')
      begin; Object.send(:remove_const, :Patron);   rescue NameError; end
    end

    should "allow to customize the Faraday adapter to Typhoeus" do
      # Require the library so autodetection finds it.
      require 'typhoeus'
      # Require the adapter so autodetection finds it.
      require 'faraday/typhoeus' if Gem::Version.new(Faraday::VERSION) >= Gem::Version.new('2')

      transport = OpenSearch::Transport::Transport::HTTP::Faraday.new \
        :hosts => [ { host: @host, port: @port } ] do |f|
          f.response :logger
          f.adapter  :typhoeus
        end

      client = OpenSearch::Transport::Client.new transport: transport
      response = client.perform_request 'GET', ''

      assert_respond_to(response.body, :to_hash)
      assert_not_nil response.body['name']
      assert_equal 'application/json; charset=UTF-8', response.headers['content-type']
    end unless jruby?

    should "allow to customize the Faraday adapter to NetHttpPersistent" do
      # Require the library so autodetection finds it.
      require 'net/http/persistent'
      # Require the adapter so autodetection finds it.
      require 'faraday/net_http_persistent'

      transport = OpenSearch::Transport::Transport::HTTP::Faraday.new \
                                                                       :hosts => [ { host: @host, port: @port } ] do |f|
        f.response :logger
        f.adapter  :net_http_persistent
      end

      client = OpenSearch::Transport::Client.new transport: transport
      client.perform_request 'GET', ''
    end

    should "allow to define connection parameters and pass them" do
      transport = OpenSearch::Transport::Transport::HTTP::Faraday.new \
                    :hosts => [ { host: @host, port: @port } ],
                    :options => { :transport_options => {
                                    :params => { :format => 'yaml' }
                                  }
                                }

      client = OpenSearch::Transport::Client.new transport: transport
      response = client.perform_request 'GET', ''

      assert response.body.start_with?("---\n"), "Response body should be YAML: #{response.body.inspect}"
    end

    should "use the Curb client" do
      require 'curb'
      require 'opensearch/transport/transport/http/curb'

      transport = OpenSearch::Transport::Transport::HTTP::Curb.new \
        :hosts => [ { host: @host, port: @port } ] do |curl|
          curl.verbose = true
        end

      client = OpenSearch::Transport::Client.new transport: transport
      client.perform_request 'GET', ''
    end unless JRUBY

    should "deserialize JSON responses in the Curb client" do
      require 'curb'
      require 'opensearch/transport/transport/http/curb'

      transport = OpenSearch::Transport::Transport::HTTP::Curb.new \
        :hosts => [ { host: @host, port: @port } ] do |curl|
          curl.verbose = true
        end

      client = OpenSearch::Transport::Client.new transport: transport
      response = client.perform_request 'GET', ''

      assert_respond_to(response.body, :to_hash)
      assert_not_nil response.body['name']
      assert_equal 'application/json', response.headers['content-type']
    end unless JRUBY
  end

end
