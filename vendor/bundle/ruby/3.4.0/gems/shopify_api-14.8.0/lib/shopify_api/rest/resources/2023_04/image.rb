# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Image < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @created_at = T.let(nil, T.nilable(String))
      @height = T.let(nil, T.nilable(Integer))
      @id = T.let(nil, T.nilable(Integer))
      @position = T.let(nil, T.nilable(Integer))
      @product_id = T.let(nil, T.nilable(Integer))
      @src = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @variant_ids = T.let(nil, T.nilable(T::Array[T.untyped]))
      @width = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:product_id, :id], path: "products/<product_id>/images/<id>.json"},
      {http_method: :get, operation: :count, ids: [:product_id], path: "products/<product_id>/images/count.json"},
      {http_method: :get, operation: :get, ids: [:product_id], path: "products/<product_id>/images.json"},
      {http_method: :get, operation: :get, ids: [:product_id, :id], path: "products/<product_id>/images/<id>.json"},
      {http_method: :post, operation: :post, ids: [:product_id], path: "products/<product_id>/images.json"},
      {http_method: :put, operation: :put, ids: [:product_id, :id], path: "products/<product_id>/images/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :height
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Integer)) }
    attr_reader :position
    sig { returns(T.nilable(Integer)) }
    attr_reader :product_id
    sig { returns(T.nilable(String)) }
    attr_reader :src
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(T::Array[Integer])) }
    attr_reader :variant_ids
    sig { returns(T.nilable(Integer)) }
    attr_reader :width

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          product_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Image))
      end
      def find(
        id:,
        product_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, product_id: product_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Image))
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
          since_id: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Image])
      end
      def all(
        product_id: nil,
        since_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {product_id: product_id},
          params: {since_id: since_id, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Image])
      end

      sig do
        params(
          product_id: T.nilable(T.any(Integer, String)),
          since_id: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        product_id: nil,
        since_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {product_id: product_id},
          params: {since_id: since_id}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
