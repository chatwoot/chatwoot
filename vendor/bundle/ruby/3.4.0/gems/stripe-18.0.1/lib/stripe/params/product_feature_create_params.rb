# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ProductFeatureCreateParams < ::Stripe::RequestParams
    # The ID of the [Feature](https://stripe.com/docs/api/entitlements/feature) object attached to this product.
    attr_accessor :entitlement_feature
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(entitlement_feature: nil, expand: nil)
      @entitlement_feature = entitlement_feature
      @expand = expand
    end
  end
end
