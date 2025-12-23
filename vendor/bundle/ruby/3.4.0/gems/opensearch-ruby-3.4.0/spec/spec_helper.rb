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

if ENV.fetch('COVERAGE', nil) && ENV['CI'].nil?
  require 'simplecov'
  SimpleCov.start { add_filter %r{^/test|spec/} }
end

require 'ansi'
require 'opensearch'
require 'opensearch-dsl'
require 'jbuilder'
require 'jsonify'
require 'yaml'
require 'hashie/mash'

require 'faraday/httpclient'
require 'faraday/net_http_persistent'
require 'logger'
require 'ansi/code'

if defined?(JRUBY_VERSION)
  require 'opensearch/transport/transport/http/manticore'
  require 'pry-nav'
else
  require 'faraday/patron'
  require 'faraday/typhoeus' if Gem::Version.new(Faraday::VERSION) >= Gem::Version.new('2')
  require 'opensearch/transport/transport/http/curb'
  require 'curb'
end

tracer = ::Logger.new(STDERR)
tracer.formatter = ->(_s, _d, _p, m) { "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }

unless defined?(OPENSEARCH_URL)
  OPENSEARCH_URL = ENV.fetch('OPENSEARCH_URL', nil) ||
                   ENV.fetch('TEST_OPENSEARCH_SERVER', nil) ||
                   "http://localhost:#{ENV.fetch('TEST_CLUSTER_PORT', nil) || 9200}"
end

DEFAULT_CLIENT = OpenSearch::Client.new(host: OPENSEARCH_URL,
                                        tracer: (tracer unless ENV['QUIET']))

# The hosts to use for creating a opensearch client.
hosts = ENV['TEST_OPENSEARCH_SERVER'] || ENV['OPENSEARCH_HOSTS']
OPENSEARCH_HOSTS = if hosts
                     hosts.split(',').map do |host|
                       /(http\:\/\/)?(\S+)/.match(host)[2]
                     end
                   else
                     ['localhost:9200']
                   end.freeze

# Are we testing on JRuby?
# @return [ true, false ] Whether JRuby is being used.
def jruby?
  RUBY_PLATFORM =~ /\bjava\b/
end

# The names of the connected nodes.
# @return [ Array<String> ] The node names.
def node_names
  node_stats = default_client.perform_request('GET', '_nodes/stats').body
  $node_names ||= node_stats['nodes'].collect do |name, stats|
    stats['name']
  end
end

# The default client.
# @return [ OpenSearch::Client ] The default client.
def default_client
  $client ||= OpenSearch::Client.new(hosts: OPENSEARCH_HOSTS)
end

class NotFound < StandardError; end

module HelperModule
  def self.included(context)
    context.let(:client_double) do
      Class.new { include OpenSearch::API }.new.tap do |client|
        expect(client).to receive(:perform_request).with(*expected_args).and_return(response_double)
      end
    end

    context.let(:client) do
      Class.new { include OpenSearch::API }.new.tap do |client|
        expect(client).to receive(:perform_request).with(*expected_args).and_return(response_double)
      end
    end

    context.let(:response_double) do
      double('response', status: 200, body: {}, headers: {})
    end

    context.let(:hosts) { OPENSEARCH_HOSTS }
  end
end

RSpec.configure do |config|
  config.include(HelperModule)
  config.formatter = 'documentation'
  config.color = true
end
