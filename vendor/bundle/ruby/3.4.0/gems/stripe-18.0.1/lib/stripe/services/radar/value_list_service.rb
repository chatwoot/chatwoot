# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    class ValueListService < StripeService
      # Creates a new ValueList object, which can then be referenced in rules.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/radar/value_lists",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Deletes a ValueList object, also deleting any items contained within the value list. To be deleted, a value list must not be referenced in any rules.
      def delete(value_list, params = {}, opts = {})
        request(
          method: :delete,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(value_list) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of ValueList objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/radar/value_lists",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a ValueList object.
      def retrieve(value_list, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(value_list) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates a ValueList object by setting the values of the parameters passed. Any parameters not provided will be left unchanged. Note that item_type is immutable.
      def update(value_list, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(value_list) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
