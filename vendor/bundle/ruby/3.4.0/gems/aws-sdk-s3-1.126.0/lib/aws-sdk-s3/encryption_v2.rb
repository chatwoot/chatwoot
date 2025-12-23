require 'aws-sdk-s3/encryptionV2/client'
require 'aws-sdk-s3/encryptionV2/decrypt_handler'
require 'aws-sdk-s3/encryptionV2/default_cipher_provider'
require 'aws-sdk-s3/encryptionV2/encrypt_handler'
require 'aws-sdk-s3/encryptionV2/errors'
require 'aws-sdk-s3/encryptionV2/io_encrypter'
require 'aws-sdk-s3/encryptionV2/io_decrypter'
require 'aws-sdk-s3/encryptionV2/io_auth_decrypter'
require 'aws-sdk-s3/encryptionV2/key_provider'
require 'aws-sdk-s3/encryptionV2/kms_cipher_provider'
require 'aws-sdk-s3/encryptionV2/materials'
require 'aws-sdk-s3/encryptionV2/utils'
require 'aws-sdk-s3/encryptionV2/default_key_provider'

module Aws
  module S3
    module EncryptionV2
      AES_GCM_TAG_LEN_BYTES = 16
      EC_USER_AGENT = 'S3CryptoV2'
    end
  end
end

