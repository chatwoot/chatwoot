# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'addressable/uri'
require 'addressable/template'
require 'google/apis'
require 'google/apis/core/version'
require 'google/apis/core/api_command'
require 'google/apis/core/batch'
require 'google/apis/core/upload'
require 'google/apis/core/storage_upload'
require 'google/apis/core/download'
require 'google/apis/core/storage_download'
require 'google/apis/options'
require 'googleauth'
require 'httpclient'

module Google
  module Apis
    module Core
      # Helper class for enumerating over a result set requiring multiple fetches
      class PagedResults
        include Enumerable

        attr_reader :last_result

        # @param [BaseService] service
        #   Current service instance
        # @param [Fixnum] max
        #   Maximum number of items to iterate over. Nil if no limit
        # @param [Boolean] cache
        #  True (default) if results should be cached so multiple iterations can be used.
        # @param [Symbol] items
        #   Name of the field in the result containing the items. Defaults to :items
        def initialize(service, max: nil, items: :items, cache: true, response_page_token: :next_page_token, &block)
          @service = service
          @block = block
          @max = max
          @items_field = items
          @response_page_token_field = response_page_token
          if cache
            @result_cache = Hash.new do |h, k|
              h[k] = @block.call(k, @service)
            end
            @fetch_proc = Proc.new { |token| @result_cache[token] }
          else
            @fetch_proc = Proc.new { |token| @block.call(token, @service) }
          end
        end

        # Iterates over result set, fetching additional pages as needed
        def each
          page_token = nil
          item_count = 0
          loop do
            @last_result = @fetch_proc.call(page_token)
            items = @last_result.send(@items_field)
            if items.kind_of?(Array)
              for item in items
                item_count = item_count + 1
                break if @max && item_count > @max
                yield item
              end
            elsif items.kind_of?(Hash)
              items.each do |key, val|
                item_count = item_count + 1
                break if @max && item_count > @max
                yield key, val
              end
            elsif items
              # yield singular non-nil items (for genomics API)
              yield items
            end
            break if @max && item_count >= @max
            next_page_token = @last_result.send(@response_page_token_field)
            break if next_page_token.to_s.empty? || next_page_token == page_token
            page_token = next_page_token
          end
        end
      end

      # Base service for all APIs. Not to be used directly.
      #
      class BaseService
        ##
        # A substitution string for the universe domain in an endpoint template
        # @return [String]
        #
        ENDPOINT_SUBSTITUTION = "$UNIVERSE_DOMAIN$".freeze

        include Logging

        # Universe domain
        # @return [String]
        attr_reader :universe_domain

        # Set the universe domain.
        # If the root URL was set with a universe domain substitution, it is
        # updated to reflect the new universe domain.
        #
        # @param new_ud [String,nil] The new universe domain, or nil to use the Google Default Universe
        def universe_domain= new_ud
          new_ud ||= ENV["GOOGLE_CLOUD_UNIVERSE_DOMAIN"] || "googleapis.com"
          if @root_url_template
            @root_url = @root_url_template.gsub ENDPOINT_SUBSTITUTION, new_ud
          end
          @universe_domain = new_ud
        end

        # Root URL (host/port) for the API
        # @return [Addressable::URI, String]
        attr_reader :root_url

        # Set the root URL.
        # If the given url includes a universe domain substitution, it is
        # resolved in the current universe domain
        #
        # @param url_or_template [Addressable::URI, String] The URL, which can include a universe domain substitution
        def root_url= url_or_template
          if url_or_template.is_a?(String) && url_or_template.include?(ENDPOINT_SUBSTITUTION)
            @root_url_template = url_or_template
            @root_url = url_or_template.gsub ENDPOINT_SUBSTITUTION, universe_domain
          else
            @root_url_template = nil
            @root_url = url_or_template
          end
        end

        # Additional path prefix for all API methods
        # @return [Addressable::URI]
        attr_accessor :base_path

        # Alternate path prefix for media uploads
        # @return [Addressable::URI]
        attr_accessor :upload_path

        # Alternate path prefix for all batch methods
        # @return [Addressable::URI]
        attr_accessor :batch_path

        # HTTP client
        # @return [HTTPClient]
        attr_accessor :client

        # General settings
        # @return [Google::Apis::ClientOptions]
        attr_accessor :client_options

        # Default options for all requests
        # @return [Google::Apis::RequestOptions]
        attr_accessor :request_options

        # Client library name.
        # @return [String]
        attr_accessor :client_name

        # Client library version.
        # @return [String]
        attr_accessor :client_version

        # @param [String,Addressable::URI] root_url
        #   Root URL for the API
        # @param [String,Addressable::URI] base_path
        #   Additional path prefix for all API methods
        # @api private
        def initialize(root_url, base_path, client_name: nil, client_version: nil, universe_domain: nil)
          @root_url_template = nil
          self.universe_domain = universe_domain
          self.root_url = root_url
          self.base_path = base_path
          self.client_name = client_name || 'google-api-ruby-client'
          self.client_version = client_version || Google::Apis::Core::VERSION
          self.upload_path = "upload/#{base_path}"
          self.batch_path = 'batch'
          self.client_options = Google::Apis::ClientOptions.default.dup
          self.request_options = Google::Apis::RequestOptions.default.dup
        end

        # @!attribute [rw] authorization
        # @return [Signet::OAuth2::Client]
        #  OAuth2 credentials
        def authorization=(authorization)
          request_options.authorization = authorization
        end

        def authorization
          request_options.authorization
        end

        # TODO: with(options) method

        # Perform a batch request. Calls made within the block are sent in a single network
        # request to the server.
        #
        # @example
        #   service.batch do |s|
        #     s.get_item(id1) do |res, err|
        #       # process response for 1st call
        #     end
        #     # ...
        #     s.get_item(idN) do |res, err|
        #       # process response for Nth call
        #     end
        #   end
        #
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @yield [self]
        # @return [void]
        def batch(options = nil)
          batch_command = BatchCommand.new(:post, Addressable::URI.parse(root_url + batch_path))
          batch_command.options = request_options.merge(options)
          apply_command_defaults(batch_command)
          begin
            start_batch(batch_command)
            yield self
          ensure
            end_batch
          end
          batch_command.execute(client)
        end

        # Perform a batch upload request. Calls made within the block are sent in a single network
        # request to the server. Batch uploads are useful for uploading multiple small files. For larger
        # files, use single requests which use a resumable upload protocol.
        #
        # @example
        #   service.batch do |s|
        #     s.insert_item(upload_source: 'file1.txt') do |res, err|
        #       # process response for 1st call
        #     end
        #     # ...
        #     s.insert_item(upload_source: 'fileN.txt') do |res, err|
        #       # process response for Nth call
        #     end
        #   end
        #
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @yield [self]
        # @return [void]
        def batch_upload(options = nil)
          batch_command = BatchUploadCommand.new(:put, Addressable::URI.parse(root_url + upload_path))
          batch_command.options = request_options.merge(options)
          apply_command_defaults(batch_command)
          begin
            start_batch(batch_command)
            yield self
          ensure
            end_batch
          end
          batch_command.execute(client)
        end

        # Get the current HTTP client
        # @return [HTTPClient]
        def client
          @client ||= new_client
        end


        # Simple escape hatch for making API requests directly to a given
        # URL. This is not intended to be used as a generic HTTP client
        # and should be used only in cases where no service method exists
        # (e.g. fetching an export link for a Google Drive file.)
        #
        # @param [Symbol] method
        #   HTTP method as symbol (e.g. :get, :post, :put, ...)
        # @param [String] url
        #   URL to call
        # @param [Hash<String,String>] params
        #   Optional hash of query parameters
        # @param [#read] body
        #   Optional body for POST/PUT
        # @param [IO, String] download_dest
        #   IO stream or filename to receive content download
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [String] HTTP response body
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [String] HTTP response body
        def http(method, url, params: nil, body: nil, download_dest: nil, options: nil, &block)
          if download_dest
            command = DownloadCommand.new(method, url, body: body, client_version: client_version)
          else
            command = HttpCommand.new(method, url, body: body)
          end
          command.options = request_options.merge(options)
          apply_command_defaults(command)
          command.query.merge(Hash(params))
          execute_or_queue_command(command, &block)
        end

        # Executes a given query with paging, automatically retrieving
        # additional pages as necessary. Requires a block that returns the
        # result set of a page. The current page token is supplied as an argument
        # to the block.
        #
        # Note: The returned enumerable also contains a `last_result` field
        # containing the full result of the last query executed.
        #
        # @param [Fixnum] max
        #   Maximum number of items to iterate over. Defaults to nil -- no upper bound.
        # @param [Symbol] items
        #   Name of the field in the result containing the items. Defaults to :items
        # @param [Boolean] cache
        #  True (default) if results should be cached so multiple iterations can be used.
        # @return [Enumerable]
        # @yield [token, service]
        #   Current page token & service instance
        # @yieldparam [String] token
        #   Current page token to be used in the query
        # @yieldparam [service]
        #   Current service instance
        # @since 0.9.4
        #
        # @example Retrieve all files,
        #   file_list = service.fetch_all { |token, s| s.list_files(page_token: token) }
        #   file_list.each { |f| ... }
        def fetch_all(max: nil, items: :items, cache: true, response_page_token: :next_page_token, &block)
          fail "fetch_all may not be used inside a batch" if batch?
          return PagedResults.new(self, max: max, items: items, cache: cache, response_page_token: response_page_token, &block)
        end

        # Verify that the universe domain setting matches the universe domain
        # in the credentials, if present.
        #
        # @raise [Google::Apis::UniverseDomainError] if there is a mismatch
        def verify_universe_domain!
          auth = authorization
          auth_universe_domain = auth.universe_domain if auth.respond_to? :universe_domain
          if auth_universe_domain && auth_universe_domain != universe_domain
            raise UniverseDomainError,
                  "Universe domain is #{universe_domain} but credentials are in #{auth_universe_domain}"
          end
          true
        end

        protected

        # Create a new upload command.
        #
        # @param [symbol] method
        #   HTTP method for uploading (typically :put or :post)
        # @param [String] path
        #  Additional path to upload endpoint, appended to API base path
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @return [Google::Apis::Core::UploadCommand]
        def make_upload_command(method, path, options)
          verify_universe_domain!
          template = Addressable::Template.new(root_url + upload_path + path)
          if batch?
            command = MultipartUploadCommand.new(method, template, client_version: client_version)
          else
            command = ResumableUploadCommand.new(method, template, client_version: client_version)
          end
          command.options = request_options.merge(options)
          apply_command_defaults(command)
          command
        end

        # Create a new storage upload command.
        # This is specifically for storage because we are moving to a new upload protocol.
        # Ref: https://cloud.google.com/storage/docs/performing-resumable-uploads
        #
        # @param [Symbol] method
        #  HTTP method for uploading. The initial request to initiate a resumable session
        #  is :post and the subsequent chunks uploaded to the session are :put
        # @param [String] path
        #  Additional path to upload endpoint, appended to API base path
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @return [Google::Apis::Core::StorageUploadCommand]
        def make_storage_upload_command(method, path, options)
          verify_universe_domain!
          template = Addressable::Template.new(root_url + upload_path + path)
          command = StorageUploadCommand.new(method, template, client_version: client_version)
          command.options = request_options.merge(options)
          apply_command_defaults(command)
          command
        end

        # Create a new download command.
        #
        # @param [symbol] method
        #   HTTP method for uploading (typically :get)
        # @param [String] path
        #  Additional path to download endpoint, appended to API base path
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @return [Google::Apis::Core::DownloadCommand]
        def make_download_command(method, path, options)
          verify_universe_domain!
          template = Addressable::Template.new(root_url + base_path + path)
          command = DownloadCommand.new(method, template, client_version: client_version)
          command.options = request_options.merge(options)
          command.query['alt'] = 'media'
          apply_command_defaults(command)
          command
        end

        # Create a new storage download command. This is specifically for storage because
        # we want to return response header too in the response.
        #
        # @param [symbol] method
        #   HTTP method for uploading (typically :get)
        # @param [String] path
        #  Additional path to download endpoint, appended to API base path
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @return [Google::Apis::Core::StorageDownloadCommand]
        def make_storage_download_command(method, path, options)
          verify_universe_domain!
          template = Addressable::Template.new(root_url + base_path + path)
          command = StorageDownloadCommand.new(method, template, client_version: client_version)
          command.options = request_options.merge(options)
          command.query['alt'] = 'media'
          apply_command_defaults(command)
          command
        end

        # Create a new command.
        #
        # @param [symbol] method
        #   HTTP method (:get, :post, :delete, etc...)
        # @param [String] path
        #  Additional path, appended to API base path
        # @param [Hash, Google::Apis::RequestOptions] options
        #  Request-specific options
        # @return [Google::Apis::Core::DownloadCommand]
        def make_simple_command(method, path, options)
          verify_universe_domain!
          full_path =
            if path.start_with? "/"
              path[1..-1]
            else
              base_path + path
            end
          template = Addressable::Template.new(root_url + full_path)
          command = ApiCommand.new(method, template, client_version: client_version)
          command.options = request_options.merge(options)
          apply_command_defaults(command)
          command
        end

        # Execute the request. If a batch is in progress, the request is added to the batch instead.
        #
        # @param [Google::Apis::Core::HttpCommand] command
        #   Command to execute
        # @return [Object] response object if command executed and no callback supplied
        # @yield [result, err] Result & error if block supplied
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def execute_or_queue_command(command, &callback)
          batch_command = current_batch
          if batch_command
            fail "Can not combine services in a batch" if Thread.current[:google_api_batch_service] != self
            batch_command.add(command, &callback)
            nil
          else
            command.execute(client, &callback)
          end
        end

        # Update commands with service-specific options. To be implemented by subclasses
        # @param [Google::Apis::Core::HttpCommand] _command
        def apply_command_defaults(_command)
        end

        private

        # Get the current batch context
        #
        # @return [Google:Apis::Core::BatchRequest]
        def current_batch
          Thread.current[:google_api_batch]
        end

        # Check if a batch is in progress
        # @return [Boolean]
        def batch?
          !current_batch.nil?
        end

        # Start a new thread-local batch context
        # @param [Google::Apis::Core::BatchCommand] cmd
        def start_batch(cmd)
          fail "Batch already in progress" if batch?
          Thread.current[:google_api_batch] = cmd
          Thread.current[:google_api_batch_service] = self
        end

        # Clear thread-local batch context
        def end_batch
          Thread.current[:google_api_batch] = nil
          Thread.current[:google_api_batch_service] = nil
        end

        # Create a new HTTP client
        # @return [HTTPClient]
        def new_client
          client = ::HTTPClient.new

          if client_options.transparent_gzip_decompression
            client.transparent_gzip_decompression = client_options.transparent_gzip_decompression
          end
          
          client.proxy = client_options.proxy_url if client_options.proxy_url

          if client_options.open_timeout_sec
            client.connect_timeout = client_options.open_timeout_sec
          end

          if client_options.read_timeout_sec
            client.receive_timeout = client_options.read_timeout_sec
          end

          if client_options.send_timeout_sec
            client.send_timeout = client_options.send_timeout_sec
          end

          client.follow_redirect_count = 5
          client.default_header = { 'User-Agent' => user_agent }

          client.debug_dev = logger if client_options.log_http_requests

          # Make HttpClient use system default root CA path
          # https://github.com/nahi/httpclient/issues/445
          client.ssl_config.clear_cert_store
          client.ssl_config.cert_store.set_default_paths
          client
        end


        # Build the user agent header
        # @return [String]
        def user_agent
          sprintf('%s/%s %s/%s %s (gzip)',
                  client_options.application_name,
                  client_options.application_version,
                  client_name,
                  client_version,
                  Google::Apis::OS_VERSION)
        end
      end
    end
  end
end
