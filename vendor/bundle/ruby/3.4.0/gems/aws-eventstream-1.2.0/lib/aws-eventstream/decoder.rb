# frozen_string_literal: true

require 'stringio'
require 'tempfile'
require 'zlib'

module Aws
  module EventStream

    # This class provides method for decoding binary inputs into
    # single or multiple messages (Aws::EventStream::Message).
    #
    # * {#decode} - decodes messages from an IO like object responds
    #   to #read that containing binary data, returning decoded
    #   Aws::EventStream::Message along the way or wrapped in an enumerator
    #
    # ## Examples
    #
    #   decoder = Aws::EventStream::Decoder.new
    #
    #   # decoding from IO
    #   decoder.decode(io) do |message|
    #     message.headers
    #     # => { ... }
    #     message.payload
    #     # => StringIO / Tempfile
    #   end
    #
    #   # alternatively
    #   message_pool = decoder.decode(io)
    #   message_pool.next
    #   # => Aws::EventStream::Message
    #
    # * {#decode_chunk} - decodes a single message from a chunk of data,
    #   returning message object followed by boolean(indicating eof status
    #   of data) in an array object
    #
    # ## Examples
    #
    #   # chunk containing exactly one message data
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => Aws::EventStream::Message
    #   chunk_eof
    #   # => true
    #
    #   # chunk containing a partial message
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => nil
    #   chunk_eof
    #   # => true
    #   # chunk data is saved at decoder's message_buffer
    #
    #   # chunk containing more that one data message
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => Aws::EventStream::Message
    #   chunk_eof
    #   # => false
    #   # extra chunk data is saved at message_buffer of the decoder
    #
    class Decoder

      include Enumerable

      ONE_MEGABYTE = 1024 * 1024
      private_constant :ONE_MEGABYTE

      # bytes of prelude part, including 4 bytes of
      # total message length, headers length and crc checksum of prelude
      PRELUDE_LENGTH = 12
      private_constant :PRELUDE_LENGTH

      # 4 bytes message crc checksum
      CRC32_LENGTH = 4
      private_constant :CRC32_LENGTH

      # @param [Hash] options The initialization options.
      # @option options [Boolean] :format (true) When `false` it
      #   disables user-friendly formatting for message header values
      #   including timestamp and uuid etc.
      def initialize(options = {})
        @format = options.fetch(:format, true)
        @message_buffer = ''
      end

      # Decodes messages from a binary stream
      #
      # @param [IO#read] io An IO-like object
      #   that responds to `#read`
      #
      # @yieldparam [Message] message
      # @return [Enumerable<Message>, nil] Returns a new Enumerable
      #   containing decoded messages if no block is given
      def decode(io, &block)
        raw_message = io.read
        decoded_message = decode_message(raw_message)
        return wrap_as_enumerator(decoded_message) unless block_given?
        # fetch message only
        raw_event, _eof = decoded_message
        block.call(raw_event)
      end

      # Decodes a single message from a chunk of string
      #
      # @param [String] chunk A chunk of string to be decoded,
      #   chunk can contain partial event message to multiple event messages
      #   When not provided, decode data from #message_buffer
      #
      # @return [Array<Message|nil, Boolean>] Returns single decoded message
      #   and boolean pair, the boolean flag indicates whether this chunk
      #   has been fully consumed, unused data is tracked at #message_buffer
      def decode_chunk(chunk = nil)
        @message_buffer = [@message_buffer, chunk].pack('a*a*') if chunk
        decode_message(@message_buffer)
      end

      private

      # exposed via object.send for testing
      attr_reader :message_buffer

      def wrap_as_enumerator(decoded_message)
        Enumerator.new do |yielder|
          yielder << decoded_message
        end
      end

      def decode_message(raw_message)
        # incomplete message prelude received
        return [nil, true] if raw_message.bytesize < PRELUDE_LENGTH

        prelude, content = raw_message.unpack("a#{PRELUDE_LENGTH}a*")

        # decode prelude
        total_length, header_length = decode_prelude(prelude)

        # incomplete message received, leave it in the buffer
        return [nil, true] if raw_message.bytesize < total_length

        content, checksum, remaining = content.unpack("a#{total_length - PRELUDE_LENGTH - CRC32_LENGTH}Na*")
        unless Zlib.crc32([prelude, content].pack('a*a*')) == checksum
          raise Errors::MessageChecksumError
        end

        # decode headers and payload
        headers, payload = decode_context(content, header_length)

        @message_buffer = remaining

        [Message.new(headers: headers, payload: payload), remaining.empty?]
      end

      def decode_prelude(prelude)
        # prelude contains length of message and headers,
        # followed with CRC checksum of itself
        content, checksum = prelude.unpack("a#{PRELUDE_LENGTH - CRC32_LENGTH}N")
        raise Errors::PreludeChecksumError unless Zlib.crc32(content) == checksum
        content.unpack('N*')
      end

      def decode_context(content, header_length)
        encoded_header, encoded_payload = content.unpack("a#{header_length}a*")
        [
          extract_headers(encoded_header),
          extract_payload(encoded_payload)
        ]
      end

      def extract_headers(buffer)
        scanner = buffer
        headers = {}
        until scanner.bytesize == 0
          # header key
          key_length, scanner = scanner.unpack('Ca*')
          key, scanner = scanner.unpack("a#{key_length}a*")

          # header value
          type_index, scanner = scanner.unpack('Ca*')
          value_type = Types.types[type_index]
          unpack_pattern, value_length = Types.pattern[value_type]
          value = if !!unpack_pattern == unpack_pattern
            # boolean types won't have value specified
            unpack_pattern
          else
            value_length, scanner = scanner.unpack('S>a*') unless value_length
            unpacked_value, scanner = scanner.unpack("#{unpack_pattern || "a#{value_length}"}a*")
            unpacked_value
          end

          headers[key] = HeaderValue.new(
            format: @format,
            value: value,
            type: value_type
          )
        end
        headers
      end

      def extract_payload(encoded)
        encoded.bytesize <= ONE_MEGABYTE ?
          payload_stringio(encoded) :
          payload_tempfile(encoded)
      end

      def payload_stringio(encoded)
        StringIO.new(encoded)
      end

      def payload_tempfile(encoded)
        payload = Tempfile.new
        payload.binmode
        payload.write(encoded)
        payload.rewind
        payload
      end
    end
  end
end
