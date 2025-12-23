# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  # When S3 returns an error response, the Ruby SDK constructs and raises an error.
  # These errors all extend Aws::S3::Errors::ServiceError < {Aws::Errors::ServiceError}
  #
  # You can rescue all S3 errors using ServiceError:
  #
  #     begin
  #       # do stuff
  #     rescue Aws::S3::Errors::ServiceError
  #       # rescues all S3 API errors
  #     end
  #
  #
  # ## Request Context
  # ServiceError objects have a {Aws::Errors::ServiceError#context #context} method that returns
  # information about the request that generated the error.
  # See {Seahorse::Client::RequestContext} for more information.
  #
  # ## Error Classes
  # * {BucketAlreadyExists}
  # * {BucketAlreadyOwnedByYou}
  # * {InvalidObjectState}
  # * {NoSuchBucket}
  # * {NoSuchKey}
  # * {NoSuchUpload}
  # * {ObjectAlreadyInActiveTierError}
  # * {ObjectNotInActiveTierError}
  #
  # Additionally, error classes are dynamically generated for service errors based on the error code
  # if they are not defined above.
  module Errors

    extend Aws::Errors::DynamicErrors

    class BucketAlreadyExists < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::BucketAlreadyExists] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class BucketAlreadyOwnedByYou < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::BucketAlreadyOwnedByYou] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class InvalidObjectState < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::InvalidObjectState] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def storage_class
        @data[:storage_class]
      end

      # @return [String]
      def access_tier
        @data[:access_tier]
      end
    end

    class NoSuchBucket < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::NoSuchBucket] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class NoSuchKey < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::NoSuchKey] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class NoSuchUpload < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::NoSuchUpload] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class ObjectAlreadyInActiveTierError < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::ObjectAlreadyInActiveTierError] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

    class ObjectNotInActiveTierError < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::S3::Types::ObjectNotInActiveTierError] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end
    end

  end
end
