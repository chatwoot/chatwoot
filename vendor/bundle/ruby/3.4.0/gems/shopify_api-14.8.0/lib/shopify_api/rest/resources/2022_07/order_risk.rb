# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class OrderRisk < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @cause_cancel = T.let(nil, T.nilable(T::Boolean))
      @checkout_id = T.let(nil, T.nilable(Integer))
      @display = T.let(nil, T.nilable(T::Boolean))
      @id = T.let(nil, T.nilable(Integer))
      @merchant_message = T.let(nil, T.nilable(String))
      @message = T.let(nil, T.nilable(String))
      @order_id = T.let(nil, T.nilable(Integer))
      @recommendation = T.let(nil, T.nilable(String))
      @score = T.let(nil, T.nilable(String))
      @source = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:order_id, :id], path: "orders/<order_id>/risks/<id>.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/risks.json"},
      {http_method: :get, operation: :get, ids: [:order_id, :id], path: "orders/<order_id>/risks/<id>.json"},
      {http_method: :post, operation: :post, ids: [:order_id], path: "orders/<order_id>/risks.json"},
      {http_method: :put, operation: :put, ids: [:order_id, :id], path: "orders/<order_id>/risks/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :cause_cancel
    sig { returns(T.nilable(Integer)) }
    attr_reader :checkout_id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :display
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :merchant_message
    sig { returns(T.nilable(String)) }
    attr_reader :message
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(String)) }
    attr_reader :recommendation
    sig { returns(T.nilable(String)) }
    attr_reader :score
    sig { returns(T.nilable(String)) }
    attr_reader :source

    class << self
      sig do
        returns(String)
      end
      def json_body_name()
        "risk"
      end

      sig do
        returns(T::Array[String])
      end
      def json_response_body_names()
        [
          "risk"
        ]
      end

      sig do
        params(
          id: T.any(Integer, String),
          order_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.nilable(OrderRisk))
      end
      def find(
        id:,
        order_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, order_id: order_id},
          params: {},
        )
        T.cast(result[0], T.nilable(OrderRisk))
      end

      sig do
        params(
          id: T.any(Integer, String),
          order_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        order_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, order_id: order_id},
          params: {},
        )
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[OrderRisk])
      end
      def all(
        order_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {order_id: order_id},
          params: {}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[OrderRisk])
      end

    end

  end
end
