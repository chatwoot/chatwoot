# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Article < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @author = T.let(nil, T.nilable(String))
      @blog_id = T.let(nil, T.nilable(Integer))
      @body_html = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @handle = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @image = T.let(nil, T.nilable(T.any(String, T::Hash[T.untyped, T.untyped])))
      @metafields = T.let(nil, T.nilable(T::Array[T.untyped]))
      @published = T.let(nil, T.nilable(T::Boolean))
      @published_at = T.let(nil, T.nilable(String))
      @summary_html = T.let(nil, T.nilable(String))
      @tags = T.let(nil, T.nilable(String))
      @template_suffix = T.let(nil, T.nilable(String))
      @title = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({
      metafields: Metafield
    }, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:blog_id, :id], path: "blogs/<blog_id>/articles/<id>.json"},
      {http_method: :get, operation: :authors, ids: [], path: "articles/authors.json"},
      {http_method: :get, operation: :count, ids: [:blog_id], path: "blogs/<blog_id>/articles/count.json"},
      {http_method: :get, operation: :get, ids: [:blog_id], path: "blogs/<blog_id>/articles.json"},
      {http_method: :get, operation: :get, ids: [:blog_id, :id], path: "blogs/<blog_id>/articles/<id>.json"},
      {http_method: :get, operation: :tags, ids: [], path: "articles/tags.json"},
      {http_method: :get, operation: :tags, ids: [:blog_id], path: "blogs/<blog_id>/articles/tags.json"},
      {http_method: :post, operation: :post, ids: [:blog_id], path: "blogs/<blog_id>/articles.json"},
      {http_method: :put, operation: :put, ids: [:blog_id, :id], path: "blogs/<blog_id>/articles/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :author
    sig { returns(T.nilable(Integer)) }
    attr_reader :blog_id
    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :handle
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T.any(String, T::Hash[T.untyped, T.untyped]))) }
    attr_reader :image
    sig { returns(T.nilable(T::Array[Metafield])) }
    attr_reader :metafields
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :published
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :summary_html
    sig { returns(T.nilable(String)) }
    attr_reader :tags
    sig { returns(T.nilable(String)) }
    attr_reader :template_suffix
    sig { returns(T.nilable(String)) }
    attr_reader :title
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          blog_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Article))
      end
      def find(
        id:,
        blog_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, blog_id: blog_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Article))
      end

      sig do
        params(
          id: T.any(Integer, String),
          blog_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        blog_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, blog_id: blog_id},
          params: {},
        )
      end

      sig do
        params(
          blog_id: T.nilable(T.any(Integer, String)),
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          published_status: T.untyped,
          handle: T.untyped,
          tag: T.untyped,
          author: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Article])
      end
      def all(
        blog_id: nil,
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        published_status: nil,
        handle: nil,
        tag: nil,
        author: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {blog_id: blog_id},
          params: {limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status, handle: handle, tag: tag, author: author, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Article])
      end

      sig do
        params(
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def authors(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :authors,
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          blog_id: T.nilable(T.any(Integer, String)),
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
        blog_id: nil,
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
          ids: {blog_id: blog_id},
          params: {created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          blog_id: T.nilable(T.any(Integer, String)),
          limit: T.untyped,
          popular: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def tags(
        blog_id: nil,
        limit: nil,
        popular: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :tags,
          session: session,
          ids: {blog_id: blog_id},
          params: {limit: limit, popular: popular}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
