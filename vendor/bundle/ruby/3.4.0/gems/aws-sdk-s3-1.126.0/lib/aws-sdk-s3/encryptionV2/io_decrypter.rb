# frozen_string_literal: true

module Aws
  module S3
    module EncryptionV2
      # @api private
      class IODecrypter

        # @param [OpenSSL::Cipher] cipher
        # @param [IO#write] io An IO-like object that responds to `#write`.
        def initialize(cipher, io)
          @cipher = cipher
          # Ensure that IO is reset between retries
          @io = io.tap { |io| io.truncate(0) if io.respond_to?(:truncate) }
          @cipher_buffer = String.new
        end

        # @return [#write]
        attr_reader :io

        def write(chunk)
          # decrypt and write
          if @cipher.method(:update).arity == 1
            @io.write(@cipher.update(chunk))
          else
            @io.write(@cipher.update(chunk, @cipher_buffer))
          end
        end

        def finalize
          @io.write(@cipher.final)
        end

      end
    end
  end
end
