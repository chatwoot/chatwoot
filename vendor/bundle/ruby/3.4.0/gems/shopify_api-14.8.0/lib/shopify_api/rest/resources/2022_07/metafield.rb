# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Metafield < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @key = T.let(nil, T.nilable(String))
      @namespace = T.let(nil, T.nilable(String))
      @value = T.let(nil, T.nilable(T.any(String, Integer, Float, T::Boolean, String)))
      @article_id = T.let(nil, T.nilable(Integer))
      @blog_id = T.let(nil, T.nilable(Integer))
      @collection_id = T.let(nil, T.nilable(Integer))
      @created_at = T.let(nil, T.nilable(String))
      @customer_id = T.let(nil, T.nilable(Integer))
      @description = T.let(nil, T.nilable(String))
      @draft_order_id = T.let(nil, T.nilable(Integer))
      @id = T.let(nil, T.nilable(Integer))
      @order_id = T.let(nil, T.nilable(Integer))
      @owner_id = T.let(nil, T.nilable(Integer))
      @owner_resource = T.let(nil, T.nilable(String))
      @page_id = T.let(nil, T.nilable(Integer))
      @product_id = T.let(nil, T.nilable(Integer))
      @product_image_id = T.let(nil, T.nilable(Integer))
      @type = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @variant_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:article_id, :id], path: "articles/<article_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:collection_id, :id], path: "collections/<collection_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:customer_id, :id], path: "customers/<customer_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:draft_order_id, :id], path: "draft_orders/<draft_order_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:id], path: "metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:order_id, :id], path: "orders/<order_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:page_id, :id], path: "pages/<page_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:product_image_id, :id], path: "product_images/<product_image_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:product_id, :id], path: "products/<product_id>/metafields/<id>.json"},
      {http_method: :delete, operation: :delete, ids: [:variant_id, :id], path: "variants/<variant_id>/metafields/<id>.json"},
      {http_method: :get, operation: :count, ids: [:article_id], path: "articles/<article_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:blog_id], path: "blogs/<blog_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:blog_id], path: "blogs/<blog_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:collection_id], path: "collections/<collection_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:customer_id], path: "customers/<customer_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:draft_order_id], path: "draft_orders/<draft_order_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [], path: "metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:order_id], path: "orders/<order_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:page_id], path: "pages/<page_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:product_image_id], path: "product_images/<product_image_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:product_id], path: "products/<product_id>/metafields/count.json"},
      {http_method: :get, operation: :count, ids: [:variant_id], path: "variants/<variant_id>/metafields/count.json"},
      {http_method: :get, operation: :get, ids: [:article_id], path: "articles/<article_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:article_id, :id], path: "articles/<article_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:blog_id], path: "blogs/<blog_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:blog_id], path: "blogs/<blog_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:collection_id], path: "collections/<collection_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:collection_id, :id], path: "collections/<collection_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:customer_id], path: "customers/<customer_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:customer_id, :id], path: "customers/<customer_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:draft_order_id], path: "draft_orders/<draft_order_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:draft_order_id, :id], path: "draft_orders/<draft_order_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "metafields.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:order_id, :id], path: "orders/<order_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:page_id], path: "pages/<page_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:page_id, :id], path: "pages/<page_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:product_image_id], path: "product_images/<product_image_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:product_image_id, :id], path: "product_images/<product_image_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:product_id], path: "products/<product_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:product_id, :id], path: "products/<product_id>/metafields/<id>.json"},
      {http_method: :get, operation: :get, ids: [:variant_id], path: "variants/<variant_id>/metafields.json"},
      {http_method: :get, operation: :get, ids: [:variant_id, :id], path: "variants/<variant_id>/metafields/<id>.json"},
      {http_method: :post, operation: :post, ids: [:article_id], path: "articles/<article_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:blog_id], path: "blogs/<blog_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:blog_id], path: "blogs/<blog_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:collection_id], path: "collections/<collection_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:customer_id], path: "customers/<customer_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:draft_order_id], path: "draft_orders/<draft_order_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [], path: "metafields.json"},
      {http_method: :post, operation: :post, ids: [:order_id], path: "orders/<order_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:page_id], path: "pages/<page_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:product_image_id], path: "product_images/<product_image_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:product_id], path: "products/<product_id>/metafields.json"},
      {http_method: :post, operation: :post, ids: [:variant_id], path: "variants/<variant_id>/metafields.json"},
      {http_method: :put, operation: :put, ids: [:article_id, :id], path: "articles/<article_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:blog_id, :id], path: "blogs/<blog_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:collection_id, :id], path: "collections/<collection_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:customer_id, :id], path: "customers/<customer_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:draft_order_id, :id], path: "draft_orders/<draft_order_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:order_id, :id], path: "orders/<order_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:page_id, :id], path: "pages/<page_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:product_image_id, :id], path: "product_images/<product_image_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:product_id, :id], path: "products/<product_id>/metafields/<id>.json"},
      {http_method: :put, operation: :put, ids: [:variant_id, :id], path: "variants/<variant_id>/metafields/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :key
    sig { returns(T.nilable(String)) }
    attr_reader :namespace
    sig { returns(T.nilable(T.any(String, Integer, Float, T::Boolean, String))) }
    attr_reader :value
    sig { returns(T.nilable(Integer)) }
    attr_reader :article_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :blog_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :collection_id
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :customer_id
    sig { returns(T.nilable(String)) }
    attr_reader :description
    sig { returns(T.nilable(Integer)) }
    attr_reader :draft_order_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :owner_id
    sig { returns(T.nilable(String)) }
    attr_reader :owner_resource
    sig { returns(T.nilable(Integer)) }
    attr_reader :page_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :product_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :product_image_id
    sig { returns(T.nilable(String)) }
    attr_reader :type
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :variant_id

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          article_id: T.nilable(T.any(Integer, String)),
          blog_id: T.nilable(T.any(Integer, String)),
          collection_id: T.nilable(T.any(Integer, String)),
          customer_id: T.nilable(T.any(Integer, String)),
          draft_order_id: T.nilable(T.any(Integer, String)),
          order_id: T.nilable(T.any(Integer, String)),
          page_id: T.nilable(T.any(Integer, String)),
          product_image_id: T.nilable(T.any(Integer, String)),
          product_id: T.nilable(T.any(Integer, String)),
          variant_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Metafield))
      end
      def find(
        id:,
        article_id: nil,
        blog_id: nil,
        collection_id: nil,
        customer_id: nil,
        draft_order_id: nil,
        order_id: nil,
        page_id: nil,
        product_image_id: nil,
        product_id: nil,
        variant_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, article_id: article_id, blog_id: blog_id, collection_id: collection_id, customer_id: customer_id, draft_order_id: draft_order_id, order_id: order_id, page_id: page_id, product_image_id: product_image_id, product_id: product_id, variant_id: variant_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Metafield))
      end

      sig do
        params(
          id: T.any(Integer, String),
          article_id: T.nilable(T.any(Integer, String)),
          blog_id: T.nilable(T.any(Integer, String)),
          collection_id: T.nilable(T.any(Integer, String)),
          customer_id: T.nilable(T.any(Integer, String)),
          draft_order_id: T.nilable(T.any(Integer, String)),
          order_id: T.nilable(T.any(Integer, String)),
          page_id: T.nilable(T.any(Integer, String)),
          product_image_id: T.nilable(T.any(Integer, String)),
          product_id: T.nilable(T.any(Integer, String)),
          variant_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        article_id: nil,
        blog_id: nil,
        collection_id: nil,
        customer_id: nil,
        draft_order_id: nil,
        order_id: nil,
        page_id: nil,
        product_image_id: nil,
        product_id: nil,
        variant_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, article_id: article_id, blog_id: blog_id, collection_id: collection_id, customer_id: customer_id, draft_order_id: draft_order_id, order_id: order_id, page_id: page_id, product_image_id: product_image_id, product_id: product_id, variant_id: variant_id},
          params: {},
        )
      end

      sig do
        params(
          article_id: T.nilable(T.any(Integer, String)),
          blog_id: T.nilable(T.any(Integer, String)),
          collection_id: T.nilable(T.any(Integer, String)),
          customer_id: T.nilable(T.any(Integer, String)),
          draft_order_id: T.nilable(T.any(Integer, String)),
          order_id: T.nilable(T.any(Integer, String)),
          page_id: T.nilable(T.any(Integer, String)),
          product_image_id: T.nilable(T.any(Integer, String)),
          product_id: T.nilable(T.any(Integer, String)),
          variant_id: T.nilable(T.any(Integer, String)),
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          namespace: T.untyped,
          key: T.untyped,
          type: T.untyped,
          fields: T.untyped,
          metafield: T.nilable(T::Hash[T.untyped, T.untyped]),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Metafield])
      end
      def all(
        article_id: nil,
        blog_id: nil,
        collection_id: nil,
        customer_id: nil,
        draft_order_id: nil,
        order_id: nil,
        page_id: nil,
        product_image_id: nil,
        product_id: nil,
        variant_id: nil,
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        namespace: nil,
        key: nil,
        type: nil,
        fields: nil,
        metafield: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {article_id: article_id, blog_id: blog_id, collection_id: collection_id, customer_id: customer_id, draft_order_id: draft_order_id, order_id: order_id, page_id: page_id, product_image_id: product_image_id, product_id: product_id, variant_id: variant_id},
          params: {limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, namespace: namespace, key: key, type: type, fields: fields, metafield: metafield}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Metafield])
      end

      sig do
        params(
          article_id: T.nilable(T.any(Integer, String)),
          blog_id: T.nilable(T.any(Integer, String)),
          collection_id: T.nilable(T.any(Integer, String)),
          customer_id: T.nilable(T.any(Integer, String)),
          draft_order_id: T.nilable(T.any(Integer, String)),
          order_id: T.nilable(T.any(Integer, String)),
          page_id: T.nilable(T.any(Integer, String)),
          product_image_id: T.nilable(T.any(Integer, String)),
          product_id: T.nilable(T.any(Integer, String)),
          variant_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        article_id: nil,
        blog_id: nil,
        collection_id: nil,
        customer_id: nil,
        draft_order_id: nil,
        order_id: nil,
        page_id: nil,
        product_image_id: nil,
        product_id: nil,
        variant_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {article_id: article_id, blog_id: blog_id, collection_id: collection_id, customer_id: customer_id, draft_order_id: draft_order_id, order_id: order_id, page_id: page_id, product_image_id: product_image_id, product_id: product_id, variant_id: variant_id},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
