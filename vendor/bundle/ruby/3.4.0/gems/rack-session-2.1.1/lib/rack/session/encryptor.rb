# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.
# Copyright, 2022, by Philip Arndt.

require 'base64'
require 'openssl'
require 'securerandom'
require 'zlib'

require 'rack/utils'

module Rack
  module Session
    class Encryptor
      class Error < StandardError
      end

      class InvalidSignature < Error
      end

      class InvalidMessage < Error
      end

      # The secret String must be at least 64 bytes in size. The first 32 bytes
      # will be used for the encryption cipher key. The remainder will be used
      # for an HMAC key.
      #
      # Options may include:
      # * :serialize_json
      #     Use JSON for message serialization instead of Marshal. This can be
      #     viewed as a security enhancement.
      # * :pad_size
      #     Pad encrypted message data, to a multiple of this many bytes
      #     (default: 32). This can be between 2-4096 bytes, or +nil+ to disable
      #     padding.
      # * :purpose
      #     Limit messages to a specific purpose. This can be viewed as a
      #     security enhancement to prevent message reuse from different contexts
      #     if keys are reused.
      #
      # Cryptography and Output Format:
      #
      #   urlsafe_encode64(version + random_data + IV + encrypted data + HMAC)
      #
      #  Where:
      #  * version - 1 byte and is currently always 0x01
      #  * random_data - 32 bytes used for generating the per-message secret
      #  * IV - 16 bytes random initialization vector
      #  * HMAC - 32 bytes HMAC-SHA-256 of all preceding data, plus the purpose
      #    value
      def initialize(secret, opts = {})
        raise ArgumentError, "secret must be a String" unless String === secret
        raise ArgumentError, "invalid secret: #{secret.bytesize}, must be >=64" unless secret.bytesize >= 64

        case opts[:pad_size]
        when nil
          # padding is disabled
        when Integer
          raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}" unless (2..4096).include? opts[:pad_size]
        else
          raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}; must be Integer or nil"
        end

        @options = {
          serialize_json: false, pad_size: 32, purpose: nil
        }.update(opts)

        @hmac_secret = secret.dup.force_encoding('BINARY')
        @cipher_secret = @hmac_secret.slice!(0, 32)

        @hmac_secret.freeze
        @cipher_secret.freeze
      end

      def decrypt(base64_data)
        data = Base64.urlsafe_decode64(base64_data)

        signature = data.slice!(-32..-1)

        verify_authenticity! data, signature

        # The version is reserved for future
        _version = data.slice!(0, 1)
        message_secret = data.slice!(0, 32)
        cipher_iv = data.slice!(0, 16)

        cipher = new_cipher
        cipher.decrypt

        set_cipher_key(cipher, cipher_secret_from_message_secret(message_secret))

        cipher.iv = cipher_iv
        data = cipher.update(data) << cipher.final

        deserialized_message data
      rescue ArgumentError
        raise InvalidSignature, 'Message invalid'
      end

      def encrypt(message)
        version = "\1"

        serialized_payload = serialize_payload(message)
        message_secret, cipher_secret = new_message_and_cipher_secret

        cipher = new_cipher
        cipher.encrypt

        set_cipher_key(cipher, cipher_secret)

        cipher_iv = cipher.random_iv

        encrypted_data = cipher.update(serialized_payload) << cipher.final

        data = String.new
        data << version
        data << message_secret
        data << cipher_iv
        data << encrypted_data
        data << compute_signature(data)

        Base64.urlsafe_encode64(data)
      end

      private

      def new_cipher
        OpenSSL::Cipher.new('aes-256-ctr')
      end

      def new_message_and_cipher_secret
        message_secret = SecureRandom.random_bytes(32)

        [message_secret, cipher_secret_from_message_secret(message_secret)]
      end

      def cipher_secret_from_message_secret(message_secret)
        OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @cipher_secret, message_secret)
      end

      def set_cipher_key(cipher, key)
        cipher.key = key
      end

      def serializer
        @serializer ||= @options[:serialize_json] ? JSON : Marshal
      end

      def compute_signature(data)
        signing_data = data
        signing_data += @options[:purpose] if @options[:purpose]

        OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @hmac_secret, signing_data)
      end

      def verify_authenticity!(data, signature)
        raise InvalidMessage, 'Message is invalid' if data.nil? || signature.nil?

        unless Rack::Utils.secure_compare(signature, compute_signature(data))
          raise InvalidSignature, 'HMAC is invalid'
        end
      end

      # Returns a serialized payload of the message. If a :pad_size is supplied,
      # the message will be padded. The first 2 bytes of the returned string will
      # indicating the amount of padding.
      def serialize_payload(message)
        serialized_data = serializer.dump(message)

        return "#{[0].pack('v')}#{serialized_data}" if @options[:pad_size].nil?

        padding_bytes = @options[:pad_size] - (2 + serialized_data.size) % @options[:pad_size]
        padding_data = SecureRandom.random_bytes(padding_bytes)

        "#{[padding_bytes].pack('v')}#{padding_data}#{serialized_data}"
      end

      # Return the deserialized message. The first 2 bytes will be read as the
      # amount of padding.
      def deserialized_message(data)
        # Read the first 2 bytes as the padding_bytes size
        padding_bytes, = data.unpack('v')

        # Slice out the serialized_data and deserialize it
        serialized_data = data.slice(2 + padding_bytes, data.bytesize)
        serializer.load serialized_data
      end
    end
  end
end
