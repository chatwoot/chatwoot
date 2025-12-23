# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Product < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @title = T.let(nil, T.nilable(String))
      @body_html = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @handle = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @images = T.let(nil, T.nilable(T::Array[T.untyped]))
      @options = T.let(nil, T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped])))
      @product_type = T.let(nil, T.nilable(String))
      @published_at = T.let(nil, T.nilable(String))
      @published_scope = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @tags = T.let(nil, T.nilable(T.any(String, T::Array[T.untyped])))
      @template_suffix = T.let(nil, T.nilable(String))
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
      {http_method: :delete, operation: :delete, ids: [:id], path: "products/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "products/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "products.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "products/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "products.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "products/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Array[Image])) }
    attr_reader :images
    sig { returns(T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]]))) }
    attr_reader :options
    sig { returns(T.nilable(String)) }
    attr_reader :product_type
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :published_scope
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(T.any(String, T::Array[String]))) }
    attr_reader :tags
    sig { returns(T.nilable(String)) }
    attr_reader :template_suffix
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(T::Array[Variant])) }
    attr_reader :variants
    sig { returns(T.nilable(String)) }
    attr_reader :vendor

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Product))
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
        T.cast(result[0], T.nilable(Product))
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
          ids: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          title: T.untyped,
          vendor: T.untyped,
          handle: T.untyped,
          product_type: T.untyped,
          status: T.untyped,
          collection_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          published_status: T.untyped,
          fields: T.untyped,
          presentment_currencies: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Product])
      end
      def all(
        ids: nil,
        limit: nil,
        since_id: nil,
        title: nil,
        vendor: nil,
        handle: nil,
        product_type: nil,
        status: nil,
        collection_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        published_status: nil,
        fields: nil,
        presentment_currencies: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {ids: ids, limit: limit, since_id: since_id, title: title, vendor: vendor, handle: handle, product_type: product_type, status: status, collection_id: collection_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status, fields: fields, presentment_currencies: presentment_currencies}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Product])
      end

      sig do
        params(
          vendor: T.untyped,
          product_type: T.untyped,
          collection_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          published_status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        vendor: nil,
        product_type: nil,
        collection_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        published_status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {vendor: vendor, product_type: product_type, collection_id: collection_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
