# frozen_string_literal: true

require 'stringio'

module Faraday
  # Rubocop doesn't seem to understand that this is an extension to the
  # Multipart module, so let's add a nodoc
  # #:nodoc:
  module Multipart
    # Multipart value used to POST a binary data from a file or
    #
    # @example
    #   payload = { file: Faraday::FilePart.new("file_name.ext", "content/type") }
    #   http.post("/upload", payload)
    #

    # @!method initialize(filename_or_io, content_type, filename = nil, opts = {})
    #
    #   @param filename_or_io [String, IO] Either a String filename to a local
    #     file or an open IO object.
    #   @param content_type [String] String content type of the file data.
    #   @param filename [String] Optional String filename, usually to add context
    #     to a given IO object.
    #   @param opts [Hash] Optional Hash of String key/value pairs to describethis
    #     this uploaded file. Expected Header keys include:
    #     * Content-Transfer-Encoding - Defaults to "binary"
    #     * Content-Disposition - Defaults to "form-data"
    #     * Content-Type - Defaults to the content_type argument.
    #     * Content-ID - Optional.
    #
    # @return [Faraday::FilePart]
    #
    # @!attribute [r] content_type
    # The uploaded binary data's content type.
    #
    # @return [String]
    #
    # @!attribute [r] original_filename
    # The base filename, taken either from the filename_or_io or filename
    # arguments in #initialize.
    #
    # @return [String]
    #
    # @!attribute [r] opts
    # Extra String key/value pairs to make up the header for this uploaded file.
    #
    # @return [Hash]
    #
    # @!attribute [r] io
    # The open IO object for the uploaded file.
    #
    # @return [IO]
    if ::Gem::Requirement.new('>= 2.2.0').satisfied_by?(multipart_post_version)
      require 'multipart/post'
      FilePart = ::Multipart::Post::UploadIO
      Parts = ::Multipart::Post::Parts
    else
      require 'composite_io'
      require 'parts'
      FilePart = ::UploadIO
      Parts = ::Parts
    end

    # Similar to, but not compatible with CompositeReadIO provided by the
    # multipart-post gem.
    # https://github.com/nicksieger/multipart-post/blob/master/lib/composite_io.rb
    class CompositeReadIO
      def initialize(*parts)
        @parts = parts.flatten
        @ios = @parts.map(&:to_io)
        @index = 0
      end

      # @return [Integer] sum of the lengths of all the parts
      def length
        @parts.inject(0) { |sum, part| sum + part.length }
      end

      # Rewind each of the IOs and reset the index to 0.
      #
      # @return [void]
      def rewind
        @ios.each(&:rewind)
        @index = 0
      end

      # Read from IOs in order until `length` bytes have been received.
      #
      # @param length [Integer, nil]
      # @param outbuf [String, nil]
      def read(length = nil, outbuf = nil)
        got_result = false
        outbuf = outbuf ? (+outbuf).replace('') : +''

        while (io = current_io)
          if (result = io.read(length))
            got_result ||= !result.nil?
            result.force_encoding('BINARY') if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length if length
            break if length&.zero?
          end
          advance_io
        end
        !got_result && length ? nil : outbuf
      end

      # Close each of the IOs.
      #
      # @return [void]
      def close
        @ios.each(&:close)
      end

      def ensure_open_and_readable
        # Rubinius compatibility
      end

      private

      def current_io
        @ios[@index]
      end

      def advance_io
        @index += 1
      end
    end
  end
end
