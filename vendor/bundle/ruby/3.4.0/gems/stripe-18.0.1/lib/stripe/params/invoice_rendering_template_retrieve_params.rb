# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceRenderingTemplateRetrieveParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Attribute for param field version
    attr_accessor :version

    def initialize(expand: nil, version: nil)
      @expand = expand
      @version = version
    end
  end
end
