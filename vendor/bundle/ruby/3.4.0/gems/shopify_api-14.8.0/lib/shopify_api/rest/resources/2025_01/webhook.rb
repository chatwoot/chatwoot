# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Webhook < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @address = T.let(nil, T.nilable(String))
      @topic = T.let(nil, T.nilable(String))
      @api_version = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @fields = T.let(nil, T.nilable(T::Array[T.untyped]))
      @filter = T.let(nil, T.nilable(String))
      @format = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @metafield_namespaces = T.let(nil, T.nilable(T::Array[T.untyped]))
      @private_metafield_namespaces = T.let(nil, T.nilable(T::Array[T.untyped]))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "webhooks/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "webhooks/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "webhooks.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "webhooks/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "webhooks.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "webhooks/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :address
    sig { returns(T.nilable(String)) }
    attr_reader :topic
    sig { returns(T.nilable(String)) }
    attr_reader :api_version
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :fields
    sig { returns(T.nilable(String)) }
    attr_reader :format
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :metafield_namespaces
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :private_metafield_namespaces
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Webhook))
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
        T.cast(result[0], T.nilable(Webhook))
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
          address: T.untyped,
          created_at_max: T.untyped,
          created_at_min: T.untyped,
          fields: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          topic: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Webhook])
      end
      def all(
        address: nil,
        created_at_max: nil,
        created_at_min: nil,
        fields: nil,
        limit: nil,
        since_id: nil,
        topic: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {address: address, created_at_max: created_at_max, created_at_min: created_at_min, fields: fields, limit: limit, since_id: since_id, topic: topic, updated_at_min: updated_at_min, updated_at_max: updated_at_max}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Webhook])
      end

      sig do
        params(
          address: T.untyped,
          topic: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        address: nil,
        topic: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {address: address, topic: topic}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
