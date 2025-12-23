# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Domains registered for Apple Pay on the Web
  class ApplePayDomain < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List

    OBJECT_NAME = "apple_pay_domain"
    def self.object_name
      "apple_pay_domain"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Attribute for field domain_name
    attr_reader :domain_name
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Always true for a deleted object
    attr_reader :deleted

    # Create an apple pay domain.
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/apple_pay/domains",
        params: params,
        opts: opts
      )
    end

    # Delete an apple pay domain.
    def self.delete(domain, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/apple_pay/domains/%<domain>s", { domain: CGI.escape(domain) }),
        params: params,
        opts: opts
      )
    end

    # Delete an apple pay domain.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/apple_pay/domains/%<domain>s", { domain: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # List apple pay domains.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/apple_pay/domains", params: params, opts: opts)
    end

    def self.resource_url
      "/v1/apple_pay/domains"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
