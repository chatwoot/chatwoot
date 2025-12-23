# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class CollectionListing < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @body_html = T.let(nil, T.nilable(String))
      @collection_id = T.let(nil, T.nilable(Integer))
      @default_product_image = T.let(nil, T.nilable(T::Array[T.untyped]))
      @handle = T.let(nil, T.nilable(String))
      @image = T.let(nil, T.nilable(Image))
      @published_at = T.let(nil, T.nilable(String))
      @sort_order = T.let(nil, T.nilable(String))
      @title = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      image: Image
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:collection_id], path: "collection_listings/<collection_id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "collection_listings.json"},
      {http_method: :get, operation: :get, ids: [:collection_id], path: "collection_listings/<collection_id>.json"},
      {http_method: :get, operation: :product_ids, ids: [:collection_id], path: "collection_listings/<collection_id>/product_ids.json"},
      {http_method: :put, operation: :put, ids: [:collection_id], path: "collection_listings/<collection_id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(Integer)) }
    attr_reader :collection_id
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :default_product_image
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(Image)) }
    attr_reader :image
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :sort_order
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        returns(String)
      end
      def primary_key()
        "collection_id"
      end

      sig do
        params(
          collection_id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(CollectionListing))
      end
      def find(
        collection_id:,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {collection_id: collection_id},
          params: {},
        )
        T.cast(result[0], T.nilable(CollectionListing))
      end

      sig do
        params(
          collection_id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        collection_id:,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {collection_id: collection_id},
          params: {},
        )
      end

      sig do
        params(
          limit: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[CollectionListing])
      end
      def all(
        limit: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[CollectionListing])
      end

      sig do
        params(
          collection_id: T.any(Integer, String),
          limit: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def product_ids(
        collection_id:,
        limit: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :product_ids,
          session: session,
          ids: {collection_id: collection_id},
          params: {limit: limit}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
