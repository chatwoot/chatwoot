# frozen_string_literal: true

module Aws
  # @api private
  module Plugins
    # @api private
    class BearerAuthorization < Seahorse::Client::Plugin

      option(:token_provider,
             required: false,
             doc_type: 'Aws::TokenProvider',
             docstring: <<-DOCS
A Bearer Token Provider. This can be an instance of any one of the
following classes:

* `Aws::StaticTokenProvider` - Used for configuring static, non-refreshing
  tokens.

* `Aws::SSOTokenProvider` - Used for loading tokens from AWS SSO using an
  access token generated from `aws login`.

When `:token_provider` is not configured directly, the `Aws::TokenProviderChain`
will be used to search for tokens configured for your profile in shared configuration files.
      DOCS
      ) do |config|
        if config.stub_responses
          StaticTokenProvider.new('token')
        else
          TokenProviderChain.new(config).resolve
        end
      end


      def add_handlers(handlers, cfg)
        bearer_operations =
          if cfg.api.metadata['signatureVersion'] == 'bearer'
            # select operations where authtype is either not set or is bearer
            cfg.api.operation_names.select do |o|
              !cfg.api.operation(o)['authtype'] || cfg.api.operation(o)['authtype'] == 'bearer'
            end
          else # service is not bearer auth
            # select only operations where authtype is explicitly bearer
            cfg.api.operation_names.select do |o|
              cfg.api.operation(o)['authtype'] == 'bearer'
            end
          end
        handlers.add(Handler, step: :sign, operations: bearer_operations)
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          if context.http_request.endpoint.scheme != 'https'
            raise ArgumentError, 'Unable to use bearer authorization on non https endpoint.'
          end

          token_provider = context.config.token_provider
          if token_provider && token_provider.set?
            context.http_request.headers['Authorization'] = "Bearer #{token_provider.token.token}"
          else
            raise Errors::MissingBearerTokenError
          end
          @handler.call(context)
        end
      end
    end
  end
end
