# frozen_string_literal: true

module Stripe
  # The base class for nested TestHelpers classes in resource objects.
  # The APIResourceTestHelpers handles URL generation and custom method
  # support for test-helper methods.
  #
  #  class MyAPIResource < APIResource
  #    class TestHelpers < APIResourceTestHelpers
  class APIResourceTestHelpers
    include Stripe::APIOperations::Request

    def initialize(resource)
      @resource = resource
    end

    def self.resource_class
      nil
    end

    # Adds a custom method to a test helper. This is used to add support for
    # non-CRUDL API requests, e.g. capturing charges. custom_method takes the
    # following parameters:
    # - name: the name of the custom method to create (as a symbol)
    # - http_verb: the HTTP verb for the API request (:get, :post, or :delete)
    # - http_path: the path to append to the resource's URL. If not provided,
    #              the name is used as the path
    #
    # For example, this call:
    #     custom_method :capture, http_verb: post
    # adds a `capture` class method to the resource class that, when called,
    # will send a POST request to `/v1/<object_name>/capture`.
    def self.custom_method(name, http_verb:, http_path: nil)
      Util.custom_method resource_class, self, name, http_verb, http_path
    end

    def self.resource_url
      "/v1/test_helpers/" \
        "#{resource_class.object_name.downcase.tr('.', '/')}s"
    end

    def resource_url
      unless (id = @resource["id"])
        raise InvalidRequestError.new(
          "Could not determine which URL to request: #{self.class} instance " \
          "has invalid ID: #{id.inspect}",
          "id"
        )
      end
      "#{self.class.resource_url}/#{CGI.escape(id)}"
    end
  end
end
