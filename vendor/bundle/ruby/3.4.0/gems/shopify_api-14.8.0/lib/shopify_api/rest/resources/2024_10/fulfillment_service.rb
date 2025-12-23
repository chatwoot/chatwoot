# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class FulfillmentService < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @admin_graphql_api_id = T.let(nil, T.nilable(String))
      @callback_url = T.let(nil, T.nilable(String))
      @fulfillment_orders_opt_in = T.let(nil, T.nilable(T::Boolean))
      @handle = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @inventory_management = T.let(nil, T.nilable(T::Boolean))
      @location_id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @permits_sku_sharing = T.let(nil, T.nilable(T::Boolean))
      @provider_id = T.let(nil, T.nilable(String))
      @requires_shipping_method = T.let(nil, T.nilable(T::Boolean))
      @tracking_support = T.let(nil, T.nilable(T::Boolean))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "fulfillment_services/<id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "fulfillment_services.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "fulfillment_services/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "fulfillment_services.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "fulfillment_services/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :admin_graphql_api_id
    sig { returns(T.nilable(String)) }
    attr_reader :callback_url
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :fulfillment_orders_opt_in
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :inventory_management
    sig { returns(T.nilable(Integer)) }
    attr_reader :location_id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :permits_sku_sharing
    sig { returns(T.nilable(String)) }
    attr_reader :provider_id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :requires_shipping_method
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :tracking_support

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(FulfillmentService))
      end
      def find(
        id:,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id},
          params: {},
        )
        T.cast(result[0], T.nilable(FulfillmentService))
      end

      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id},
          params: {},
        )
      end

      sig do
        params(
          scope: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[FulfillmentService])
      end
      def all(
        scope: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {scope: scope}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[FulfillmentService])
      end

    end

  end
end
