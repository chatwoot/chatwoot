# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class PriceRule < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @allocation_limit = T.let(nil, T.nilable(Integer))
      @allocation_method = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @customer_segment_prerequisite_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @customer_selection = T.let(nil, T.nilable(String))
      @ends_at = T.let(nil, T.nilable(String))
      @entitled_collection_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @entitled_country_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @entitled_product_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @entitled_variant_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @id = T.let(nil, T.nilable(Integer))
      @once_per_customer = T.let(nil, T.nilable(T::Boolean))
      @prerequisite_collection_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @prerequisite_customer_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @prerequisite_product_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @prerequisite_quantity_range = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @prerequisite_shipping_price_range = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @prerequisite_subtotal_range = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @prerequisite_to_entitlement_purchase = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @prerequisite_to_entitlement_quantity_ratio = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @prerequisite_variant_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @starts_at = T.let(nil, T.nilable(String))
      @target_selection = T.let(nil, T.nilable(String))
      @target_type = T.let(nil, T.nilable(String))
      @title = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @usage_limit = T.let(nil, T.nilable(Integer))
      @value = T.let(nil, T.nilable(String))
      @value_type = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "price_rules/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "price_rules/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "price_rules.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "price_rules/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "price_rules.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "price_rules/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :allocation_limit
    sig { returns(T.nilable(String)) }
    attr_reader :allocation_method
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :customer_segment_prerequisite_ids
    sig { returns(T.nilable(String)) }
    attr_reader :customer_selection
    sig { returns(T.nilable(String)) }
    attr_reader :ends_at
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :entitled_collection_ids
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :entitled_country_ids
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :entitled_product_ids
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :entitled_variant_ids
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :once_per_customer
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :prerequisite_collection_ids
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :prerequisite_customer_ids
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :prerequisite_product_ids
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :prerequisite_quantity_range
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :prerequisite_shipping_price_range
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :prerequisite_subtotal_range
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :prerequisite_to_entitlement_purchase
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :prerequisite_to_entitlement_quantity_ratio
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :prerequisite_variant_ids
    sig { returns(T.nilable(String)) }
    attr_reader :starts_at
    sig { returns(T.nilable(String)) }
    attr_reader :target_selection
    sig { returns(T.nilable(String)) }
    attr_reader :target_type
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :usage_limit
    sig { returns(T.nilable(String)) }
    attr_reader :value
    sig { returns(T.nilable(String)) }
    attr_reader :value_type

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(PriceRule))
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
        T.cast(result[0], T.nilable(PriceRule))
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
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          starts_at_min: T.untyped,
          starts_at_max: T.untyped,
          ends_at_min: T.untyped,
          ends_at_max: T.untyped,
          times_used: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[PriceRule])
      end
      def all(
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        starts_at_min: nil,
        starts_at_max: nil,
        ends_at_min: nil,
        ends_at_max: nil,
        times_used: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, starts_at_min: starts_at_min, starts_at_max: starts_at_max, ends_at_min: ends_at_min, ends_at_max: ends_at_max, times_used: times_used}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[PriceRule])
      end

      sig do
        params(
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
