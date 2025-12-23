# frozen_string_literal: true

require 'aws-sdk-s3/encryption/client'
require 'aws-sdk-s3/encryption/decrypt_handler'
require 'aws-sdk-s3/encryption/default_cipher_provider'
require 'aws-sdk-s3/encryption/encrypt_handler'
require 'aws-sdk-s3/encryption/errors'
require 'aws-sdk-s3/encryption/io_encrypter'
require 'aws-sdk-s3/encryption/io_decrypter'
require 'aws-sdk-s3/encryption/io_auth_decrypter'
require 'aws-sdk-s3/encryption/key_provider'
require 'aws-sdk-s3/encryption/kms_cipher_provider'
require 'aws-sdk-s3/encryption/materials'
require 'aws-sdk-s3/encryption/utils'
require 'aws-sdk-s3/encryption/default_key_provider'

module Aws
  module S3
    module Encryption; end
    AES_GCM_TAG_LEN_BYTES = 16
    EC_USER_AGENT = 'S3CryptoV1n'
  end
end
