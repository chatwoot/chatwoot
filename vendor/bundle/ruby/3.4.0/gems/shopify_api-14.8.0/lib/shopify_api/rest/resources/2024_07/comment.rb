# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Comment < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @article_id = T.let(nil, T.nilable(Integer))
      @author = T.let(nil, T.nilable(String))
      @blog_id = T.let(nil, T.nilable(Integer))
      @body = T.let(nil, T.nilable(String))
      @body_html = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @email = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @ip = T.let(nil, T.nilable(String))
      @published_at = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @user_agent = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [], path: "comments/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "comments.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "comments/<id>.json"},
      {http_method: :post, operation: :approve, ids: [:id], path: "comments/<id>/approve.json"},
      {http_method: :post, operation: :not_spam, ids: [:id], path: "comments/<id>/not_spam.json"},
      {http_method: :post, operation: :post, ids: [], path: "comments.json"},
      {http_method: :post, operation: :remove, ids: [:id], path: "comments/<id>/remove.json"},
      {http_method: :post, operation: :restore, ids: [:id], path: "comments/<id>/restore.json"},
      {http_method: :post, operation: :spam, ids: [:id], path: "comments/<id>/spam.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "comments/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :article_id
    sig { returns(T.nilable(String)) }
    attr_reader :author
    sig { returns(T.nilable(Integer)) }
    attr_reader :blog_id
    sig { returns(T.nilable(String)) }
    attr_reader :body
    sig { returns(T.nilable(String)) }
    attr_reader :body_html
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :ip
    sig { returns(T.nilable(String)) }
    attr_reader :published_at
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(String)) }
    attr_reader :user_agent

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Comment))
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
        T.cast(result[0], T.nilable(Comment))
      end

      sig do
        params(
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          fields: T.untyped,
          published_status: T.untyped,
          status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Comment])
      end
      def all(
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        fields: nil,
        published_status: nil,
        status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, fields: fields, published_status: published_status, status: status}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Comment])
      end

      sig do
        params(
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          published_at_min: T.untyped,
          published_at_max: T.untyped,
          published_status: T.untyped,
          status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        published_at_min: nil,
        published_at_max: nil,
        published_status: nil,
        status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, published_at_min: published_at_min, published_at_max: published_at_max, published_status: published_status, status: status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def approve(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :approve,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def not_spam(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :not_spam,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def remove(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :remove,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def restore(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :restore,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def spam(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :spam,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
