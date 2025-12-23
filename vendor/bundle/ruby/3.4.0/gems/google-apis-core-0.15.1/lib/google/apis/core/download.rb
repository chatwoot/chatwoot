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

require 'google/apis/core/api_command'
require 'google/apis/errors'
require 'addressable/uri'
require 'pathname'

module Google
  module Apis
    module Core
      # Streaming/resumable media download support
      class DownloadCommand < ApiCommand
        RANGE_HEADER = 'Range'
        OK_STATUS = [200, 201, 206]

        # File or IO to write content to
        # @return [String, File, #write]
        attr_accessor :download_dest

        # Ensure the download destination is a writable stream.
        #
        # @return [void]
        def prepare!
          @state = :start
          @download_url = nil
          @offset = 0
          if @download_dest.is_a?(Pathname)
            @download_io = File.open(download_dest, 'wb')
            @close_io_on_finish = true
          elsif download_dest.respond_to?(:write)
            @download_io = download_dest
            @close_io_on_finish = false
          elsif download_dest.is_a?(String)
            @download_io = File.open(download_dest, 'wb')
            @close_io_on_finish = true
          else
            @download_io = StringIO.new('', 'wb')
            @close_io_on_finish = false
          end
          super
        end

        # Close IO stream when command done. Only closes the stream if it was opened by the command.
        def release!
          @download_io.close if @close_io_on_finish
        end

        # Execute the upload request once. Overrides the default implementation to handle streaming/chunking
        # of file content.
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
          success(result, &block)
        rescue => e
          @download_io.flush if @download_io.respond_to?(:flush)
          error(e, rethrow: true, &block)
        end
      end
    end
  end
end
