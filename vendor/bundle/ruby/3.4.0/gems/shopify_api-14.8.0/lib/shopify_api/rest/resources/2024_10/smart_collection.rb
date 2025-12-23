# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class SmartCollection < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @rules = T.let(nil, T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped])))
      @title = T.let(nil, T.nilable(String))
      @body_html = T.let(nil, T.nilable(String))
      @disjunctive = T.let(nil, T.nilable(T::Boolean))
      @handle = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @image = T.let(nil, T.nilable(T.any(String, T::Hash[T.untyped, T.untyped])))
      @published_at = T.let(nil, T.nilable(String))
      @published_scope = T.let(nil, T.nilable(String))
      @sort_order = T.let(nil, T.nilable(String))
      @template_suffix = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "smart_collections/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "smart_collections/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "smart_collections.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "smart_collections/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "smart_collections.json"},
      {http_method: :put, operation: :order, ids: [:id], path: "smart_collections/<id>/order.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "smart_collections/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]]))) }
    attr_reader :rules
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :disjunctive
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T.any(String, T::Hash[T.untyped, T.untyped]))) }
    attr_reader :image
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :published_scope
    sig { returns(T.nilable(String)) }
    attr_reader :sort_order
    sig { returns(T.nilable(String)) }
    attr_reader :template_suffix
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(SmartCollection))
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
        T.cast(result[0], T.nilable(SmartCollection))
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
          ids: T.untyped,
          since_id: T.untyped,
          title: T.untyped,
          product_id: T.untyped,
          handle: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          published_status: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[SmartCollection])
      end
      def all(
        limit: nil,
        ids: nil,
        since_id: nil,
        title: nil,
        product_id: nil,
        handle: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        published_status: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, ids: ids, since_id: since_id, title: title, product_id: product_id, handle: handle, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[SmartCollection])
      end

      sig do
        params(
          title: T.untyped,
          product_id: T.untyped,
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
        title: nil,
        product_id: nil,
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
          params: {title: title, product_id: product_id, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

    sig do
      params(
        products: T.untyped,
        sort_order: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def order(
      products: nil,
      sort_order: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :put,
        operation: :order,
        session: @session,
        ids: {id: @id},
        params: {products: products, sort_order: sort_order}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
