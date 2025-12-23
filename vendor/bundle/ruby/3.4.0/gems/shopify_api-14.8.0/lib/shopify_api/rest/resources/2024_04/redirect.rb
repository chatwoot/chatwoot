# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Redirect < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @id = T.let(nil, T.nilable(Integer))
      @path = T.let(nil, T.nilable(String))
      @target = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "redirects/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "redirects/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "redirects.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "redirects/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "redirects.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "redirects/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :path
    sig { returns(T.nilable(String)) }
    attr_reader :target

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Redirect))
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
        T.cast(result[0], T.nilable(Redirect))
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
          path: T.untyped,
          target: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Redirect])
      end
      def all(
        limit: nil,
        since_id: nil,
        path: nil,
        target: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, since_id: since_id, path: path, target: target, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Redirect])
      end

      sig do
        params(
          path: T.untyped,
          target: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        path: nil,
        target: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {path: path, target: target}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
