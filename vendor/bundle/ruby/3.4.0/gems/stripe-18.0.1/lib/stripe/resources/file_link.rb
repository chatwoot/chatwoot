# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # To share the contents of a `File` object with non-Stripe users, you can
  # create a `FileLink`. `FileLink`s contain a URL that you can use to
  # retrieve the contents of the file without authentication.
  class FileLink < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "file_link"
    def self.object_name
      "file_link"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Returns if the link is already expired.
    attr_reader :expired
    # Time that the link expires.
    attr_reader :expires_at
    # The file object this link points to.
    attr_reader :file
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The publicly accessible URL to download the file.
    attr_reader :url

    # Creates a new file link object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/file_links", params: params, opts: opts)
    end

    # Returns a list of file links.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/file_links", params: params, opts: opts)
    end

    # Updates an existing file link object. Expired links can no longer be updated.
    def self.update(link, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/file_links/%<link>s", { link: CGI.escape(link) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
