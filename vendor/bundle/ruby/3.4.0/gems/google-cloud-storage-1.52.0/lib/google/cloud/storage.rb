# Copyright 2014 Google LLC
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


require "google-cloud-storage"
require "google/cloud/storage/project"
require "google/cloud/config"
require "google/cloud/env"

module Google
  module Cloud
    ##
    # # Google Cloud Storage
    #
    # Google Cloud Storage is an Internet service to store data in Google's
    # cloud. It allows world-wide storage and retrieval of any amount of data
    # and at any time, taking advantage of Google's own reliable and fast
    # networking infrastructure to perform data operations in a cost effective
    # manner.
    #
    # See {file:OVERVIEW.md Storage Overview}.
    #
    module Storage
      ##
      # Creates a new object for connecting to the Storage service.
      # Each call creates a new connection.
      #
      # For more information on connecting to Google Cloud see the
      # {file:AUTHENTICATION.md Authentication Guide}.
      #
      # @param [String] project_id Project identifier for the Storage service
      #   you are connecting to. If not present, the default project for the
      #   credentials is used.
      # @param [String, Hash, Google::Auth::Credentials] credentials The path to
      #   the keyfile as a String, the contents of the keyfile as a Hash, or a
      #   Google::Auth::Credentials object. (See {Storage::Credentials})
      # @param [String, Array<String>] scope The OAuth 2.0 scopes controlling
      #   the set of resources and operations that the connection can access.
      #   See [Using OAuth 2.0 to Access Google
      #   APIs](https://developers.google.com/identity/protocols/OAuth2).
      #
      #   The default scope is:
      #
      #   * `https://www.googleapis.com/auth/devstorage.full_control`
      # @param [Integer] retries Number of times to retry requests on server
      #   error. The default value is `3`. Optional.
      # @param [Integer] max_elapsed_time Total time in seconds that requests are allowed to keep being retried.
      # @param [Float] base_interval The initial interval in seconds between tries.
      # @param [Integer] max_interval The maximum interval in seconds that any individual retry can reach.
      # @param [Integer] multiplier Each successive interval grows by this factor. A multipler of 1.5 means the next
      #                  interval will be 1.5x the current interval.
      # @param [Integer] timeout (default timeout) The max duration, in seconds, to wait before timing out. Optional.
      #    If left blank, the wait will be at most the time permitted by the underlying HTTP/RPC protocol.
      # @param [Integer] open_timeout How long, in seconds, before failed connections time out. Optional.
      # @param [Integer] read_timeout How long, in seconds, before requests time out. Optional.
      # @param [Integer] send_timeout How long, in seconds, before receiving response from server times out. Optional.
      # @param [String] endpoint Override of the endpoint host name. Optional.
      #   If the param is nil, uses the default endpoint.
      # @param universe_domain [String] Override of the universe domain. Optional.
      #   If unset or nil, uses the default unvierse domain
      # @param [Integer] upload_chunk_size The chunk size of storage upload, in bytes.
      #                  The default value is 100 MB, i.e. 104_857_600 bytes. To disable chunking and upload
      #                  the complete file regardless of size, pass 0 as the chunk size.
      # @param [String] project Alias for the `project_id` argument. Deprecated.
      # @param [String] keyfile Alias for the `credentials` argument.
      #   Deprecated.
      #
      # @return [Google::Cloud::Storage::Project]
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new(
      #     project_id: "my-project",
      #     credentials: "/path/to/keyfile.json"
      #   )
      #
      #   bucket = storage.bucket "my-bucket"
      #   file = bucket.file "path/to/my-file.ext"
      #
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      def self.new project_id: nil, credentials: nil, scope: nil, retries: nil,
                   timeout: nil, open_timeout: nil, read_timeout: nil,
                   send_timeout: nil, endpoint: nil, project: nil, keyfile: nil,
                   max_elapsed_time: nil, base_interval: nil, max_interval: nil,
                   multiplier: nil, upload_chunk_size: nil, universe_domain: nil
        scope             ||= configure.scope
        retries           ||= configure.retries
        timeout           ||= configure.timeout
        open_timeout      ||= (configure.open_timeout || timeout)
        read_timeout      ||= (configure.read_timeout || timeout)
        send_timeout      ||= (configure.send_timeout || timeout)
        endpoint          ||= configure.endpoint
        credentials       ||= (keyfile || default_credentials(scope: scope))
        max_elapsed_time  ||= configure.max_elapsed_time
        base_interval     ||= configure.base_interval
        max_interval      ||= configure.max_interval
        multiplier        ||= configure.multiplier
        upload_chunk_size ||= configure.upload_chunk_size
        universe_domain   ||= configure.universe_domain

        unless credentials.is_a? Google::Auth::Credentials
          credentials = Storage::Credentials.new credentials, scope: scope
        end

        project_id = resolve_project_id(project_id || project, credentials)
        raise ArgumentError, "project_id is missing" if project_id.empty?

        Storage::Project.new(
          Storage::Service.new(
            project_id, credentials,
            retries: retries, timeout: timeout, open_timeout: open_timeout,
            read_timeout: read_timeout, send_timeout: send_timeout,
            host: endpoint, quota_project: configure.quota_project,
            max_elapsed_time: max_elapsed_time, base_interval: base_interval,
            max_interval: max_interval, multiplier: multiplier, upload_chunk_size: upload_chunk_size,
            universe_domain: universe_domain
          )
        )
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

      ##
      # Creates an unauthenticated, anonymous client for retrieving public data
      # from the Storage service. Each call creates a new connection.
      #
      # @param [Integer] retries Number of times to retry requests on server
      #   error. The default value is `3`. Optional.
      # @param [Integer] max_elapsed_time Total time in seconds that requests are allowed to keep being retried.
      # @param [Float] base_interval The initial interval in seconds between tries.
      # @param [Integer] max_interval The maximum interval in seconds that any individual retry can reach.
      # @param [Integer] multiplier Each successive interval grows by this factor. A multipler of 1.5 means the next
      #                  interval will be 1.5x the current interval.
      # @param [Integer] timeout (default timeout) The max duration, in seconds, to wait before timing out. Optional.
      #    If left blank, the wait will be at most the time permitted by the underlying HTTP/RPC protocol.
      # @param [Integer] open_timeout How long, in seconds, before failed connections time out. Optional.
      # @param [Integer] read_timeout How long, in seconds, before requests time out. Optional.
      # @param [Integer] send_timeout How long, in seconds, before receiving response from server times out. Optional.
      # @param [String] endpoint Override of the endpoint host name. Optional.
      #   If the param is nil, uses the default endpoint.
      # @param universe_domain [String] Override of the universe domain. Optional.
      #   If unset or nil, uses the default unvierse domain
      # @param [Integer] upload_chunk_size The chunk size of storage upload, in bytes.
      #                  The default value is 100 MB, i.e. 104_857_600 bytes. To disable chunking and upload
      #                  the complete file regardless of size, pass 0 as the chunk size.
      #
      # @return [Google::Cloud::Storage::Project]
      #
      # @example Use `skip_lookup` to avoid retrieving non-public metadata:
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.anonymous
      #
      #   bucket = storage.bucket "public-bucket", skip_lookup: true
      #   file = bucket.file "path/to/public-file.ext", skip_lookup: true
      #
      #   downloaded = file.download
      #   downloaded.rewind
      #   downloaded.read #=> "Hello world!"
      #
      def self.anonymous retries: nil, timeout: nil, open_timeout: nil,
                         read_timeout: nil, send_timeout: nil, endpoint: nil,
                         max_elapsed_time: nil, base_interval: nil, max_interval: nil,
                         multiplier: nil, upload_chunk_size: nil, universe_domain: nil
        open_timeout ||= timeout
        read_timeout ||= timeout
        send_timeout ||= timeout
        Storage::Project.new(
          Storage::Service.new(
            nil, nil, retries: retries, timeout: timeout, open_timeout: open_timeout,
            read_timeout: read_timeout, send_timeout: send_timeout, host: endpoint,
            max_elapsed_time: max_elapsed_time, base_interval: base_interval,
            max_interval: max_interval, multiplier: multiplier, upload_chunk_size: upload_chunk_size,
            universe_domain: universe_domain
          )
        )
      end

      ##
      # Configure the Google Cloud Storage library.
      #
      # The following Storage configuration parameters are supported:
      #
      # * `project_id` - (String) Identifier for a Storage project. (The
      #   parameter `project` is considered deprecated, but may also be used.)
      # * `credentials` - (String, Hash, Google::Auth::Credentials) The path to
      #   the keyfile as a String, the contents of the keyfile as a Hash, or a
      #   Google::Auth::Credentials object. (See {Storage::Credentials}) (The
      #   parameter `keyfile` is considered deprecated, but may also be used.)
      # * `endpoint` - (String) Override of the endpoint host name, or `nil`
      #   to use the default endpoint.
      # * `scope` - (String, Array<String>) The OAuth 2.0 scopes controlling
      #   the set of resources and operations that the connection can access.
      # * `retries` - (Integer) Number of times to retry requests on server
      #   error.
      # * `max_elapsed_time` - (Integer) Total time in seconds that requests
      #    are allowed to keep being retried.
      # * `base_interval` - (Float) The initial interval in seconds between tries.
      # * `max_interval` - (Integer) The maximum interval in seconds that any
      #   individual retry can reach.
      # * `multiplier` - (Integer) Each successive interval grows by this factor.
      #    A multipler of 1.5 means the next interval will be 1.5x the current interval.
      # * `timeout` - (Integer) (default timeout) The max duration, in seconds, to wait before timing out.
      #       If left blank, the wait will be at most the time permitted by the underlying HTTP/RPC protocol.
      # * `open_timeout` - (Integer) How long, in seconds, before failed connections time out.
      # * `read_timeout` - (Integer) How long, in seconds, before requests time out.
      # * `send_timeout` - (Integer) How long, in seconds, before receiving response from server times out.
      # * `upload_chunk_size` - (Integer) The chunk size of storage upload, in bytes.
      #
      # @return [Google::Cloud::Config] The configuration object the
      #   Google::Cloud::Storage library uses.
      #
      def self.configure
        yield Google::Cloud.configure.storage if block_given?

        Google::Cloud.configure.storage
      end

      ##
      # @private Resolve project.
      def self.resolve_project_id given_project, credentials
        project_id = given_project || default_project_id
        if credentials.respond_to? :project_id
          project_id ||= credentials.project_id
        end
        project_id.to_s # Always cast to a string
      end

      ##
      # @private Default project.
      def self.default_project_id
        Google::Cloud.configure.storage.project_id ||
          Google::Cloud.configure.project_id ||
          Google::Cloud.env.project_id
      end

      ##
      # @private Default credentials.
      def self.default_credentials scope: nil
        Google::Cloud.configure.storage.credentials ||
          Google::Cloud.configure.credentials ||
          Storage::Credentials.default(scope: scope)
      end
    end
  end
end
