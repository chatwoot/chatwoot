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

module OpenSearch
  module Transport
    module Transport
      # @abstract Module with common functionality for transport implementations.
      #
      module Base
        include Loggable

        DEFAULT_PORT             = 9200
        DEFAULT_PROTOCOL         = 'http'
        DEFAULT_RELOAD_AFTER     = 10_000 # Requests
        DEFAULT_RESURRECT_AFTER  = 60     # Seconds
        DEFAULT_MAX_RETRIES      = 3      # Requests
        DEFAULT_SERIALIZER_CLASS = Serializer::MultiJson
        SANITIZED_PASSWORD       = '*' * rand(1..14)

        attr_reader   :hosts, :options, :connections, :counter, :last_request_at, :protocol
        attr_accessor :serializer, :sniffer, :logger, :tracer,
                      :reload_connections, :reload_after,
                      :resurrect_after

        # Creates a new transport object
        #
        # @param arguments [Hash] Settings and options for the transport
        # @param block     [Proc] Lambda or Proc which can be evaluated in the context of the "session" object
        #
        # @option arguments [Array] :hosts   An Array of normalized hosts information
        # @option arguments [Array] :options A Hash with options (usually passed by {Client})
        #
        # @see Client#initialize
        #
        def initialize(arguments = {}, &block)
          @state_mutex = Mutex.new

          @hosts       = arguments[:hosts]   || []
          @options     = arguments[:options] || {}
          @options[:http] ||= {}
          @options[:retry_on_status] ||= []

          @block       = block
          @compression = !@options[:compression].nil?
          @connections = __build_connections

          @serializer  = options[:serializer] || (options[:serializer_class] ? options[:serializer_class].new(self) : DEFAULT_SERIALIZER_CLASS.new(self))
          @protocol    = options[:protocol] || DEFAULT_PROTOCOL

          @logger      = options[:logger]
          @tracer      = options[:tracer]

          @sniffer     = options[:sniffer_class] ? options[:sniffer_class].new(self) : Sniffer.new(self)
          @counter     = 0
          @counter_mtx = Mutex.new
          @last_request_at = Time.now
          @reload_connections = options[:reload_connections]
          @reload_after    = options[:reload_connections].is_a?(Integer) ? options[:reload_connections] : DEFAULT_RELOAD_AFTER
          @resurrect_after = options[:resurrect_after] || DEFAULT_RESURRECT_AFTER
          @retry_on_status = Array(options[:retry_on_status]).map(&:to_i)
        end

        # Returns a connection from the connection pool by delegating to {Connections::Collection#get_connection}.
        #
        # Resurrects dead connection if the `resurrect_after` timeout has passed.
        # Increments the counter and performs connection reloading if the `reload_connections` option is set.
        #
        # @return [Connections::Connection]
        # @see    Connections::Collection#get_connection
        #
        def get_connection(options = {})
          resurrect_dead_connections! if Time.now > @last_request_at + @resurrect_after

          @counter_mtx.synchronize { @counter += 1 }
          reload_connections! if reload_connections && (counter % reload_after).zero?
          connections.get_connection(options)
        end

        # Reloads and replaces the connection collection based on cluster information
        #
        # @see Sniffer#hosts
        #
        def reload_connections!
          hosts = sniffer.hosts
          __rebuild_connections hosts: hosts, options: options
          self
        rescue SnifferTimeoutError
          log_error '[SnifferTimeoutError] Timeout when reloading connections.'
          self
        end

        # Tries to "resurrect" all eligible dead connections
        #
        # @see Connections::Connection#resurrect!
        #
        def resurrect_dead_connections!
          connections.dead.each(&:resurrect!)
        end

        # Rebuilds the connections collection in the transport.
        #
        # The methods *adds* new connections from the passed hosts to the collection,
        # and *removes* all connections not contained in the passed hosts.
        #
        # @return [Connections::Collection]
        # @api private
        #
        def __rebuild_connections(arguments = {})
          @state_mutex.synchronize do
            @hosts       = arguments[:hosts]    || []
            @options     = arguments[:options]  || {}

            __close_connections

            new_connections = __build_connections
            stale_connections = @connections.all.reject { |c| new_connections.include?(c) }
            new_connections = new_connections.reject { |c| @connections.all.include?(c) }

            @connections.remove(stale_connections)
            @connections.add(new_connections)
            @connections
          end
        end

        # Builds and returns a collection of connections
        #
        # The adapters have to implement the {Base#__build_connection} method.
        #
        # @return [Connections::Collection]
        # @api    private
        #
        def __build_connections
          Connections::Collection.new \
            connections: hosts.map { |host|
                           host[:protocol] =
                             host[:scheme] || options[:scheme] || options[:http][:scheme] || DEFAULT_PROTOCOL
                           host[:port] ||= options[:port] || options[:http][:port] || DEFAULT_PORT
                           if (options[:user] || options[:http][:user]) && !host[:user]
                             host[:user] ||= options[:user] || options[:http][:user]
                             host[:password] ||= options[:password] || options[:http][:password]
                           end

                           __build_connection(host, (options[:transport_options] || {}), @block)
                         },
            selector_class: options[:selector_class],
            selector: options[:selector]
        end

        # @abstract Build and return a connection.
        #           A transport implementation *must* implement this method.
        #           See {HTTP::Faraday#__build_connection} for an example.
        #
        # @return [Connections::Connection]
        # @api    private
        #
        def __build_connection(_host, _options = {}, _block = nil)
          raise NoMethodError, 'Implement this method in your class'
        end

        # Closes the connections collection
        #
        # @api private
        #
        def __close_connections
          # A hook point for specific adapters when they need to close connections
        end

        # Log request and response information
        #
        # @api private
        #
        def __log_response(method, _path, _params, body, url, response, _json, took, duration)
          return unless logger
          sanitized_url = url.to_s.gsub(%r{//(.+):(.+)@}, "//\\1:#{SANITIZED_PASSWORD}@")
          log_info "#{method.to_s.upcase} #{sanitized_url} " \
                   "[status:#{response.status}, request:#{format('%.3fs', duration)}, query:#{took}]"
          log_debug "> #{__convert_to_json(body)}" if body
          log_debug "< #{response.body}"
        end

        # Trace the request in the `curl` format
        #
        # @api private
        #
        def __trace(method, path, params, headers, body, _url, response, json, _took, duration)
          trace_url  = "http://localhost:9200/#{path}?pretty" +
                       (params.empty? ? '' : "&#{::Faraday::Utils::ParamsHash[params].to_query}")
          trace_body = body ? " -d '#{__convert_to_json(body, pretty: true)}'" : ''
          trace_command = "curl -X #{method.to_s.upcase}"
          trace_command += " -H '#{headers.collect { |k, v| "#{k}: #{v}" }.join(', ')}'" if headers && !headers.empty?
          trace_command += " '#{trace_url}'#{trace_body}\n"
          tracer.info trace_command
          tracer.debug "# #{Time.now.iso8601} [#{response.status}] (#{format('%.3f', duration)}s)\n#"
          return "# #{response.body}\n" unless tracer.debug json
          "#{serializer.dump(json, pretty: true).gsub(/^/, '# ').sub(/\}$/, "\n# }")}\n"
        end

        # Raise error specific for the HTTP response status or a generic server error
        #
        # @api private
        #
        def __raise_transport_error(response)
          error = ERRORS[response.status] || ServerError
          raise error, "[#{response.status}] #{response.body}"
        end

        # Converts any non-String object to JSON
        #
        # @api private
        #
        def __convert_to_json(obj = nil, options = {})
          obj.is_a?(String) ? obj : serializer.dump(obj, options)
        end

        # Returns a full URL based on information from host
        #
        # @param host [Hash] Host configuration passed in from {Client}
        #
        # @api private
        def __full_url(host)
          url  = "#{host[:protocol]}://"
          url += "#{CGI.escape(host[:user])}:#{CGI.escape(host[:password])}@" if host[:user]
          url += host[:host]
          url += ":#{host[:port]}" if host[:port]
          url += host[:path] if host[:path]
          url
        end

        # Performs a request to Elasticsearch, while handling logging, tracing, marking dead connections,
        # retrying the request and reloading the connections.
        #
        # @abstract The transport implementation has to implement this method either in full,
        #           or by invoking this method with a block. See {HTTP::Faraday#perform_request} for an example.
        #
        # @param method [String] Request method
        # @param path   [String] The API endpoint
        # @param params [Hash]   Request parameters (will be serialized by {Connections::Connection#full_url})
        # @param body   [Hash]   Request body (will be serialized by the {#serializer})
        # @param headers [Hash]   Request headers (will be serialized by the {#serializer})
        # @param block  [Proc]   Code block to evaluate, passed from the implementation
        #
        # @return [Response]
        # @raise  [NoMethodError] If no block is passed
        # @raise  [ServerError]   If request failed on server
        # @raise  [Error]         If no connection is available
        #
        def perform_request(method, path, params = {}, body = nil, _headers = nil, opts = {}, &block)
          raise NoMethodError, 'Implement this method in your transport class' unless block_given?

          start = Time.now
          tries = 0
          reload_on_failure = opts.fetch(:reload_on_failure, @options[:reload_on_failure])

          max_retries = if opts.key?(:retry_on_failure)
                          opts[:retry_on_failure] == true ? DEFAULT_MAX_RETRIES : opts[:retry_on_failure]
                        elsif options.key?(:retry_on_failure)
                          options[:retry_on_failure] == true ? DEFAULT_MAX_RETRIES : options[:retry_on_failure]
                        end

          params = params.clone

          ignore = Array(params.delete(:ignore)).compact.map(&:to_i)

          begin
            tries     += 1
            connection = get_connection or raise(Error, 'Cannot get new connection from pool.')

            if connection.connection.respond_to?(:params) && connection.connection.params.respond_to?(:to_hash)
              params = connection.connection.params.merge(params.to_hash)
            end

            url      = connection.full_url(path, params)

            response = block.call(connection, url)

            connection.healthy! if connection.failures.positive?

            # Raise an exception so we can catch it for `retry_on_status`
            if response.status.to_i >= 300 && @retry_on_status.include?(response.status.to_i)
              __raise_transport_error(response)
            end
          rescue OpenSearch::Transport::Transport::ServerError => e
            raise e unless response && @retry_on_status.include?(response.status)
            log_warn "[#{e.class}] Attempt #{tries} to get response from #{url}"
            if tries <= (max_retries || DEFAULT_MAX_RETRIES)
              retry
            else
              log_fatal "[#{e.class}] Cannot get response from #{url} after #{tries} tries"
              raise e
            end
          rescue *host_unreachable_exceptions => e
            log_error "[#{e.class}] #{e.message} #{connection.host.inspect}"

            connection.dead!

            if reload_on_failure && (tries < connections.all.size)
              log_warn "[#{e.class}] Reloading connections (attempt #{tries} of #{connections.all.size})"
              reload_connections! and retry
            end

            raise e unless max_retries
            log_warn "[#{e.class}] Attempt #{tries} connecting to #{connection.host.inspect}"
            if tries <= max_retries
              retry
            else
              log_fatal "[#{e.class}] Cannot connect to #{connection.host.inspect} after #{tries} tries"
              raise e
            end
          rescue StandardError => e
            log_fatal "[#{e.class}] #{e.message} (#{connection.host.inspect if connection})"
            raise e
          end

          duration = Time.now - start

          if response.status.to_i >= 300
            __log_response method, path, params, body, url, response, nil, 'N/A', duration
            if tracer
              __trace method, path, params, connection.connection.headers, body, url, response, nil, 'N/A',
                      duration
            end

            # Log the failure only when `ignore` doesn't match the response status
            log_fatal "[#{response.status}] #{response.body}" unless ignore.include?(response.status.to_i)

            __raise_transport_error response unless ignore.include?(response.status.to_i)
          end

          if response.body && !response.body.empty? && response.headers && response.headers['content-type'] =~ /json/
            json = serializer.load(response.body)
          end
          took = begin
            (json['took'] ? format('%.3fs', json['took'] / 1000.0) : 'n/a')
          rescue StandardError
            'n/a'
          end

          unless ignore.include?(response.status.to_i)
            __log_response method, path, params, body, url, response, json, took, duration
          end

          if tracer
            __trace method, path, params, connection.connection.headers, body, url, response, nil, 'N/A',
                    duration
          end

          warnings(response.headers['warning']) if response.headers&.[]('warning')

          Response.new response.status, json || response.body, response.headers
        ensure
          @last_request_at = Time.now
        end

        # @abstract Returns an Array of connection errors specific to the transport implementation.
        #           See {HTTP::Faraday#host_unreachable_exceptions} for an example.
        #
        # @return [Array]
        #
        def host_unreachable_exceptions
          [Errno::ECONNREFUSED]
        end

        private

        USER_AGENT_STR = 'User-Agent'.freeze
        USER_AGENT_REGEX = /user-?_?agent/
        CONTENT_TYPE_STR = 'Content-Type'.freeze
        CONTENT_TYPE_REGEX = /content-?_?type/
        DEFAULT_CONTENT_TYPE = 'application/json'.freeze
        GZIP = 'gzip'.freeze
        ACCEPT_ENCODING = 'Accept-Encoding'.freeze
        GZIP_FIRST_TWO_BYTES = '1f8b'.freeze
        HEX_STRING_DIRECTIVE = 'H*'.freeze
        RUBY_ENCODING = '1.9'.respond_to?(:force_encoding)

        def decompress_response(body)
          return body unless use_compression?
          return body unless gzipped?(body)

          io = StringIO.new(body)
          gzip_reader = if RUBY_ENCODING
                          Zlib::GzipReader.new(io, encoding: 'ASCII-8BIT')
                        else
                          Zlib::GzipReader.new(io)
                        end
          gzip_reader.read
        end

        def gzipped?(body)
          body[0..1].unpack1(HEX_STRING_DIRECTIVE) == GZIP_FIRST_TWO_BYTES
        end

        def use_compression?
          @compression
        end

        def apply_headers(client, options)
          headers = options[:headers] || {}
          headers[CONTENT_TYPE_STR] = find_value(headers, CONTENT_TYPE_REGEX) || DEFAULT_CONTENT_TYPE
          headers[USER_AGENT_STR] = find_value(headers, USER_AGENT_REGEX) || user_agent_header(client)
          client.headers[ACCEPT_ENCODING] = GZIP if use_compression?
          client.headers.merge!(headers)
        end

        def find_value(hash, regex)
          key_value = hash.find { |k, _v| k.to_s.downcase =~ regex }
          return unless key_value
          hash.delete(key_value[0])
          key_value[1]
        end

        def user_agent_header(_client)
          @user_agent_header ||= begin
            meta = ["RUBY_VERSION: #{RUBY_VERSION}"]
            if RbConfig::CONFIG && RbConfig::CONFIG['host_os']
              meta << "#{RbConfig::CONFIG['host_os'].split('_').first[/[a-z]+/i].downcase} #{RbConfig::CONFIG['target_cpu']}"
            end
            "opensearch-ruby/#{VERSION} (#{meta.join('; ')})"
          end
        end

        def warnings(warning)
          warn("warning: #{warning}")
        end
      end
    end
  end
end
