# frozen_string_literal: true

require 'time'

require_relative 'constants'
require_relative 'head'
require_relative 'utils'
require_relative 'request'
require_relative 'mime'

module Rack
  # Rack::Files serves files below the +root+ directory given, according to the
  # path info of the Rack request.
  # e.g. when Rack::Files.new("/etc") is used, you can access 'passwd' file
  # as http://localhost:9292/passwd
  #
  # Handlers can detect if bodies are a Rack::Files, and use mechanisms
  # like sendfile on the +path+.

  class Files
    ALLOWED_VERBS = %w[GET HEAD OPTIONS]
    ALLOW_HEADER = ALLOWED_VERBS.join(', ')
    MULTIPART_BOUNDARY = 'AaB03x'

    attr_reader :root

    def initialize(root, headers = {}, default_mime = 'text/plain')
      @root = (::File.expand_path(root) if root)
      @headers = headers
      @default_mime = default_mime
      @head = Rack::Head.new(lambda { |env| get env })
    end

    def call(env)
      # HEAD requests drop the response body, including 4xx error messages.
      @head.call env
    end

    def get(env)
      request = Rack::Request.new env
      unless ALLOWED_VERBS.include? request.request_method
        return fail(405, "Method Not Allowed", { 'allow' => ALLOW_HEADER })
      end

      path_info = Utils.unescape_path request.path_info
      return fail(400, "Bad Request") unless Utils.valid_path?(path_info)

      clean_path_info = Utils.clean_path_info(path_info)
      path = ::File.join(@root, clean_path_info)

      available = begin
        ::File.file?(path) && ::File.readable?(path)
      rescue SystemCallError
        # Not sure in what conditions this exception can occur, but this
        # is a safe way to handle such an error.
        # :nocov:
        false
        # :nocov:
      end

      if available
        serving(request, path)
      else
        fail(404, "File not found: #{path_info}")
      end
    end

    def serving(request, path)
      if request.options?
        return [200, { 'allow' => ALLOW_HEADER, CONTENT_LENGTH => '0' }, []]
      end
      last_modified = ::File.mtime(path).httpdate
      return [304, {}, []] if request.get_header('HTTP_IF_MODIFIED_SINCE') == last_modified

      headers = { "last-modified" => last_modified }
      mime_type = mime_type path, @default_mime
      headers[CONTENT_TYPE] = mime_type if mime_type

      # Set custom headers
      headers.merge!(@headers) if @headers

      status = 200
      size = filesize path

      ranges = Rack::Utils.get_byte_ranges(request.get_header('HTTP_RANGE'), size)
      if ranges.nil?
        # No ranges:
        ranges = [0..size - 1]
      elsif ranges.empty?
        # Unsatisfiable. Return error, and file size:
        response = fail(416, "Byte range unsatisfiable")
        response[1]["content-range"] = "bytes */#{size}"
        return response
      else
        # Partial content
        partial_content = true

        if ranges.size == 1
          range = ranges[0]
          headers["content-range"] = "bytes #{range.begin}-#{range.end}/#{size}"
        else
          headers[CONTENT_TYPE] = "multipart/byteranges; boundary=#{MULTIPART_BOUNDARY}"
        end

        status = 206
        body = BaseIterator.new(path, ranges, mime_type: mime_type, size: size)
        size = body.bytesize
      end

      headers[CONTENT_LENGTH] = size.to_s

      if request.head?
        body = []
      elsif !partial_content
        body = Iterator.new(path, ranges, mime_type: mime_type, size: size)
      end

      [status, headers, body]
    end

    class BaseIterator
      attr_reader :path, :ranges, :options

      def initialize(path, ranges, options)
        @path = path
        @ranges = ranges
        @options = options
      end

      def each
        ::File.open(path, "rb") do |file|
          ranges.each do |range|
            yield multipart_heading(range) if multipart?

            each_range_part(file, range) do |part|
              yield part
            end
          end

          yield "\r\n--#{MULTIPART_BOUNDARY}--\r\n" if multipart?
        end
      end

      def bytesize
        size = ranges.inject(0) do |sum, range|
          sum += multipart_heading(range).bytesize if multipart?
          sum += range.size
        end
        size += "\r\n--#{MULTIPART_BOUNDARY}--\r\n".bytesize if multipart?
        size
      end

      def close; end

      private

      def multipart?
        ranges.size > 1
      end

      def multipart_heading(range)
<<-EOF
\r
--#{MULTIPART_BOUNDARY}\r
content-type: #{options[:mime_type]}\r
content-range: bytes #{range.begin}-#{range.end}/#{options[:size]}\r
\r
EOF
      end

      def each_range_part(file, range)
        file.seek(range.begin)
        remaining_len = range.end - range.begin + 1
        while remaining_len > 0
          part = file.read([8192, remaining_len].min)
          break unless part
          remaining_len -= part.length

          yield part
        end
      end
    end

    class Iterator < BaseIterator
      alias :to_path :path
    end

    private

    def fail(status, body, headers = {})
      body += "\n"

      [
        status,
        {
          CONTENT_TYPE   => "text/plain",
          CONTENT_LENGTH => body.size.to_s,
          "x-cascade" => "pass"
        }.merge!(headers),
        [body]
      ]
    end

    # The MIME type for the contents of the file located at @path
    def mime_type(path, default_mime)
      Mime.mime_type(::File.extname(path), default_mime)
    end

    def filesize(path)
      #   We check via File::size? whether this file provides size info
      #   via stat (e.g. /proc files often don't), otherwise we have to
      #   figure it out by reading the whole file into memory.
      ::File.size?(path) || ::File.read(path).bytesize
    end
  end
end
