# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SSOOIDC

  # When SSOOIDC returns an error response, the Ruby SDK constructs and raises an error.
  # These errors all extend Aws::SSOOIDC::Errors::ServiceError < {Aws::Errors::ServiceError}
  #
  # You can rescue all SSOOIDC errors using ServiceError:
  #
  #     begin
  #       # do stuff
  #     rescue Aws::SSOOIDC::Errors::ServiceError
  #       # rescues all SSOOIDC API errors
  #     end
  #
  #
  # ## Request Context
  # ServiceError objects have a {Aws::Errors::ServiceError#context #context} method that returns
  # information about the request that generated the error.
  # See {Seahorse::Client::RequestContext} for more information.
  #
  # ## Error Classes
  # * {AccessDeniedException}
  # * {AuthorizationPendingException}
  # * {ExpiredTokenException}
  # * {InternalServerException}
  # * {InvalidClientException}
  # * {InvalidClientMetadataException}
  # * {InvalidGrantException}
  # * {InvalidRequestException}
  # * {InvalidRequestRegionException}
  # * {InvalidScopeException}
  # * {SlowDownException}
  # * {UnauthorizedClientException}
  # * {UnsupportedGrantTypeException}
  #
  # Additionally, error classes are dynamically generated for service errors based on the error code
  # if they are not defined above.
  module Errors

    extend Aws::Errors::DynamicErrors

    class AccessDeniedException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::AccessDeniedException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class AuthorizationPendingException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::AuthorizationPendingException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class ExpiredTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::ExpiredTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InternalServerException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InternalServerException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InvalidClientException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidClientException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InvalidClientMetadataException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidClientMetadataException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InvalidGrantException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidGrantException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InvalidRequestException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidRequestException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class InvalidRequestRegionException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidRequestRegionException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end

      # @return [String]
      def endpoint
        @data[:endpoint]
      end

      # @return [String]
      def region
        @data[:region]
      end
    end

    class InvalidScopeException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::InvalidScopeException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class SlowDownException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::SlowDownException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class UnauthorizedClientException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::UnauthorizedClientException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

    class UnsupportedGrantTypeException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::SSOOIDC::Types::UnsupportedGrantTypeException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def error
        @data[:error]
      end

      # @return [String]
      def error_description
        @data[:error_description]
      end
    end

  end
end
