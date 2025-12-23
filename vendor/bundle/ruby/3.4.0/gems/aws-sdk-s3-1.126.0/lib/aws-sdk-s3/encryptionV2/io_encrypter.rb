# frozen_string_literal: true

require 'stringio'
require 'tempfile'

module Aws
  module S3
    module EncryptionV2

      # Provides an IO wrapper encrypting a stream of data.
      # @api private
      class IOEncrypter

        # @api private
        ONE_MEGABYTE = 1024 * 1024

        def initialize(cipher, io)
          @encrypted = io.size <= ONE_MEGABYTE ?
            encrypt_to_stringio(cipher, io.read) :
            encrypt_to_tempfile(cipher, io)
          @size = @encrypted.size
        end

        # @return [Integer]
        attr_reader :size

        def read(bytes = nil, output_buffer = nil)
          if @encrypted.is_a?(Tempfile) && @encrypted.closed?
            @encrypted.open
            @encrypted.binmode
          end
          @encrypted.read(bytes, output_buffer)
        end

        def rewind
          @encrypted.rewind
        end

        # @api private
        def close
          @encrypted.close if @encrypted.is_a?(Tempfile)
        end

        private

        def encrypt_to_stringio(cipher, plain_text)
          if plain_text.empty?
            StringIO.new(cipher.final + cipher.auth_tag)
          else
            StringIO.new(cipher.update(plain_text) + cipher.final + cipher.auth_tag)
          end
        end

        def encrypt_to_tempfile(cipher, io)
          encrypted = Tempfile.new(self.object_id.to_s)
          encrypted.binmode
          while chunk = io.read(ONE_MEGABYTE, read_buffer ||= String.new)
            if cipher.method(:update).arity == 1
              encrypted.write(cipher.update(chunk))
            else
              encrypted.write(cipher.update(chunk, cipher_buffer ||= String.new))
            end
          end
          encrypted.write(cipher.final)
          encrypted.write(cipher.auth_tag)
          encrypted.rewind
          encrypted
        end

      end
    end
  end
end
