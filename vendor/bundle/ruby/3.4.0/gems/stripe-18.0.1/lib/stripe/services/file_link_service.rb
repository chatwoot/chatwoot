# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileLinkService < StripeService
    # Creates a new file link object.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/file_links", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of file links.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/file_links", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the file link with the given ID.
    def retrieve(link, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/file_links/%<link>s", { link: CGI.escape(link) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an existing file link object. Expired links can no longer be updated.
    def update(link, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/file_links/%<link>s", { link: CGI.escape(link) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
