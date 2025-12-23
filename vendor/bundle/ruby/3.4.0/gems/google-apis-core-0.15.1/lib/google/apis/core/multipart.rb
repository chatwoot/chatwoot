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
    module Core
      # Part of a multipart request for holding JSON data
      #
      # @private
      class JsonPart

        # @param [String] value
        #   JSON content
        # @param [Hash] header
        #   Additional headers
        def initialize(value, header = {})
          @value = value
          @header = header
        end

        def to_io(boundary)
          part = ''
          part << "--#{boundary}\r\n"
          part << "Content-Type: application/json\r\n"
          @header.each do |(k, v)|
            part << "#{k}: #{v}\r\n"
          end
          part << "\r\n"
          part << "#{@value}\r\n"
          StringIO.new(part)
        end

      end

      # Part of a multipart request for holding arbitrary content.
      #
      # @private
      class FilePart
        # @param [IO] io
        #   IO stream
        # @param [Hash] header
        #   Additional headers
        def initialize(io, header = {})
          @io = io
          @header = header
          @length = io.respond_to?(:size) ? io.size : nil
        end

        def to_io(boundary)
          head = ''
          head << "--#{boundary}\r\n"
          @header.each do |(k, v)|
            head << "#{k}: #{v}\r\n"
          end
          head << "Content-Length: #{@length}\r\n" unless @length.nil?
          head << "Content-Transfer-Encoding: binary\r\n"
          head << "\r\n"
          Google::Apis::Core::CompositeIO.new(StringIO.new(head), @io, StringIO.new("\r\n"))
        end
      end

      # Helper for building multipart requests
      class Multipart
        MULTIPART_RELATED = 'multipart/related'

        # @return [String]
        #  Content type header
        attr_reader :content_type

        # @param [String] content_type
        #  Content type for the multipart request
        # @param [String] boundary
        #  Part delimiter

        def initialize(content_type: MULTIPART_RELATED, boundary: nil)
          @parts = []
          @boundary = boundary || Digest::SHA1.hexdigest(SecureRandom.random_bytes(8))
          @content_type = "#{content_type}; boundary=#{@boundary}"
        end

        # Append JSON data part
        #
        # @param [String] body
        #   JSON text
        # @param [String] content_id
        #   Optional unique ID of this part
        # @return [self]
        def add_json(body, content_id: nil)
          header = {}
          header['Content-ID'] = content_id unless content_id.nil?
          @parts << Google::Apis::Core::JsonPart.new(body, header).to_io(@boundary)
          self
        end

        # Append arbitrary data as a part
        #
        # @param [IO] upload_io
        #   IO stream
        # @param [String] content_id
        #   Optional unique ID of this part
        # @return [self]
        def add_upload(upload_io, content_type: nil, content_id: nil)
          header = {
              'Content-Type' => content_type || 'application/octet-stream'
          }
          header['Content-Id'] = content_id unless content_id.nil?
          @parts << Google::Apis::Core::FilePart.new(upload_io,
                                                     header).to_io(@boundary)
          self
        end

        # Assemble the multipart requests
        #
        # @return [IO]
        #  IO stream
        def assemble
          @parts <<  StringIO.new("--#{@boundary}--\r\n\r\n")
          Google::Apis::Core::CompositeIO.new(*@parts)
        end
      end
    end
  end
end