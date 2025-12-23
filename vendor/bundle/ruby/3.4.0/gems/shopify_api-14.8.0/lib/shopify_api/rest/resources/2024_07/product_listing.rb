# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class ProductListing < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @body_html = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @handle = T.let(nil, T.nilable(String))
      @images = T.let(nil, T.nilable(T::Array[T.untyped]))
      @options = T.let(nil, T.nilable(T::Array[T.untyped]))
      @product_id = T.let(nil, T.nilable(Integer))
      @product_type = T.let(nil, T.nilable(String))
      @published_at = T.let(nil, T.nilable(String))
      @tags = T.let(nil, T.nilable(String))
      @title = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @variants = T.let(nil, T.nilable(T::Array[T.untyped]))
      @vendor = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({
      images: Image,
      variants: Variant
    }, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:product_id], path: "product_listings/<product_id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "product_listings/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "product_listings.json"},
      {http_method: :get, operation: :get, ids: [:product_id], path: "product_listings/<product_id>.json"},
      {http_method: :get, operation: :product_ids, ids: [], path: "product_listings/product_ids.json"},
      {http_method: :put, operation: :put, ids: [:product_id], path: "product_listings/<product_id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(T::Array[Image])) }
    attr_reader :images
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :options
    sig { returns(T.nilable(Integer)) }
    attr_reader :product_id
    sig { returns(T.nilable(String)) }
    attr_reader :product_type
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :tags
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(T::Array[Variant])) }
    attr_reader :variants
    sig { returns(T.nilable(String)) }
    attr_reader :vendor

    class << self
      sig do
        returns(String)
      end
      def primary_key()
        "product_id"
      end

      sig do
        params(
          product_id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(ProductListing))
      end
      def find(
        product_id:,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {product_id: product_id},
          params: {},
        )
        T.cast(result[0], T.nilable(ProductListing))
      end

      sig do
        params(
          product_id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        product_id:,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {product_id: product_id},
          params: {},
        )
      end

      sig do
        params(
          product_ids: T.untyped,
          limit: T.untyped,
          collection_id: T.untyped,
          updated_at_min: T.untyped,
          handle: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[ProductListing])
      end
      def all(
        product_ids: nil,
        limit: nil,
        collection_id: nil,
        updated_at_min: nil,
        handle: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {product_ids: product_ids, limit: limit, collection_id: collection_id, updated_at_min: updated_at_min, handle: handle}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[ProductListing])
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

      sig do
        params(
          limit: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def product_ids(
        limit: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :product_ids,
          session: session,
          ids: {},
          params: {limit: limit}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
