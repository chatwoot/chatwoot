# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class InventoryItem < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @cost = T.let(nil, T.nilable(String))
      @country_code_of_origin = T.let(nil, T.nilable(String))
      @country_harmonized_system_codes = T.let(nil, T.nilable(T::Array[T.untyped]))
      @created_at = T.let(nil, T.nilable(String))
      @harmonized_system_code = T.let(nil, T.nilable(T.any(Integer, String)))
      @id = T.let(nil, T.nilable(Integer))
      @province_code_of_origin = T.let(nil, T.nilable(String))
      @requires_shipping = T.let(nil, T.nilable(T::Boolean))
      @sku = T.let(nil, T.nilable(String))
      @tracked = T.let(nil, T.nilable(T::Boolean))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [], path: "inventory_items.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "inventory_items/<id>.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "inventory_items/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :cost
    sig { returns(T.nilable(String)) }
    attr_reader :country_code_of_origin
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :country_harmonized_system_codes
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(T.any(Integer, String))) }
    attr_reader :harmonized_system_code
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :province_code_of_origin
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :requires_shipping
    sig { returns(T.nilable(String)) }
    attr_reader :sku
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :tracked
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(InventoryItem))
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
        T.cast(result[0], T.nilable(InventoryItem))
      end

      sig do
        params(
          ids: T.untyped,
          limit: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[InventoryItem])
      end
      def all(
        ids: nil,
        limit: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {ids: ids, limit: limit}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[InventoryItem])
      end

    end

  end
end
