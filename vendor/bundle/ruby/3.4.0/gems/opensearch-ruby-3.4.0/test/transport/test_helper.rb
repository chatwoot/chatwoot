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


OPENSEARCH_HOSTS = if hosts = ENV['TEST_OPENSEARCH_SERVER'] || ENV['OPENSEARCH_HOSTS']
                        hosts.split(',').map do |host|
                          /(http\:\/\/)?(\S+)/.match(host)[2]
                        end
                      else
                        ['localhost:9200']
                      end.freeze

TEST_HOST, TEST_PORT = OPENSEARCH_HOSTS.first.split(':') if OPENSEARCH_HOSTS

JRUBY    = defined?(JRUBY_VERSION)

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start { add_filter %r{^/test/} }
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'
require 'mocha/minitest'
require 'ansi/code'

require 'require-prof' if ENV["REQUIRE_PROF"]
require 'opensearch'
require 'logger'

require 'hashie'

RequireProf.print_timing_infos if ENV["REQUIRE_PROF"]

class FixedMinitestSpecReporter < Minitest::Reporters::SpecReporter
  def before_test(test)
    last_test = tests.last

    before_suite(test.class) unless last_test

    if last_test && last_test.klass.to_s != test.class.to_s
      after_suite(last_test.class) if last_test
      before_suite(test.class)
    end
  end
end

module Minitest
  class Test
    def assert_nothing_raised(*args)
      begin
        line = __LINE__
        yield
      rescue RuntimeError => e
        raise MiniTest::Assertion, "Exception raised:\n<#{e.class}>", e.backtrace
      end
      true
    end

    def assert_not_nil(object, msg=nil)
      msg = message(msg) { "<#{object.inspect}> expected to not be nil" }
      assert !object.nil?, msg
    end

    def assert_block(*msgs)
      assert yield, *msgs
    end

    alias :assert_raise :assert_raises
  end
end

Minitest::Reporters.use! FixedMinitestSpecReporter.new unless ENV['RM_INFO']
