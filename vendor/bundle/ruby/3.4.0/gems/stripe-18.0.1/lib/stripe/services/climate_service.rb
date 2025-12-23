# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ClimateService < StripeService
    attr_reader :orders, :products, :suppliers

    def initialize(requestor)
      super
      @orders = Stripe::Climate::OrderService.new(@requestor)
      @products = Stripe::Climate::ProductService.new(@requestor)
      @suppliers = Stripe::Climate::SupplierService.new(@requestor)
    end
  end
end
