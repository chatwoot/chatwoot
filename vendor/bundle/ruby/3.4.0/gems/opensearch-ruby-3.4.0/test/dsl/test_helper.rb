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

OPENSEARCH_HOSTS = if hosts = ENV.fetch('TEST_OPENSEARCH_SERVER', nil) || ENV.fetch('OPENSEARCH_HOSTS', nil)
                     hosts.split(',').map do |host|
                       %r{(http://)?(\S+)}.match(host)[2]
                     end
                   else
                     ['localhost:9200']
                   end.freeze

TEST_HOST, TEST_PORT = OPENSEARCH_HOSTS.first.split(':') if OPENSEARCH_HOSTS

JRUBY = defined?(JRUBY_VERSION)

if ENV.fetch('COVERAGE', nil) || ENV.fetch('CI', nil)
  require 'simplecov'
  SimpleCov.start { add_filter '/test|test_' }
end

require 'minitest/autorun'
require 'shoulda-context'
require 'mocha/minitest'

require 'opensearch'
require 'opensearch/dsl'
require 'logger'
require 'ansi'

module OpenSearch
  module Test
    module Assertions
      def assert_nothing_raised(*)
        yield
      end
    end

    class UnitTestCase < ::Minitest::Test
      include Assertions
      alias assert_not_nil refute_nil
      alias assert_raise assert_raises
    end

    class IntegrationTestCase < ::Minitest::Test
      include Assertions
      alias assert_not_nil refute_nil
      alias assert_raise assert_raises

      def setup
        @port = (ENV.fetch('TEST_CLUSTER_PORT', nil) || 9250).to_i

        @logger = Logger.new(STDERR)
        @logger.formatter = proc do |severity, _datetime, _progname, msg|
          color = case severity
                  when /INFO/ then :green
                  when /ERROR|WARN|FATAL/ then :red
                  when /DEBUG/ then :cyan
                  else :white
                  end
          ANSI.ansi(severity[0] + ' ', color, :faint) + ANSI.ansi(msg, :white, :faint) + "\n"
        end

        @client = OpenSearch::Client.new(host: "#{TEST_HOST}:#{TEST_PORT}", logger: (ENV['QUIET'] ? nil : @logger))
        @version = @client.info['version']['number']
      end

      def teardown
        @client.indices.delete index: '_all'
      end
    end
  end
end
