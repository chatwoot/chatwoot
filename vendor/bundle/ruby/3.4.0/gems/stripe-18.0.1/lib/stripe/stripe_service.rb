# frozen_string_literal: true
# typed: true

module Stripe
  class StripeService
    # Initializes a new StripeService
    def initialize(requestor)
      @requestor = requestor
    end

    def request(method:, path:, base_address:, params: {}, opts: {})
      @requestor.execute_request(
        method,
        path,
        base_address,
        params: params,
        opts: RequestOptions.extract_opts_from_hash(opts),
        usage: ["stripe_client"]
      )
    end

    def request_stream(method:, path:, base_address:, params: {}, opts: {}, &read_body_chunk_block)
      @requestor.execute_request_stream(
        method,
        path,
        base_address,
        params: params,
        opts: RequestOptions.extract_opts_from_hash(opts),
        usage: ["stripe_client"],
        &read_body_chunk_block
      )
    end
  end
end
