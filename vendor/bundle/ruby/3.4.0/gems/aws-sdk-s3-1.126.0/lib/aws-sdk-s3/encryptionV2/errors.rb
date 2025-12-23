# frozen_string_literal: true

module Aws
  module S3
    module EncryptionV2
      module Errors

        # Generic DecryptionError
        class DecryptionError < RuntimeError; end

        class EncryptionError < RuntimeError; end

        # Raised when attempting to decrypt a legacy (V1) encrypted object
        # when using a security_profile that does not support it.
        class LegacyDecryptionError < DecryptionError
          def initialize(*args)
            msg = 'The requested object is ' \
              'encrypted with V1 encryption schemas that have been disabled ' \
              'by client configuration security_profile = :v2. Retry with ' \
              ':v2_and_legacy or re-encrypt the object.'
            super(msg)
          end
        end

        class CEKAlgMismatchError < DecryptionError
          def initialize(*args)
            msg = 'The content encryption algorithm used at encryption time ' \
              'does not match the algorithm stored for decryption time. ' \
              'The object may be altered or corrupted.'
            super(msg)
          end
        end

      end
    end
  end
end
