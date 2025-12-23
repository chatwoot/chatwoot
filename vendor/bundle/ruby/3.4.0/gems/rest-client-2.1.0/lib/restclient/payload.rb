require 'tempfile'
require 'securerandom'
require 'stringio'

begin
  # Use mime/types/columnar if available, for reduced memory usage
  require 'mime/types/columnar'
rescue LoadError
  require 'mime/types'
end

module RestClient
  module Payload
    extend self

    def generate(params)
      if params.is_a?(RestClient::Payload::Base)
        # pass through Payload objects unchanged
        params
      elsif params.is_a?(String)
        Base.new(params)
      elsif params.is_a?(Hash)
        if params.delete(:multipart) == true || has_file?(params)
          Multipart.new(params)
        else
          UrlEncoded.new(params)
        end
      elsif params.is_a?(ParamsArray)
        if _has_file?(params)
          Multipart.new(params)
        else
          UrlEncoded.new(params)
        end
      elsif params.respond_to?(:read)
        Streamed.new(params)
      else
        nil
      end
    end

    def has_file?(params)
      unless params.is_a?(Hash)
        raise ArgumentError.new("Must pass Hash, not #{params.inspect}")
      end
      _has_file?(params)
    end

    def _has_file?(obj)
      case obj
      when Hash, ParamsArray
        obj.any? {|_, v| _has_file?(v) }
      when Array
        obj.any? {|v| _has_file?(v) }
      else
        obj.respond_to?(:path) && obj.respond_to?(:read)
      end
    end

    class Base
      def initialize(params)
        build_stream(params)
      end

      def build_stream(params)
        @stream = StringIO.new(params)
        @stream.seek(0)
      end

      def read(*args)
        @stream.read(*args)
      end

      def to_s
        result = read
        @stream.seek(0)
        result
      end

      def headers
        {'Content-Length' => size.to_s}
      end

      def size
        @stream.size
      end

      alias :length :size

      def close
        @stream.close unless @stream.closed?
      end

      def closed?
        @stream.closed?
      end

      def to_s_inspect
        to_s.inspect
      end

      def short_inspect
        if size && size > 500
          "#{size} byte(s) length"
        else
          to_s_inspect
        end
      end

    end

    class Streamed < Base
      def build_stream(params = nil)
        @stream = params
      end

      def size
        if @stream.respond_to?(:size)
          @stream.size
        elsif @stream.is_a?(IO)
          @stream.stat.size
        end
      end

      # TODO (breaks compatibility): ought to use mime_for() to autodetect the
      # Content-Type for stream objects that have a filename.

      alias :length :size
    end

    class UrlEncoded < Base
      def build_stream(params = nil)
        @stream = StringIO.new(Utils.encode_query_string(params))
        @stream.seek(0)
      end

      def headers
        super.merge({'Content-Type' => 'application/x-www-form-urlencoded'})
      end
    end

    class Multipart < Base
      EOL = "\r\n"

      def build_stream(params)
        b = '--' + boundary

        @stream = Tempfile.new('rest-client.multipart.')
        @stream.binmode
        @stream.write(b + EOL)

        case params
        when Hash, ParamsArray
          x = Utils.flatten_params(params)
        else
          x = params
        end

        last_index = x.length - 1
        x.each_with_index do |a, index|
          k, v = * a
          if v.respond_to?(:read) && v.respond_to?(:path)
            create_file_field(@stream, k, v)
          else
            create_regular_field(@stream, k, v)
          end
          @stream.write(EOL + b)
          @stream.write(EOL) unless last_index == index
        end
        @stream.write('--')
        @stream.write(EOL)
        @stream.seek(0)
      end

      def create_regular_field(s, k, v)
        s.write("Content-Disposition: form-data; name=\"#{k}\"")
        s.write(EOL)
        s.write(EOL)
        s.write(v)
      end

      def create_file_field(s, k, v)
        begin
          s.write("Content-Disposition: form-data;")
          s.write(" name=\"#{k}\";") unless (k.nil? || k=='')
          s.write(" filename=\"#{v.respond_to?(:original_filename) ? v.original_filename : File.basename(v.path)}\"#{EOL}")
          s.write("Content-Type: #{v.respond_to?(:content_type) ? v.content_type : mime_for(v.path)}#{EOL}")
          s.write(EOL)
          while (data = v.read(8124))
            s.write(data)
          end
        ensure
          v.close if v.respond_to?(:close)
        end
      end

      def mime_for(path)
        mime = MIME::Types.type_for path
        mime.empty? ? 'text/plain' : mime[0].content_type
      end

      def boundary
        return @boundary if defined?(@boundary) && @boundary

        # Use the same algorithm used by WebKit: generate 16 random
        # alphanumeric characters, replacing `+` `/` with `A` `B` (included in
        # the list twice) to round out the set of 64.
        s = SecureRandom.base64(12)
        s.tr!('+/', 'AB')

        @boundary = '----RubyFormBoundary' + s
      end

      # for Multipart do not escape the keys
      #
      # Ostensibly multipart keys MAY be percent encoded per RFC 7578, but in
      # practice no major browser that I'm aware of uses percent encoding.
      #
      # Further discussion of multipart encoding:
      # https://github.com/rest-client/rest-client/pull/403#issuecomment-156976930
      #
      def handle_key key
        key
      end

      def headers
        super.merge({'Content-Type' => %Q{multipart/form-data; boundary=#{boundary}}})
      end

      def close
        @stream.close!
      end
    end
  end
end
