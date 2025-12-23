# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Login Links are single-use URLs that takes an Express account to the login page for their Stripe dashboard.
  # A Login Link differs from an [Account Link](https://stripe.com/docs/api/account_links) in that it takes the user directly to their [Express dashboard for the specified account](https://stripe.com/docs/connect/integrate-express-dashboard#create-login-link)
  class LoginLink < APIResource
    OBJECT_NAME = "login_link"
    def self.object_name
      "login_link"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The URL for the login link.
    attr_reader :url

    def self.retrieve(_id, _opts = nil)
      raise NotImplementedError,
            "Login links do not have IDs and cannot be retrieved. They can " \
            "only be created using `Account.create_login_link('account_id', " \
            "create_params)`"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
