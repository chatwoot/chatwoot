# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::STS
  module Plugins
    class Endpoints < Seahorse::Client::Plugin
      option(
        :endpoint_provider,
        doc_type: 'Aws::STS::EndpointProvider',
        docstring: 'The endpoint provider used to resolve endpoints. Any '\
                   'object that responds to `#resolve_endpoint(parameters)` '\
                   'where `parameters` is a Struct similar to '\
                   '`Aws::STS::EndpointParameters`'
      ) do |cfg|
        Aws::STS::EndpointProvider.new
      end

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          # If endpoint was discovered, do not resolve or apply the endpoint.
          unless context[:discovered_endpoint]
            params = parameters_for_operation(context)
            endpoint = context.config.endpoint_provider.resolve_endpoint(params)

            context.http_request.endpoint = endpoint.url
            apply_endpoint_headers(context, endpoint.headers)
          end

          context[:endpoint_params] = params
          context[:auth_scheme] =
            Aws::Endpoints.resolve_auth_scheme(context, endpoint)

          @handler.call(context)
        end

        private

        def apply_endpoint_headers(context, headers)
          headers.each do |key, values|
            value = values
              .compact
              .map { |s| Seahorse::Util.escape_header_list_string(s.to_s) }
              .join(',')

            context.http_request.headers[key] = value
          end
        end

        def parameters_for_operation(context)
          case context.operation_name
          when :assume_role
            Aws::STS::Endpoints::AssumeRole.build(context)
          when :assume_role_with_saml
            Aws::STS::Endpoints::AssumeRoleWithSAML.build(context)
          when :assume_role_with_web_identity
            Aws::STS::Endpoints::AssumeRoleWithWebIdentity.build(context)
          when :decode_authorization_message
            Aws::STS::Endpoints::DecodeAuthorizationMessage.build(context)
          when :get_access_key_info
            Aws::STS::Endpoints::GetAccessKeyInfo.build(context)
          when :get_caller_identity
            Aws::STS::Endpoints::GetCallerIdentity.build(context)
          when :get_federation_token
            Aws::STS::Endpoints::GetFederationToken.build(context)
          when :get_session_token
            Aws::STS::Endpoints::GetSessionToken.build(context)
          end
        end
      end

      def add_handlers(handlers, _config)
        handlers.add(Handler, step: :build, priority: 75)
      end
    end
  end
end
