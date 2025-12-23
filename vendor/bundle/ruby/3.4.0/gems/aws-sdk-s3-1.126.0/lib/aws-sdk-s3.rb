# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


require 'aws-sdk-kms'
require 'aws-sigv4'
require 'aws-sdk-core'

require_relative 'aws-sdk-s3/types'
require_relative 'aws-sdk-s3/client_api'
require_relative 'aws-sdk-s3/plugins/endpoints.rb'
require_relative 'aws-sdk-s3/client'
require_relative 'aws-sdk-s3/errors'
require_relative 'aws-sdk-s3/waiters'
require_relative 'aws-sdk-s3/resource'
require_relative 'aws-sdk-s3/endpoint_parameters'
require_relative 'aws-sdk-s3/endpoint_provider'
require_relative 'aws-sdk-s3/endpoints'
require_relative 'aws-sdk-s3/bucket'
require_relative 'aws-sdk-s3/bucket_acl'
require_relative 'aws-sdk-s3/bucket_cors'
require_relative 'aws-sdk-s3/bucket_lifecycle'
require_relative 'aws-sdk-s3/bucket_lifecycle_configuration'
require_relative 'aws-sdk-s3/bucket_logging'
require_relative 'aws-sdk-s3/bucket_notification'
require_relative 'aws-sdk-s3/bucket_policy'
require_relative 'aws-sdk-s3/bucket_request_payment'
require_relative 'aws-sdk-s3/bucket_tagging'
require_relative 'aws-sdk-s3/bucket_versioning'
require_relative 'aws-sdk-s3/bucket_website'
require_relative 'aws-sdk-s3/multipart_upload'
require_relative 'aws-sdk-s3/multipart_upload_part'
require_relative 'aws-sdk-s3/object'
require_relative 'aws-sdk-s3/object_acl'
require_relative 'aws-sdk-s3/object_summary'
require_relative 'aws-sdk-s3/object_version'
require_relative 'aws-sdk-s3/customizations'
require_relative 'aws-sdk-s3/event_streams'

# This module provides support for Amazon Simple Storage Service. This module is available in the
# `aws-sdk-s3` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     s3 = Aws::S3::Client.new
#     resp = s3.abort_multipart_upload(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from Amazon Simple Storage Service are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::S3::Errors::ServiceError
#       # rescues all Amazon Simple Storage Service API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::S3

  GEM_VERSION = '1.126.0'

end
