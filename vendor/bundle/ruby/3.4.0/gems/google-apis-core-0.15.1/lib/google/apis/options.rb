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

module Google
  module Apis
    # General options for API requests
    ClientOptions = Struct.new(
      :application_name,
      :application_version,
      :proxy_url,
      :open_timeout_sec,
      :read_timeout_sec,
      :send_timeout_sec,
      :log_http_requests,
      :transparent_gzip_decompression)

    RequestOptions = Struct.new(
      :authorization,
      :retries,
      :max_elapsed_time,
      :base_interval,
      :max_interval,
      :multiplier,
      :header,
      :normalize_unicode,
      :skip_serialization,
      :skip_deserialization,
      :api_format_version,
      :use_opencensus,
      :quota_project,
      :query,
      :add_invocation_id_header,
      :upload_chunk_size)

    # General client options
    class ClientOptions
      # @!attribute [rw] application_name
      #   @return [String] Name of the application, for identification in the User-Agent header
      # @!attribute [rw] application_version
      #   @return [String] Version of the application, for identification in the User-Agent header
      # @!attribute [rw] proxy_url
      #   @return [String] URL of a proxy server
      # @!attribute [rw] log_http_requests
      #   @return [Boolean] True if raw HTTP requests should be logged
      # @!attribute [rw] open_timeout_sec
      #   @return [Integer] How long, in seconds, before failed connections time out
      # @!attribute [rw] send_timeout_sec
      #   @return [Integer] How long, in seconds, before sending data times out
      # @!attribute [rw] read_timeout_sec
      #   @return [Integer] How long, in seconds, before receiving data times out
      # @!attribute [rw] transparent_gzip_decompression
      # @return [Boolean] True if gzip compression needs to be enabled
      # Get the default options
      # @return [Google::Apis::ClientOptions]
      def self.default
        @options ||= ClientOptions.new
      end
    end

    # Request options
    class RequestOptions
      # @!attribute [rw] authorization
      #   @return [Signet::OAuth2::Client, #apply(Hash)] OAuth2 credentials.
      # @!attribute [rw] retries
      #   @return [Integer] Number of times to retry requests on server error.
      # @!attribute [rw] max_elapsed_time
      #   @return [Integer] Total time in seconds that requests are allowed to keep being retried.
      # @!attribute [rw] base_interval
      #   @return [Float] The initial interval in seconds between tries.
      # @!attribute [rw] max_interval
      #   @return [Integer] The maximum interval in seconds that any individual retry can reach.
      # @!attribute [rw] multiplier
      #   @return [Numeric] Each successive interval grows by this factor. A multipler of 1.5 means the next interval 
      #              will be 1.5x the current interval.
      # @!attribute [rw] header
      #   @return [Hash<String,String>] Additional HTTP headers to include in requests.
      # @!attribute [rw] normalize_unicode
      #   @return [Boolean] True if unicode strings should be normalized in path parameters.
      # @!attribute [rw] skip_serialization
      #   @return [Boolean] True if body object should be treated as raw text instead of an object.
      # @!attribute [rw] skip_deserialization
      #   @return [Boolean] True if response should be returned in raw form instead of deserialized.
      # @!attribute [rw] api_format_version
      #   @return [Integer] Version of the error format to request/expect.
      # @!attribute [rw] use_opencensus
      #   @return [Boolean] Whether OpenCensus spans should be generated for requests. Default is true.
      # @!attribute [rw] quota_project
      #   @return [String] Project ID to charge quota, or `nil` to default to the credentials-specified project.
      # @!attribute [rw] query
      #   @return [Hash<String,String>] Additional HTTP URL query parameters to include in requests.
      # @!attribute [rw] add_invocation_id_header
      #   @return [Boolean] True if the header gccl-invocation-id need to be set
      # @!attribute [rw] upload_chunk_size
      #   @return [Integer] The chunk size of storage upload. The default value is 100 MB.

      # Get the default options
      # @return [Google::Apis::RequestOptions]
      def self.default
        @options ||= RequestOptions.new
      end

      def merge(options)
        return self if options.nil?

        new_options = dup
        members.each do |opt|
          opt = opt.to_sym
          new_options[opt] = options[opt] unless options[opt].nil?
        end
        new_options
      end
    end

    ClientOptions.default.log_http_requests = false
    ClientOptions.default.application_name = 'unknown'
    ClientOptions.default.application_version = '0.0.0'
    ClientOptions.default.transparent_gzip_decompression = true
    RequestOptions.default.retries = 0
    RequestOptions.default.max_elapsed_time = 900
    RequestOptions.default.base_interval = 1
    RequestOptions.default.max_interval = 60
    RequestOptions.default.multiplier = 2
    RequestOptions.default.normalize_unicode = false
    RequestOptions.default.skip_serialization = false
    RequestOptions.default.skip_deserialization = false
    RequestOptions.default.api_format_version = nil
    RequestOptions.default.use_opencensus = true
    RequestOptions.default.quota_project = nil
    RequestOptions.default.add_invocation_id_header = false
    RequestOptions.default.upload_chunk_size = 100 * 1024 * 1024 # 100 MB
  end
end
