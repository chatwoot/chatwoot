# frozen_string_literal: true

require 'zlib'

module Aws
  module EventStream

    # This class provides #encode method for encoding
    # Aws::EventStream::Message into binary.
    #
    # * {#encode} - encode Aws::EventStream::Message into binary
    #   when output IO-like object is provided, binary string
    #   would be written to IO. If not, the encoded binary string
    #   would be returned directly
    #
    # ## Examples
    #
    #   message = Aws::EventStream::Message.new(
    #     headers: {
    #       "foo" => Aws::EventStream::HeaderValue.new(
    #         value: "bar", type: "string"
    #        )
    #     },
    #     payload: "payload"
    #   )
    #   encoder = Aws::EventsStream::Encoder.new
    #   file = Tempfile.new
    #
    #   # encode into IO ouput
    #   encoder.encode(message, file)
    #
    #   # get encoded binary string
    #   encoded_message = encoder.encode(message)
    #
    #   file.read == encoded_message
    #   # => true
    #
    class Encoder

      # bytes of total overhead in a message, including prelude
      # and 4 bytes total message crc checksum
      OVERHEAD_LENGTH = 16

      # Maximum header length allowed (after encode) 128kb
      MAX_HEADERS_LENGTH = 131072

      # Maximum payload length allowed (after encode) 16mb
      MAX_PAYLOAD_LENGTH = 16777216

      # Encodes Aws::EventStream::Message to output IO when
      #   provided, else return the encoded binary string
      #
      # @param [Aws::EventStream::Message] message
      #
      # @param [IO#write, nil] io An IO-like object that
      #   responds to `#write`, encoded message will be
      #   written to this IO when provided
      #
      # @return [nil, String] when output IO is provided,
      #   encoded message will be written to that IO, nil
      #   will be returned. Else, encoded binary string is
      #   returned.
      def encode(message, io = nil)
        encoded = encode_message(message)
        if io
          io.write(encoded)
          io.close
        else
          encoded
        end
      end

      # Encodes an Aws::EventStream::Message
      #   into String
      #
      # @param [Aws::EventStream::Message] message
      #
      # @return [String]
      def encode_message(message)
        # create context buffer with encode headers
        encoded_header = encode_headers(message)
        header_length = encoded_header.bytesize
        # encode payload
        if message.payload.length > MAX_PAYLOAD_LENGTH
          raise Aws::EventStream::Errors::EventPayloadLengthExceedError.new
        end
        encoded_payload = message.payload.read
        total_length = header_length + encoded_payload.bytesize + OVERHEAD_LENGTH

        # create message buffer with prelude section
        encoded_prelude = encode_prelude(total_length, header_length)

        # append message context (headers, payload)
        encoded_content = [
          encoded_prelude,
          encoded_header,
          encoded_payload,
        ].pack('a*a*a*')
        # append message checksum
        message_checksum = Zlib.crc32(encoded_content)
        [encoded_content, message_checksum].pack('a*N')
      end

      # Encodes headers part of an Aws::EventStream::Message
      #   into String
      #
      # @param [Aws::EventStream::Message] message
      #
      # @return [String]
      def encode_headers(message)
        header_entries = message.headers.map do |key, value|
          encoded_key = [key.bytesize, key].pack('Ca*')

          # header value
          pattern, value_length, type_index = Types.pattern[value.type]
          encoded_value = [type_index].pack('C')
          # boolean types doesn't need to specify value
          next [encoded_key, encoded_value].pack('a*a*') if !!pattern == pattern
          encoded_value = [encoded_value, value.value.bytesize].pack('a*S>') unless value_length

          [
            encoded_key,
            encoded_value,
            pattern ? [value.value].pack(pattern) : value.value,
          ].pack('a*a*a*')
        end
        header_entries.join.tap do |encoded_header|
          break encoded_header if encoded_header.bytesize <= MAX_HEADERS_LENGTH
          raise Aws::EventStream::Errors::EventHeadersLengthExceedError.new
        end
      end

      private

      def encode_prelude(total_length, headers_length)
        prelude_body = [total_length, headers_length].pack('NN')
        checksum = Zlib.crc32(prelude_body)
        [prelude_body, checksum].pack('a*N')
      end
    end
  end
end
