# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Event < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @arguments = T.let(nil, T.nilable(T::Array[T.untyped]))
      @body = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @description = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @message = T.let(nil, T.nilable(String))
      @path = T.let(nil, T.nilable(String))
      @subject_id = T.let(nil, T.nilable(Integer))
      @subject_type = T.let(nil, T.nilable(String))
      @verb = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [], path: "events/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "events.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "events/<id>.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/events.json"},
      {http_method: :get, operation: :get, ids: [:product_id], path: "products/<product_id>/events.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :arguments
    sig { returns(T.nilable(String)) }
    attr_reader :body
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :description
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :message
    sig { returns(T.nilable(String)) }
    attr_reader :path
    sig { returns(T.nilable(Integer)) }
    attr_reader :subject_id
    sig { returns(T.nilable(String)) }
    attr_reader :subject_type
    sig { returns(T.nilable(String)) }
    attr_reader :verb

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Event))
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
        T.cast(result[0], T.nilable(Event))
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          product_id: T.nilable(T.any(Integer, String)),
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          filter: T.untyped,
          verb: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Event])
      end
      def all(
        order_id: nil,
        product_id: nil,
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        filter: nil,
        verb: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {order_id: order_id, product_id: product_id},
          params: {limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, filter: filter, verb: verb, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Event])
      end

      sig do
        params(
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        created_at_min: nil,
        created_at_max: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {created_at_min: created_at_min, created_at_max: created_at_max}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
