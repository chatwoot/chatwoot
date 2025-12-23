# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class CarrierService < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @active = T.let(nil, T.nilable(T::Boolean))
      @admin_graphql_api_id = T.let(nil, T.nilable(String))
      @callback_url = T.let(nil, T.nilable(String))
      @carrier_service_type = T.let(nil, T.nilable(String))
      @format = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @service_discovery = T.let(nil, T.nilable(T::Boolean))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "carrier_services/<id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "carrier_services.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "carrier_services/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "carrier_services.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "carrier_services/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :active
    sig { returns(T.nilable(String)) }
    attr_reader :admin_graphql_api_id
    sig { returns(T.nilable(String)) }
    attr_reader :callback_url
    sig { returns(T.nilable(String)) }
    attr_reader :carrier_service_type
    sig { returns(T.nilable(String)) }
    attr_reader :format
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :service_discovery

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(CarrierService))
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
        T.cast(result[0], T.nilable(CarrierService))
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
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[CarrierService])
      end
      def all(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[CarrierService])
      end

    end

  end
end
