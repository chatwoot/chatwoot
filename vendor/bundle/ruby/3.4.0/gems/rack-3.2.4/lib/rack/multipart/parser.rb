# frozen_string_literal: true

require 'strscan'

require_relative '../utils'
require_relative '../bad_request'

module Rack
  module Multipart
    class MultipartPartLimitError < Errno::EMFILE
      include BadRequest
    end

    class MultipartTotalPartLimitError < StandardError
      include BadRequest
    end

    # Use specific error class when parsing multipart request
    # that ends early.
    class EmptyContentError < ::EOFError
      include BadRequest
    end

    # Base class for multipart exceptions that do not subclass from
    # other exception classes for backwards compatibility.
    class BoundaryTooLongError < StandardError
      include BadRequest
    end

    # Prefer to use the BoundaryTooLongError class or Rack::BadRequest.
    Error = BoundaryTooLongError

    EOL = "\r\n"
    FWS = /[ \t]+(?:\r\n[ \t]+)?/ # whitespace with optional folding
    HEADER_VALUE = "(?:[^\r\n]|\r\n[ \t])*" # anything but a non-folding CRLF
    MULTIPART = %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|ni
    MULTIPART_CONTENT_TYPE = /^Content-Type:#{FWS}?(#{HEADER_VALUE})/ni
    MULTIPART_CONTENT_DISPOSITION = /^Content-Disposition:#{FWS}?(#{HEADER_VALUE})/ni
    MULTIPART_CONTENT_ID = /^Content-ID:#{FWS}?(#{HEADER_VALUE})/ni

    # Rack::Multipart::Parser handles parsing of multipart/form-data requests.
    #
    # File Parameter Contents
    #
    # When processing file uploads, the parser returns a hash containing
    # information about uploaded files. For +file+ parameters, the hash includes:
    #
    # * +:filename+ - The original filename, already URL decoded by the parser
    # * +:type+ - The content type of the uploaded file  
    # * +:name+ - The parameter name from the form
    # * +:tempfile+ - A Tempfile object containing the uploaded data
    # * +:head+ - The raw header content for this part
    class Parser
      BUFSIZE = 1_048_576
      TEXT_PLAIN = "text/plain"
      TEMPFILE_FACTORY = lambda { |filename, content_type|
        extension = ::File.extname(filename.gsub("\0", '%00'))[0, 129]

        Tempfile.new(["RackMultipart", extension])
      }

      BOUNDARY_START_LIMIT = 16 * 1024
      private_constant :BOUNDARY_START_LIMIT

      MIME_HEADER_BYTESIZE_LIMIT = 64 * 1024
      private_constant :MIME_HEADER_BYTESIZE_LIMIT

      env_int = lambda do |key, val|
        if str_val = ENV[key]
          begin
            val = Integer(str_val, 10)
          rescue ArgumentError
            raise ArgumentError, "non-integer value provided for environment variable #{key}"
          end
        end

        val
      end

      BUFFERED_UPLOAD_BYTESIZE_LIMIT = env_int.call("RACK_MULTIPART_BUFFERED_UPLOAD_BYTESIZE_LIMIT", 16 * 1024 * 1024)
      private_constant :BUFFERED_UPLOAD_BYTESIZE_LIMIT

      class BoundedIO # :nodoc:
        def initialize(io, content_length)
          @io             = io
          @content_length = content_length
          @cursor = 0
        end

        def read(size, outbuf = nil)
          return if @cursor >= @content_length

          left = @content_length - @cursor

          str = if left < size
                  @io.read left, outbuf
                else
                  @io.read size, outbuf
                end

          if str
            @cursor += str.bytesize
          else
            # Raise an error for mismatching content-length and actual contents
            raise EOFError, "bad content body"
          end

          str
        end
      end

      MultipartInfo = Struct.new :params, :tmp_files
      EMPTY         = MultipartInfo.new(nil, [])

      def self.parse_boundary(content_type)
        return unless content_type
        data = content_type.match(MULTIPART)
        return unless data
        data[1]
      end

      def self.parse(io, content_length, content_type, tmpfile, bufsize, qp)
        return EMPTY if 0 == content_length

        boundary = parse_boundary content_type
        return EMPTY unless boundary

        if boundary.length > 70
          # RFC 1521 Section 7.2.1 imposes a 70 character maximum for the boundary.
          # Most clients use no more than 55 characters.
          raise BoundaryTooLongError, "multipart boundary size too large (#{boundary.length} characters)"
        end

        io = BoundedIO.new(io, content_length) if content_length

        parser = new(boundary, tmpfile, bufsize, qp)
        parser.parse(io)

        parser.result
      end

      class Collector
        class MimePart < Struct.new(:body, :head, :filename, :content_type, :name)
          def get_data
            data = body
            if filename == ""
              # filename is blank which means no file has been selected
              return
            elsif filename
              body.rewind if body.respond_to?(:rewind)

              # Take the basename of the upload's original filename.
              # This handles the full Windows paths given by Internet Explorer
              # (and perhaps other broken user agents) without affecting
              # those which give the lone filename.
              fn = filename.split(/[\/\\]/).last

              data = { filename: fn, type: content_type,
                      name: name, tempfile: body, head: head }
            end

            yield data
          end
        end

        class BufferPart < MimePart
          def file?; false; end
          def close; end
        end

        class TempfilePart < MimePart
          def file?; true; end
          def close; body.close; end
        end

        include Enumerable

        def initialize(tempfile)
          @tempfile = tempfile
          @mime_parts = []
          @open_files = 0
        end

        def each
          @mime_parts.each { |part| yield part }
        end

        def on_mime_head(mime_index, head, filename, content_type, name)
          if filename
            body = @tempfile.call(filename, content_type)
            body.binmode if body.respond_to?(:binmode)
            klass = TempfilePart
            @open_files += 1
          else
            body = String.new
            klass = BufferPart
          end

          @mime_parts[mime_index] = klass.new(body, head, filename, content_type, name)

          check_part_limits
        end

        def on_mime_body(mime_index, content)
          @mime_parts[mime_index].body << content
        end

        def on_mime_finish(mime_index)
        end

        private

        def check_part_limits
          file_limit = Utils.multipart_file_limit
          part_limit = Utils.multipart_total_part_limit

          if file_limit && file_limit > 0
            if @open_files >= file_limit
              @mime_parts.each(&:close)
              raise MultipartPartLimitError, 'Maximum file multiparts in content reached'
            end
          end

          if part_limit && part_limit > 0
            if @mime_parts.size >= part_limit
              @mime_parts.each(&:close)
              raise MultipartTotalPartLimitError, 'Maximum total multiparts in content reached'
            end
          end
        end
      end

      attr_reader :state

      def initialize(boundary, tempfile, bufsize, query_parser)
        @query_parser   = query_parser
        @params         = query_parser.make_params
        @bufsize        = bufsize

        @state = :FAST_FORWARD
        @mime_index = 0
        @body_retained = nil
        @retained_size = 0
        @collector = Collector.new tempfile

        @sbuf = StringScanner.new("".dup)
        @body_regex = /(?:#{EOL}|\A)--#{Regexp.quote(boundary)}(?:#{EOL}|--)/m
        @body_regex_at_end = /#{@body_regex}\z/m
        @end_boundary_size = boundary.bytesize + 4 # (-- at start, -- at finish)
        @rx_max_size = boundary.bytesize + 6 # (\r\n-- at start, either \r\n or -- at finish)
        @head_regex = /(.*?#{EOL})#{EOL}/m
      end

      def parse(io)
        outbuf = String.new
        read_data(io, outbuf)

        loop do
          status =
            case @state
            when :FAST_FORWARD
              handle_fast_forward
            when :CONSUME_TOKEN
              handle_consume_token
            when :MIME_HEAD
              handle_mime_head
            when :MIME_BODY
              handle_mime_body
            else # when :DONE
              return
            end

          read_data(io, outbuf) if status == :want_read
        end
      end

      def result
        @collector.each do |part|
          part.get_data do |data|
            tag_multipart_encoding(part.filename, part.content_type, part.name, data)
            name, data = handle_dummy_encoding(part.name, data)
            @query_parser.normalize_params(@params, name, data)
          end
        end
        MultipartInfo.new @params.to_params_hash, @collector.find_all(&:file?).map(&:body)
      end

      private

      def read_data(io, outbuf)
        content = io.read(@bufsize, outbuf)
        handle_empty_content!(content)
        @sbuf.concat(content)
      end

      # This handles the initial parser state.  We read until we find the starting
      # boundary, then we can transition to the next state. If we find the ending
      # boundary, this is an invalid multipart upload, but keep scanning for opening
      # boundary in that case. If no boundary found, we need to keep reading data
      # and retry. It's highly unlikely the initial read will not consume the
      # boundary.  The client would have to deliberately craft a response
      # with the opening boundary beyond the buffer size for that to happen.
      def handle_fast_forward
        while true
          case consume_boundary
          when :BOUNDARY
            # found opening boundary, transition to next state
            @state = :MIME_HEAD
            return
          when :END_BOUNDARY
            # invalid multipart upload
            if @sbuf.pos == @end_boundary_size && @sbuf.rest == EOL
              # stop parsing a buffer if a buffer is only an end boundary.
              @state = :DONE
              return
            end

            # retry for opening boundary
          else
            # We raise if we don't find the multipart boundary, to avoid unbounded memory
            # buffering. Note that the actual limit is the higher of 16KB and the buffer size (1MB by default)
            raise Error, "multipart boundary not found within limit" if @sbuf.string.bytesize > BOUNDARY_START_LIMIT

            # no boundary found, keep reading data
            return :want_read
          end
        end
      end

      def handle_consume_token
        tok = consume_boundary
        # break if we're at the end of a buffer, but not if it is the end of a field
        @state = if tok == :END_BOUNDARY || (@sbuf.eos? && tok != :BOUNDARY)
          :DONE
        else
          :MIME_HEAD
        end
      end

      CONTENT_DISPOSITION_MAX_PARAMS = 16
      CONTENT_DISPOSITION_MAX_BYTES = 1536
      def handle_mime_head
        if @sbuf.scan_until(@head_regex)
          head = @sbuf[1]
          content_type = head[MULTIPART_CONTENT_TYPE, 1]
          if (disposition = head[MULTIPART_CONTENT_DISPOSITION, 1]) &&
              disposition.bytesize <= CONTENT_DISPOSITION_MAX_BYTES

            # ignore actual content-disposition value (should always be form-data)
            i = disposition.index(';')
            disposition.slice!(0, i+1)
            param = nil
            num_params = 0

            # Parse parameter list
            while i = disposition.index('=')
              # Only parse up to max parameters, to avoid potential denial of service
              num_params += 1
              break if num_params > CONTENT_DISPOSITION_MAX_PARAMS

              # Found end of parameter name, ensure forward progress in loop
              param = disposition.slice!(0, i+1)

              # Remove ending equals and preceding whitespace from parameter name
              param.chomp!('=')
              param.lstrip!

              if disposition[0] == '"'
                # Parameter value is quoted, parse it, handling backslash escapes
                disposition.slice!(0, 1)
                value = String.new

                while i = disposition.index(/(["\\])/)
                  c = $1

                  # Append all content until ending quote or escape
                  value << disposition.slice!(0, i)

                  # Remove either backslash or ending quote,
                  # ensures forward progress in loop
                  disposition.slice!(0, 1)

                  # stop parsing parameter value if found ending quote
                  break if c == '"'

                  escaped_char = disposition.slice!(0, 1)
                  if param == 'filename' && escaped_char != '"'
                    # Possible IE uploaded filename, append both escape backslash and value
                    value << c << escaped_char
                  else
                    # Other only append escaped value
                    value << escaped_char
                  end
                end
              else
                if i = disposition.index(';')
                  # Parameter value unquoted (which may be invalid), value ends at semicolon
                  value = disposition.slice!(0, i)
                else
                  # If no ending semicolon, assume remainder of line is value and stop
                  # parsing
                  disposition.strip!
                  value = disposition
                  disposition = ''
                end
              end

              case param
              when 'name'
                name = value
              when 'filename'
                filename = value
              when 'filename*'
                filename_star = value
              # else
              # ignore other parameters
              end

              # skip trailing semicolon, to proceed to next parameter
              if i = disposition.index(';')
                disposition.slice!(0, i+1)
              end
            end
          else
            name = head[MULTIPART_CONTENT_ID, 1]
          end

          if filename_star
            encoding, _, filename = filename_star.split("'", 3)
            filename = normalize_filename(filename || '')
            filename.force_encoding(find_encoding(encoding))
          elsif filename
            filename = normalize_filename(filename)
          end

          if name.nil? || name.empty?
            name = filename || "#{content_type || TEXT_PLAIN}[]".dup
          end

          # Mime part head data is retained for both TempfilePart and BufferPart
          # for the entireity of the parse, even though it isn't used for BufferPart.
          update_retained_size(head.bytesize)

          # If a filename is given, a TempfilePart will be used, so the body will
          # not be buffered in memory. However, if a filename is not given, a BufferPart
          # will be used, and the body will be buffered in memory.
          @body_retained = !filename

          @collector.on_mime_head @mime_index, head, filename, content_type, name
          @state = :MIME_BODY
        else
          # We raise if the mime part header is too large, to avoid unbounded memory
          # buffering. Note that the actual limit is the higher of 64KB and the buffer size (1MB by default)
          raise Error, "multipart mime part header too large" if @sbuf.rest.bytesize > MIME_HEADER_BYTESIZE_LIMIT

          return :want_read
        end
      end

      def handle_mime_body
        if (body_with_boundary = @sbuf.check_until(@body_regex)) # check but do not advance the pointer yet
          body = body_with_boundary.sub(@body_regex_at_end, '') # remove the boundary from the string
          update_retained_size(body.bytesize) if @body_retained
          @collector.on_mime_body @mime_index, body
          @sbuf.pos += body.length + 2 # skip \r\n after the content
          @state = :CONSUME_TOKEN
          @mime_index += 1
        else
          # Save what we have so far
          if @rx_max_size < @sbuf.rest_size
            delta = @sbuf.rest_size - @rx_max_size
            body = @sbuf.peek(delta)
            update_retained_size(body.bytesize) if @body_retained
            @collector.on_mime_body @mime_index, body
            @sbuf.pos += delta
            @sbuf.string = @sbuf.rest
          end
          :want_read
        end
      end

      def update_retained_size(size)
        @retained_size += size
        if @retained_size > BUFFERED_UPLOAD_BYTESIZE_LIMIT
          raise Error, "multipart data over retained size limit"
        end
      end

      # Scan until the we find the start or end of the boundary.
      # If we find it, return the appropriate symbol for the start or
      # end of the boundary.  If we don't find the start or end of the
      # boundary, clear the buffer and return nil.
      def consume_boundary
        if read_buffer = @sbuf.scan_until(@body_regex)
          read_buffer.end_with?(EOL) ? :BOUNDARY : :END_BOUNDARY
        else
          @sbuf.terminate
          nil
        end
      end

      def normalize_filename(filename)
        if filename.scan(/%.?.?/).all? { |s| /%[0-9a-fA-F]{2}/.match?(s) }
          filename = Utils.unescape_path(filename)
        end

        filename.scrub!

        filename.split(/[\/\\]/).last || String.new
      end

      CHARSET = "charset"
      deprecate_constant :CHARSET

      def tag_multipart_encoding(filename, content_type, name, body)
        name = name.to_s
        encoding = Encoding::UTF_8

        name.force_encoding(encoding)

        return if filename

        if content_type
          list         = content_type.split(';')
          type_subtype = list.first
          type_subtype.strip!
          if TEXT_PLAIN == type_subtype
            rest = list.drop 1
            rest.each do |param|
              k, v = param.split('=', 2)
              k.strip!
              v.strip!
              v = v[1..-2] if v.start_with?('"') && v.end_with?('"')
              if k == "charset"
                encoding = find_encoding(v)
              end
            end
          end
        end

        name.force_encoding(encoding)
        body.force_encoding(encoding)
      end

      # Return the related Encoding object. However, because
      # enc is submitted by the user, it may be invalid, so
      # use a binary encoding in that case.
      def find_encoding(enc)
        Encoding.find enc
      rescue ArgumentError
        Encoding::BINARY
      end

      REENCODE_DUMMY_ENCODINGS = {
        # ISO-2022-JP is a legacy but still widely used encoding in Japan
        # Here we convert ISO-2022-JP to UTF-8 so that it can be handled.
        Encoding::ISO_2022_JP => true

        # Other dummy encodings are rarely used and have not been supported yet.
        # Adding support for them will require careful considerations.
      }

      def handle_dummy_encoding(name, body)
        # A string object with a 'dummy' encoding does not have full functionality and can cause errors.
        # So here we covert it to UTF-8 so that it can be handled properly.
        if name.encoding.dummy? && REENCODE_DUMMY_ENCODINGS[name.encoding]
          name = name.encode(Encoding::UTF_8)
          body = body.encode(Encoding::UTF_8)
        end
        return name, body
      end

      def handle_empty_content!(content)
        if content.nil? || content.empty?
          raise EmptyContentError
        end
      end
    end
  end
end
