# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Variant < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @barcode = T.let(nil, T.nilable(String))
      @compare_at_price = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @fulfillment_service = T.let(nil, T.nilable(String))
      @grams = T.let(nil, T.nilable(Integer))
      @id = T.let(nil, T.nilable(Integer))
      @image_id = T.let(nil, T.nilable(Integer))
      @inventory_item_id = T.let(nil, T.nilable(Integer))
      @inventory_management = T.let(nil, T.nilable(String))
      @inventory_policy = T.let(nil, T.nilable(String))
      @inventory_quantity = T.let(nil, T.nilable(T.any(Integer, String)))
      @old_inventory_quantity = T.let(nil, T.nilable(T.any(Integer, String)))
      @option = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @position = T.let(nil, T.nilable(Integer))
      @presentment_prices = T.let(nil, T.nilable(T::Array[T.untyped]))
      @price = T.let(nil, T.nilable(String))
      @product_id = T.let(nil, T.nilable(Integer))
      @requires_shipping = T.let(nil, T.nilable(T::Boolean))
      @sku = T.let(nil, T.nilable(String))
      @tax_code = T.let(nil, T.nilable(String))
      @taxable = T.let(nil, T.nilable(T::Boolean))
      @title = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @weight = T.let(nil, T.nilable(Float))
      @weight_unit = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:product_id, :id], path: "products/<product_id>/variants/<id>.json"},
      {http_method: :get, operation: :count, ids: [:product_id], path: "products/<product_id>/variants/count.json"},
      {http_method: :get, operation: :get, ids: [:product_id], path: "products/<product_id>/variants.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "variants/<id>.json"},
      {http_method: :post, operation: :post, ids: [:product_id], path: "products/<product_id>/variants.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "variants/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])
    @read_only_attributes = T.let([
      :inventory_quantity
    ], T::Array[Symbol])

    sig { returns(T.nilable(String)) }
    attr_reader :barcode
    sig { returns(T.nilable(String)) }
    attr_reader :compare_at_price
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :fulfillment_service
    sig { returns(T.nilable(Integer)) }
    attr_reader :grams
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Integer)) }
    attr_reader :image_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :inventory_item_id
    sig { returns(T.nilable(String)) }
    attr_reader :inventory_management
    sig { returns(T.nilable(String)) }
    attr_reader :inventory_policy
    sig { returns(T.nilable(T.any(Integer, String))) }
    attr_reader :inventory_quantity
    sig { returns(T.nilable(T.any(Integer, String))) }
    attr_reader :old_inventory_quantity
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :option
    sig { returns(T.nilable(Integer)) }
    attr_reader :position
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :presentment_prices
    sig { returns(T.nilable(String)) }
    attr_reader :price
    sig { returns(T.nilable(Integer)) }
    attr_reader :product_id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :requires_shipping
    sig { returns(T.nilable(String)) }
    attr_reader :sku
    sig { returns(T.nilable(String)) }
    attr_reader :tax_code
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxable
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Float)) }
    attr_reader :weight
    sig { returns(T.nilable(String)) }
    attr_reader :weight_unit

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Variant))
      end
      def find(
        id:,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Variant))
      end

      sig do
        params(
          id: T.any(Integer, String),
          product_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        product_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, product_id: product_id},
          params: {},
        )
      end

      sig do
        params(
          product_id: T.nilable(T.any(Integer, String)),
          limit: T.untyped,
          presentment_currencies: T.untyped,
          since_id: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Variant])
      end
      def all(
        product_id: nil,
        limit: nil,
        presentment_currencies: nil,
        since_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {product_id: product_id},
          params: {limit: limit, presentment_currencies: presentment_currencies, since_id: since_id, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Variant])
      end

      sig do
        params(
          product_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        product_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {product_id: product_id},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
