# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class EphemeralKey < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete

    OBJECT_NAME = "ephemeral_key"
    def self.object_name
      "ephemeral_key"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Time at which the key will expire. Measured in seconds since the Unix epoch.
    attr_reader :expires
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The key's secret. You can use this value to make authorized requests to the Stripe API.
    attr_reader :secret

    # Invalidates a short-lived API key for a given resource.
    def self.delete(key, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/ephemeral_keys/%<key>s", { key: CGI.escape(key) }),
        params: params,
        opts: opts
      )
    end

    # Invalidates a short-lived API key for a given resource.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/ephemeral_keys/%<key>s", { key: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    def self.create(params = {}, opts = {})
      opts = Util.normalize_opts(opts)
      unless opts[:stripe_version]
        raise ArgumentError,
              "stripe_version must be specified to create an ephemeral key"
      end
      super
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
