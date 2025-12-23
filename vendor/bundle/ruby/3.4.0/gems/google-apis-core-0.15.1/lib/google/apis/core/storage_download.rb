# Copyright 2022 Google LLC
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

require 'google/apis/core/api_command'
require 'google/apis/errors'
require 'addressable/uri'

module Google
  module Apis
    module Core
      # Streaming/resumable media download support specifically for storage API so that 
      # we can respond with response headers too.
      class StorageDownloadCommand < DownloadCommand

        # Execute the upload request once. Overrides the default implementation to handle streaming/chunking
        # of file content.
        # Note: This method is overridden from DownloadCommand in order to respond back with 
        # http header. All changes made to `execute_once` of DownloadCommand, should be made 
        # here too.
        #
        # @private
        # @param [HTTPClient] client
        #   HTTP client
        # @yield [result, err] Result or error if block supplied
        # @return [Object]
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def execute_once(client, &block)
          request_header = header.dup
          apply_request_options(request_header)
          download_offset = nil

          if @offset > 0
            logger.debug { sprintf('Resuming download from offset %d', @offset) }
            request_header[RANGE_HEADER] = sprintf('bytes=%d-', @offset)
          end

          http_res = client.get(url.to_s,
                     query: query,
                     header: request_header,
                     follow_redirect: true) do |res, chunk|
            status = res.http_header.status_code.to_i
            next unless OK_STATUS.include?(status)

            download_offset ||= (status == 206 ? @offset : 0)
            download_offset  += chunk.bytesize

            if download_offset - chunk.bytesize == @offset
              next_chunk = chunk
            else
              # Oh no! Requested a chunk, but received the entire content
              chunk_index = @offset - (download_offset - chunk.bytesize)
              next_chunk = chunk.byteslice(chunk_index..-1)
              next if next_chunk.nil?
            end

            # logger.debug { sprintf('Writing chunk (%d bytes, %d total)', chunk.length, bytes_read) }
            @download_io.write(next_chunk)

            @offset += next_chunk.bytesize
          end

         @download_io.flush if @download_io.respond_to?(:flush)

          if @close_io_on_finish
            result = nil
          else
            result = @download_io
          end
          check_status(http_res.status.to_i, http_res.header, http_res.body)
          # In case of file download in storage, we need to respond back with http 
          # header along with the actual object.
          success([result, http_res], &block)
        rescue => e
          @download_io.flush if @download_io.respond_to?(:flush)
          error(e, rethrow: true, &block)
        end
      end
    end
  end
end
