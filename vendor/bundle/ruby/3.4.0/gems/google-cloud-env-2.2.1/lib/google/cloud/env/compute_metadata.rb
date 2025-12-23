# frozen_string_literal: true

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "faraday"
require "json"

require "google/cloud/env/compute_smbios"
require "google/cloud/env/lazy_value"
require "google/cloud/env/variables"

module Google
  module Cloud
    class Env
      ##
      # A client for the Google metadata service.
      #
      class ComputeMetadata
        ##
        # The default host for the metadata server
        # @return [String]
        #
        DEFAULT_HOST = "http://169.254.169.254"

        ##
        # The default timeout in seconds for opening http connections
        # @return [Numeric]
        #
        DEFAULT_OPEN_TIMEOUT = 0.1

        ##
        # The default timeout in seconds for request responses
        # @return [Numeric]
        #
        DEFAULT_REQUEST_TIMEOUT = 0.5

        ##
        # The default number of retries
        # @return [Integer]
        #
        DEFAULT_RETRY_COUNT = 2

        ##
        # The default timeout across retries
        # @return [nil]
        #
        DEFAULT_RETRY_TIMEOUT = nil

        ##
        # The default interval between retries, in seconds
        # @return [Numeric]
        #
        DEFAULT_RETRY_INTERVAL = 0.5

        ##
        # The default time in seconds to wait for environment warmup.
        # @return [Numeric]
        #
        DEFAULT_WARMUP_TIME = 60

        ##
        # @private
        # The base path of metadata server queries.
        # @return [String]
        #
        PATH_BASE = "/computeMetadata/v1"

        ##
        # @private
        # The standard set of headers
        # @return [Hash{String=>String}]
        #
        FLAVOR_HEADER = { "Metadata-Flavor" => "Google" }.freeze

        ##
        # Basic HTTP response object, returned by
        # {ComputeMetadata#lookup_response}.
        #
        # This object duck-types the `status`, `body`, and `headers` fields of
        # `Faraday::Response`. It also includes the CLOCK_MONOTONIC time when
        # the data was retrieved.
        #
        class Response
          ##
          # Create a response object.
          #
          # @param status [Integer] The HTTP status, normally 200
          # @param body [String] The HTTP body as a string
          # @param headers [Hash{String=>String}] The HTTP response headers.
          #     Normally, the `Metadata-Flavor` header must be set to the value
          #     `Google`.
          #
          def initialize status, body, headers
            @status = status
            @body = body
            @headers = headers
            @retrieval_monotonic_time = Process.clock_gettime Process::CLOCK_MONOTONIC
          end

          ##
          # The HTTP status code
          # @return [Integer]
          #
          attr_reader :status

          ##
          # The HTTP response body
          # @return [String]
          #
          attr_reader :body

          ##
          # The HTTP response headers
          # @return [Hash{String=>String}]
          #
          attr_reader :headers

          # The CLOCK_MONOTONIC time at which this response was retrieved.
          # @return [Numeric]
          #
          attr_reader :retrieval_monotonic_time

          ##
          # Returns true if the metadata-flavor is correct for Google Cloud
          # @return [boolean]
          #
          def google_flavor?
            headers["Metadata-Flavor"] == "Google"
          end
        end

        ##
        # A set of overrides for metadata access. This is used in
        # {ComputeMetadata#overrides=} and {ComputeMetadata#with_overrides}.
        # Generally, you should create and populate an overrides object, then
        # set it using one of those methods.
        #
        # An empty overrides object that contains no data is interpreted as a
        # metadata server that does not respond and raises
        # MetadataServerNotResponding. Otherwise, the overrides specifies what
        # responses are returned for specified queries, and any query not
        # explicitly set will result in a 404.
        #
        class Overrides
          ##
          # Create an empty overrides object.
          #
          def initialize
            clear
          end

          ##
          # Add an override to the object, providing a full response.
          #
          # @param path [String] The key path (e.g. `project/project-id`)
          # @param response [Response] The response object to return.
          # @param query [Hash{String => String}] Any additional query
          #     parameters for the request.
          #
          # @return [self] for chaining
          #
          def add_response path, response, query: nil
            @data[[path, query || {}]] = response
            self
          end

          ##
          # Add an override to the object, providing just a body string.
          #
          # @param path [String] The key path (e.g. `project/project-id`)
          # @param string [String] The response string to return.
          # @param query [Hash{String => String}] Any additional query
          #     parameters for the request.
          #
          # @return [self] for chaining
          #
          def add path, string, query: nil, headers: nil
            headers = (headers || {}).merge FLAVOR_HEADER
            response = Response.new 200, string, headers
            add_response path, response, query: query
          end

          ##
          # Add an override for the ping request.
          #
          # @return [self] for chaining
          #
          def add_ping
            add nil, "computeMetadata/\n"
          end

          ##
          # Clear all data from these overrides
          #
          # @return [self] for chaining
          #
          def clear
            @data = {}
            self
          end

          ##
          # Look up a response from the override data.
          #
          # @param path [String] The key path (e.g. `project/project-id`)
          # @param query [Hash{String => String}] Any additional query
          #     parameters for the request.
          #
          # @return [String] The response
          # @return [nil] if there is no data for the given query
          #
          def lookup path, query: nil
            @data[[path, query || {}]]
          end

          ##
          # Returns true if there is at least one override present
          #
          # @return [true, false]
          #
          def empty?
            @data.empty?
          end
        end

        ##
        # Create a compute metadata access object.
        #
        # @param variables [Google::Cloud::Env::Variables] Access object for
        #     environment variables. If not provided, a default is created.
        # @param compute_smbios [Google::Cloud::Env::ComputeSMBIOS] Access
        #     object for SMBIOS information. If not provided, a default is
        #     created.
        #
        def initialize variables: nil,
                       compute_smbios: nil
          @variables = variables || Variables.new
          @compute_smbios = compute_smbios || ComputeSMBIOS.new
          # This mutex protects the overrides and existence settings.
          # Those values won't change within a synchronize block.
          @mutex = Thread::Mutex.new
          reset!
        end

        ##
        # The host URL for the metadata server, including `http://`.
        #
        # @return [String]
        #
        attr_reader :host

        ##
        # The host URL for the metadata server, including `http://`.
        #
        # @param new_host [String]
        #
        def host= new_host
          new_host ||= @variables["GCE_METADATA_HOST"] || DEFAULT_HOST
          new_host = "http://#{new_host}" unless new_host.start_with? "http://"
          @host = new_host
        end

        ##
        # The default maximum number of times to retry a query for a key.
        # A value of 1 means 2 attempts (i.e. 1 retry). A value of nil means
        # there is no limit to the number of retries, although there could be
        # an overall timeout.
        #
        # Defaults to {DEFAULT_RETRY_COUNT}.
        #
        # @return [Integer,nil]
        #
        attr_accessor :retry_count

        ##
        # The default overall timeout across all retries of a lookup, in
        # seconds. A value of nil means there is no timeout, although there
        # could be a limit to the number of retries.
        #
        # Defaults to {DEFAULT_RETRY_TIMEOUT}.
        #
        # @return [Numeric,nil]
        #
        attr_accessor :retry_timeout

        ##
        # The time in seconds between retries. This time includes the time
        # spent by the previous attempt.
        #
        # Defaults to {DEFAULT_RETRY_INTERVAL}.
        #
        # @return [Numeric]
        #
        attr_accessor :retry_interval

        ##
        # A time in seconds allotted to environment warmup, during which
        # retries will not be ended. This handles certain environments in which
        # the Metadata Server might not be fully awake until some time after
        # application startup. A value of nil disables this warmup period.
        #
        # Defaults to {DEFAULT_WARMUP_TIME}.
        #
        # @return [Numeric,nil]
        #
        attr_accessor :warmup_time

        ##
        # The timeout for opening http connections in seconds.
        #
        # @return [Numeric]
        #
        def open_timeout
          connection.options.open_timeout
        end

        ##
        # The timeout for opening http connections in seconds.
        #
        # @param timeout [Numeric]
        #
        def open_timeout= timeout
          connection.options[:open_timeout] = timeout
        end

        ##
        # The total timeout for an HTTP request in seconds.
        #
        # @return [Numeric]
        #
        def request_timeout
          connection.options.timeout
        end

        ##
        # The total timeout for an HTTP request in seconds.
        #
        # @param timeout [Numeric]
        #
        def request_timeout= timeout
          connection.options[:timeout] = timeout
        end

        ##
        # Look up a particular key from the metadata server, and return a full
        # {Response} object. Could return a cached value if the key has been
        # queried before, otherwise this could block while trying to contact
        # the server through the given timeouts and retries.
        #
        # This returns a Response object even if the HTTP status is 404, so be
        # sure to check the status code to determine whether the key actually
        # exists. Unlike {#lookup}, this method does not return nil.
        #
        # @param path [String] The key path (e.g. `project/project-id`)
        # @param query [Hash{String => String}] Any additional query parameters
        #     to send with the request.
        # @param open_timeout [Numeric] Timeout for opening http connections.
        #     Defaults to {#open_timeout}.
        # @param request_timeout [Numeric] Timeout for entire http requests.
        #     Defaults to {#request_timeout}.
        # @param retry_count [Integer,nil] Number of times to retry. A value of
        #     1 means 2 attempts (i.e. 1 retry). A value of nil indicates
        #     retries are limited only by the timeout. Defaults to
        #     {#retry_count}.
        # @param retry_timeout [Numeric,nil] Total timeout for retries. A value
        #     of nil indicates no time limit, and retries are limited only by
        #     count. Defaults to {#retry_timeout}.
        #
        # @return [Response] the data from the metadata server
        # @raise [MetadataServerNotResponding] if the Metadata Server is not
        #     responding
        #
        def lookup_response path,
                            query: nil,
                            open_timeout: nil,
                            request_timeout: nil,
                            retry_count: :default,
                            retry_timeout: :default
          query = canonicalize_query query
          if @overrides
            @mutex.synchronize do
              return lookup_override path, query if @overrides
            end
          end
          raise MetadataServerNotResponding unless gce_check
          retry_count = self.retry_count if retry_count == :default
          retry_count += 1 if retry_count
          retry_timeout = self.retry_timeout if retry_timeout == :default
          @cache.await [path, query], open_timeout, request_timeout,
                       transient_errors: [MetadataServerNotResponding],
                       max_tries: retry_count,
                       max_time: retry_timeout
        end

        ##
        # Look up a particular key from the metadata server and return the data
        # as a string. Could return a cached value if the key has been queried
        # before, otherwise this could block while trying to contact the server
        # through the given timeouts and retries.
        #
        # This returns the HTTP body as a string, only if the call succeeds. If
        # the key is inaccessible or missing (i.e. the HTTP status was not 200)
        # or does not have the correct `Metadata-Flavor` header, then nil is
        # returned. If you need more detailed information, use
        # {#lookup_response}.
        #
        # @param path [String] The key path (e.g. `project/project-id`)
        # @param query [Hash{String => String}] Any additional query parameters
        #     to send with the request.
        # @param open_timeout [Numeric] Timeout for opening http connections.
        #     Defaults to {#open_timeout}.
        # @param request_timeout [Numeric] Timeout for entire http requests.
        #     Defaults to {#request_timeout}.
        # @param retry_count [Integer,nil] Number of times to retry. A value of
        #     1 means 2 attempts (i.e. 1 retry). A value of nil indicates
        #     retries are limited only by the timeout. Defaults to
        #     {#retry_count}.
        # @param retry_timeout [Numeric,nil] Total timeout for retries. A value
        #     of nil indicates no time limit, and retries are limited only by
        #     count. Defaults to {#retry_timeout}.
        #
        # @return [String] the data from the metadata server
        # @return [nil] if the key is not present
        # @raise [MetadataServerNotResponding] if the Metadata Server is not
        #     responding
        #
        def lookup path,
                   query: nil,
                   open_timeout: nil,
                   request_timeout: nil,
                   retry_count: :default,
                   retry_timeout: :default
          response = lookup_response path,
                                     query: query,
                                     open_timeout: open_timeout,
                                     request_timeout: request_timeout,
                                     retry_count: retry_count,
                                     retry_timeout: retry_timeout
          return nil unless response.status == 200 && response.google_flavor?
          response.body
        end

        ##
        # Return detailed information about whether we think Metadata is
        # available. If we have not previously confirmed existence one way or
        # another, this could block while trying to contact the server through
        # the given timeouts and retries.
        #
        # @param open_timeout [Numeric] Timeout for opening http connections.
        #     Defaults to {#open_timeout}.
        # @param request_timeout [Numeric] Timeout for entire http requests.
        #     Defaults to {#request_timeout}.
        # @param retry_count [Integer,nil] Number of times to retry. A value of
        #     1 means 2 attempts (i.e. 1 retry). A value of nil indicates
        #     retries are limited only by the timeout. Defaults to
        #     {#retry_count}.
        # @param retry_timeout [Numeric,nil] Total timeout for retries. A value
        #     of nil indicates no time limit, and retries are limited only by
        #     count. Defaults to {#retry_timeout}.
        #
        # @return [:no] if we know the metadata server is not present
        # @return [:unconfirmed] if we believe metadata should be present but we
        #     haven't gotten a confirmed response from it. This can happen if
        #     SMBIOS says we're on GCE but we can't contact the Metadata Server
        #     even through retries.
        # @return [:confirmed] if we have a confirmed response from metadata.
        #
        def check_existence open_timeout: nil,
                            request_timeout: nil,
                            retry_count: :default,
                            retry_timeout: :default
          current = @existence
          return current if [:no, :confirmed].include? @existence
          begin
            lookup nil,
                   open_timeout: open_timeout,
                   request_timeout: request_timeout,
                   retry_count: retry_count,
                   retry_timeout: retry_timeout
          rescue MetadataServerNotResponding
            # Do nothing
          end
          @existence
        end

        ##
        # The current detailed existence status, without blocking on any
        # attempt to contact the metadata server.
        #
        # @return [nil] if we have no information at all yet
        # @return [:no] if we know the metadata server is not present
        # @return [:unconfirmed] if we believe metadata should be present but we
        #     haven't gotten a confirmed response from it.
        # @return [:confirmed] if we have a confirmed response from metadata.
        #
        def existence_immediate
          @existence
        end

        ##
        # Assert that the Metadata Server should be present, and wait for a
        # confirmed connection to ensure it is up. This will generally run
        # at most {#warmup_time} seconds to wait out the expected maximum
        # warmup time, but a shorter timeout can be provided.
        #
        # @param timeout [Numeric,nil] a timeout in seconds, or nil to wait
        #     until we have conclusively decided one way or the other.
        # @return [:confirmed] if we were able to confirm connection.
        # @raise [MetadataServerNotResponding] if we were unable to confirm
        #     connection with the Metadata Server, either because the timeout
        #     expired or because the server seems to be down
        #
        def ensure_existence timeout: nil
          timeout ||= @startup_time + warmup_time - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          timeout = 1.0 if timeout < 1.0
          check_existence retry_count: nil, retry_timeout: timeout
          raise MetadataServerNotResponding unless @existence == :confirmed
          @existence
        end

        ##
        # Get the expiration time for the given path. Returns the monotonic
        # time if the data has been retrieved and has an expiration, nil if the
        # data has been retrieved but has no expiration, or false if the data
        # has not yet been retrieved.
        #
        # @return [Numeric,nil,false]
        #
        def expiration_time_of path, query: nil
          state = @cache.internal_state [path, query]
          return false unless state[0] == :success
          state[2]
        end

        ##
        # The overrides, or nil if overrides are not present.
        # If present, overrides will answer all metadata queries, and actual
        # calls to the metadata server will be blocked.
        #
        # @return [Overrides,nil]
        #
        attr_reader :overrides

        ##
        # Set the overrides. You can also set nil to disable overrides.
        # If present, overrides will answer all metadata queries, and actual
        # calls to the metadata server will be blocked.
        #
        # @param new_overrides [Overrides,nil]
        #
        def overrides= new_overrides
          @mutex.synchronize do
            @existence = nil
            @overrides = new_overrides
          end
        end

        ##
        # Run the given block with the overrides replaced with the given set
        # (or nil to disable overrides in the block). The original overrides
        # setting is restored at the end of the block. This is used for
        # debugging/testing/mocking.
        #
        # @param temp_overrides [Overrides,nil]
        #
        def with_overrides temp_overrides
          old_overrides, old_existence = @mutex.synchronize do
            [@overrides, @existence]
          end
          begin
            @mutex.synchronize do
              @existence = nil
              @overrides = temp_overrides
            end
            yield
          ensure
            @mutex.synchronize do
              @existence = old_existence
              @overrides = old_overrides
            end
          end
        end

        ##
        # @private
        # The underlying Faraday connection. Can be used to customize the
        # connection for testing.
        # @return [Faraday::Connection]
        #
        attr_reader :connection

        ##
        # @private
        # The underlying LazyDict. Can be used to customize the cache for
        # testing.
        # @return [Google::Cloud::Env::LazyDict]
        #
        attr_reader :cache

        ##
        # @private
        # The variables access object
        # @return [Google::Cloud::Env::Variables]
        #
        attr_reader :variables

        ##
        # @private
        # The compute SMBIOS access object
        # @return [Google::Cloud::Env::ComputeSMBIOS]
        #
        attr_reader :compute_smbios

        ##
        # @private
        # Reset the cache, overrides, and all settings to default, for testing.
        #
        def reset!
          @mutex.synchronize do
            self.host = nil
            @connection = Faraday.new url: host
            self.open_timeout = DEFAULT_OPEN_TIMEOUT
            self.request_timeout = DEFAULT_REQUEST_TIMEOUT
            self.retry_count = DEFAULT_RETRY_COUNT
            self.retry_timeout = DEFAULT_RETRY_TIMEOUT
            self.retry_interval = DEFAULT_RETRY_INTERVAL
            self.warmup_time = DEFAULT_WARMUP_TIME
            @cache = create_cache
            @overrides = nil
          end
          reset_existence!
        end

        ##
        # @private
        # Clear the existence cache, for testing.
        #
        def reset_existence!
          @mutex.synchronize do
            @existence = nil
            @startup_time = Process.clock_gettime Process::CLOCK_MONOTONIC
          end
          self
        end

        private

        ##
        # @private
        # A list of exceptions that are considered transient. They trigger a
        # retry if received from an HTTP attempt, and they are not cached (i.e.
        # the cache lifetime is set to 0.)
        #
        TRANSIENT_EXCEPTIONS = [
          Faraday::TimeoutError,
          Faraday::ConnectionFailed,
          Errno::EHOSTDOWN,
          Errno::ETIMEDOUT,
          Timeout::Error
        ].freeze

        ##
        # @private
        #
        # A buffer in seconds for token expiry. Our cache for the token will
        # expire approximately this many seconds before the declared expiry
        # time of the token itself.
        #
        # We want this value to be positive so that we provide some buffer to
        # offset any clock skew and Metadata Server latency that might affect
        # our calculation of the expiry time, but more importantly so that a
        # client has approximately this amount of time to use a token we give
        # them before it expires.
        #
        # We don't want this to be much higher, however, to keep the load down
        # on the Metadata Server. We've been advised by the compute/serverless
        # engineering teams to set this value less than 4 minutes because the
        # Metadata Server can refresh the token as late as 4 minutes before the
        # actual expiry of the previous token. If our cache expires and we
        # request a new token, we actually want to receive a new token rather
        # than the previous old token. See internal issue b/311414224.
        #
        TOKEN_EXPIRY_BUFFER = 210

        ##
        # @private
        #
        # Attempt to determine if we're on GCE (if we haven't previously), and
        # update the existence flag. Return true if we *could* be on GCE, or
        # false if we're definitely not.
        #
        def gce_check
          if @existence.nil?
            @mutex.synchronize do
              @existence ||=
                if @compute_smbios.google_compute? || maybe_gcf || maybe_gcr || maybe_gae
                  :unconfirmed
                else
                  :no
                end
            end
          end
          @existence != :no
        end

        # @private
        def maybe_gcf
          @variables["K_SERVICE"] && @variables["K_REVISION"] && @variables["GAE_RUNTIME"]
        end

        # @private
        def maybe_gcr
          @variables["K_SERVICE"] && @variables["K_REVISION"] && @variables["K_CONFIGURATION"]
        end

        # @private
        def maybe_gae
          @variables["GAE_SERVICE"] && @variables["GAE_RUNTIME"]
        end

        ##
        # @private
        # Create and return a new LazyDict cache for the metadata
        #
        def create_cache
          retries = proc do
            Google::Cloud::Env::Retries.new max_tries: nil,
                                            initial_delay: retry_interval,
                                            delay_includes_time_elapsed: true
          end
          Google::Cloud::Env::LazyDict.new retries: retries do |(path, query), open_timeout, request_timeout|
            internal_lookup path, query, open_timeout, request_timeout
          end
        end

        ##
        # @private
        # Look up the given path, without using the cache.
        #
        def internal_lookup path, query, open_timeout, request_timeout
          full_path = path ? "#{PATH_BASE}/#{path}" : ""
          http_response = connection.get full_path do |req|
            req.params = query if query
            req.headers = FLAVOR_HEADER
            req.options.timeout = request_timeout if request_timeout
            req.options.open_timeout = open_timeout if open_timeout
          end
          response = Response.new http_response.status, http_response.body, http_response.headers
          if path.nil?
            post_update_existence(response.status == 200 && response.google_flavor?, response.retrieval_monotonic_time)
          elsif response.google_flavor?
            post_update_existence true, response.retrieval_monotonic_time
          end
          lifetime = determine_data_lifetime path, response.body.strip
          LazyValue.expiring_value lifetime, response
        rescue *TRANSIENT_EXCEPTIONS
          post_update_existence false
          raise MetadataServerNotResponding
        end

        ##
        # @private
        # Update existence based on a received result
        #
        def post_update_existence success, current_time = nil
          return if @existence == :confirmed
          @mutex.synchronize do
            if success
              @existence = :confirmed
            elsif @existence != :confirmed
              current_time ||= Process.clock_gettime Process::CLOCK_MONOTONIC
              @existence = :no if current_time > @startup_time + warmup_time
            end
          end
        end

        ##
        # @private
        # Compute the lifetime of data, given the path and data. Returns the
        # value in seconds, or nil for nonexpiring data.
        #
        def determine_data_lifetime path, data
          case path
          when %r{instance/service-accounts/[^/]+/token}
            access_token_lifetime data
          when %r{instance/service-accounts/[^/]+/identity}
            identity_token_lifetime data
          end
        end

        ##
        # @private
        # Extract the lifetime of an access token
        #
        def access_token_lifetime data
          json = JSON.parse data rescue nil
          return 0 unless json.respond_to?(:key?) && json.key?("expires_in")
          lifetime = json["expires_in"].to_i - TOKEN_EXPIRY_BUFFER
          lifetime = 0 if lifetime.negative?
          lifetime
        end

        ##
        # @private
        # Extract the lifetime of an identity token
        #
        def identity_token_lifetime data
          return 0 unless data =~ /^[\w=-]+\.([\w=-]+)\.[\w=-]+$/
          base64 = Base64.urlsafe_decode64 Regexp.last_match[1]
          json = JSON.parse base64 rescue nil
          return 0 unless json.respond_to?(:key?) && json&.key?("exp")
          lifetime = json["exp"].to_i - Time.now.to_i - TOKEN_EXPIRY_BUFFER
          lifetime = 0 if lifetime.negative?
          lifetime
        end

        ##
        # @private
        # Stringify keys in a query hash
        #
        def canonicalize_query query
          query&.transform_keys(&:to_s)
        end

        ##
        # @private
        # Lookup from overrides and return the result or raise.
        # This must be called from within the mutex, and assumes that
        # overrides is non-nil.
        #
        def lookup_override path, query
          if @overrides.empty?
            @existence = :no
            raise MetadataServerNotResponding
          end
          @existence = :confirmed
          result = @overrides.lookup path, query: query
          result ||= Response.new 404, "Not found", FLAVOR_HEADER
          result
        end
      end

      ##
      # Error raised when the compute metadata server is expected to be
      # present in the current environment, but couldn't be contacted.
      #
      class MetadataServerNotResponding < StandardError
        ##
        # Default message for the error
        # @return [String]
        #
        DEFAULT_MESSAGE =
          "The Google Metadata Server did not respond to queries. This " \
          "could be because no Server is present, the Server has not yet " \
          "finished starting up, the Server is running but overloaded, or " \
          "Server could not be contacted due to networking issues."

        ##
        # Create a new MetadataServerNotResponding.
        #
        # @param message [String] Error message. If not provided, defaults to
        #     {DEFAULT_MESSAGE}.
        #
        def initialize message = nil
          message ||= DEFAULT_MESSAGE
          super message
        end
      end
    end
  end
end
