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

if JRUBY
  puts "'#{File.basename(__FILE__)}' not supported on JRuby #{RUBY_VERSION}"
else
  require 'opensearch/transport/transport/http/curb'
  require 'curb'

  class OpenSearch::Transport::Transport::HTTP::FaradayTest < Minitest::Test
    include OpenSearch::Transport::Transport::HTTP

    context "Curb transport" do
      setup do
        @transport = Curb.new :hosts => [ { :host => 'foobar', :port => 1234 } ]
      end

      should "implement host_unreachable_exceptions" do
        assert_instance_of Array, @transport.host_unreachable_exceptions
      end

      should "implement __build_connections" do
        assert_equal 1, @transport.hosts.size
        assert_equal 1, @transport.connections.size

        assert_instance_of ::Curl::Easy,   @transport.connections.first.connection
        assert_equal 'http://foobar:1234', @transport.connections.first.connection.url
      end

      should "perform the request" do
        @transport.connections.first.connection.expects(:http).returns(stub_everything)
        @transport.perform_request 'GET', '/'
      end

      should "set body for GET request" do
        @transport.connections.first.connection.expects(:put_data=).with('{"foo":"bar"}')
        @transport.connections.first.connection.expects(:http).with(:GET).returns(stub_everything)
        @transport.perform_request 'GET', '/', {}, '{"foo":"bar"}'
      end

      should "perform request with headers" do
        @transport.connections.first.connection.expects(:put_data=).with('{"foo":"bar"}')
        @transport.connections.first.connection.expects(:http).with(:POST).returns(stub_everything)
        @transport.connections.first.connection.headers.expects(:merge!).with("Content-Type" => "application/x-ndjson")

        @transport.perform_request 'POST', '/', {}, {:foo => 'bar'}, {"Content-Type" => "application/x-ndjson"}
      end

      should "set body for PUT request" do
        @transport.connections.first.connection.expects(:put_data=)
        @transport.connections.first.connection.expects(:http).with(:PUT).returns(stub_everything)
        @transport.perform_request 'PUT', '/', {}, {:foo => 'bar'}
      end

      should "serialize the request body" do
        @transport.connections.first.connection.expects(:http).with(:POST).returns(stub_everything)
        @transport.serializer.expects(:dump)
        @transport.perform_request 'POST', '/', {}, {:foo => 'bar'}
      end

      should "not serialize a String request body" do
        @transport.connections.first.connection.expects(:http).with(:POST).returns(stub_everything)
        @transport.serializer.expects(:dump).never
        @transport.perform_request 'POST', '/', {}, '{"foo":"bar"}'
      end

      should "set application/json response header" do
        @transport.connections.first.connection.expects(:http).with(:GET).returns(stub_everything)
        @transport.connections.first.connection.expects(:body_str).returns('{"foo":"bar"}')
        @transport.connections.first.connection.expects(:header_str).returns('HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=UTF-8\r\nContent-Length: 311\r\n\r\n')
        response = @transport.perform_request 'GET', '/'

        assert_equal 'application/json', response.headers['content-type']
      end

      should "handle HTTP methods" do
        @transport.connections.first.connection.expects(:http).with(:HEAD).returns(stub_everything)
        @transport.connections.first.connection.expects(:http).with(:GET).returns(stub_everything)
        @transport.connections.first.connection.expects(:http).with(:PUT).returns(stub_everything)
        @transport.connections.first.connection.expects(:http).with(:POST).returns(stub_everything)
        @transport.connections.first.connection.expects(:http).with(:DELETE).returns(stub_everything)

        %w| HEAD GET PUT POST DELETE |.each { |method| @transport.perform_request method, '/' }

        assert_raise(ArgumentError) { @transport.perform_request 'FOOBAR', '/' }
      end

      should "properly pass the Content-Type header option" do
        transport = Curb.new :hosts => [ { :host => 'foobar', :port => 1234 } ], :options => { :transport_options => { :headers => { 'Content-Type' => 'foo/bar' } } }

        assert_equal "foo/bar", transport.connections.first.connection.headers["Content-Type"]
      end

      should "allow to set options for Curb" do
        transport = Curb.new :hosts => [ { :host => 'foobar', :port => 1234 } ] do |curl|
          curl.headers["User-Agent"] = "myapp-0.0"
        end

        assert_equal "myapp-0.0", transport.connections.first.connection.headers["User-Agent"]
      end

      should "set the credentials if passed" do
        transport = Curb.new :hosts => [ { :host => 'foobar', :port => 1234, :user => 'foo', :password => 'bar' } ]
        assert_equal 'foo', transport.connections.first.connection.username
        assert_equal 'bar', transport.connections.first.connection.password
      end

      should "use global http configuration" do
        transport = Faraday.new :hosts => [ { :host => 'foobar', :port => 1234 } ],
                                :options => { :http => { :scheme => 'https', :user => 'U', :password => 'P' } }

        assert_equal 'https://U:P@foobar:1234/', transport.connections.first.full_url('')
      end
    end

  end

end
