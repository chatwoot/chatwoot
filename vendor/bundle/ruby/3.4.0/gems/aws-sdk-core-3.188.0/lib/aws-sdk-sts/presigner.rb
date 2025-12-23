# frozen_string_literal: true

require 'aws-sigv4'

module Aws
  module STS
    # Allows you to create presigned URLs for STS operations.
    #
    # @example
    #
    #   signer = Aws::STS::Presigner.new
    #   url = signer.get_caller_identity_presigned_url(
    #     headers: {"X-K8s-Aws-Id" => 'my-eks-cluster'}
    #   )
    class Presigner
      # @option options [Client] :client Optionally provide an existing
      #   STS client
      def initialize(options = {})
        @client = options[:client] || Aws::STS::Client.new
      end

      # Returns a presigned url for get_caller_identity.
      #
      # @option options [Hash] :headers
      #   Headers that should be signed and sent along with the request. All
      #   x-amz-* headers must be present during signing. Other headers are
      #   optional.
      #
      # @return [String] A presigned url string.
      #
      # @example
      #
      #   url = signer.get_caller_identity_presigned_url(
      #     headers: {"X-K8s-Aws-Id" => 'my-eks-cluster'},
      #   )
      #
      # This can be easily converted to a token used by the EKS service:
      # {https://docs.ruby-lang.org/en/3.2/Base64.html#method-i-encode64}
      # "k8s-aws-v1." + Base64.urlsafe_encode64(url).chomp("==")
      def get_caller_identity_presigned_url(options = {})
        req = @client.build_request(:get_caller_identity, {})
        context = req.context

        param_list = Aws::Query::ParamList.new
        param_list.set('Action', 'GetCallerIdentity')
        param_list.set('Version', req.context.config.api.version)
        Aws::Query::EC2ParamBuilder.new(param_list)
          .apply(req.context.operation.input, {})

        endpoint_params = Aws::STS::EndpointParameters.new(
          region: context.config.region,
          use_dual_stack: context.config.use_dualstack_endpoint,
          use_fips: context.config.use_fips_endpoint,
          use_global_endpoint: context.config.sts_regional_endpoints == 'legacy'
        )
        endpoint = context.config.endpoint_provider
                          .resolve_endpoint(endpoint_params)
        auth_scheme = Aws::Endpoints.resolve_auth_scheme(context, endpoint)

        signer = Aws::Plugins::Sign.signer_for(
          auth_scheme, context.config
        )

        signer.presign_url(
          http_method: 'GET',
          url: "#{endpoint.url}/?#{param_list}",
          body: '',
          headers: options[:headers]
        ).to_s
      end
    end
  end
end
