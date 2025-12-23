# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Transaction < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @kind = T.let(nil, T.nilable(String))
      @amount = T.let(nil, T.nilable(String))
      @amount_rounding = T.let(nil, T.nilable(String))
      @authorization = T.let(nil, T.nilable(String))
      @authorization_expires_at = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @currency_exchange_adjustment = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @device_id = T.let(nil, T.nilable(Integer))
      @error_code = T.let(nil, T.nilable(String))
      @extended_authorization_attributes = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @gateway = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @location_id = T.let(nil, T.nilable(Integer))
      @message = T.let(nil, T.nilable(String))
      @order_id = T.let(nil, T.nilable(Integer))
      @parent_id = T.let(nil, T.nilable(Integer))
      @payment_details = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @payments_refund_attributes = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @processed_at = T.let(nil, T.nilable(String))
      @receipt = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @source_name = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @test = T.let(nil, T.nilable(T::Boolean))
      @total_unsettled_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [:order_id], path: "orders/<order_id>/transactions/count.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/transactions.json"},
      {http_method: :get, operation: :get, ids: [:order_id, :id], path: "orders/<order_id>/transactions/<id>.json"},
      {http_method: :post, operation: :post, ids: [:order_id], path: "orders/<order_id>/transactions.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :kind
    sig { returns(T.nilable(String)) }
    attr_reader :amount
    sig { returns(T.nilable(String)) }
    attr_reader :authorization
    sig { returns(T.nilable(String)) }
    attr_reader :authorization_expires_at
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :currency_exchange_adjustment
    sig { returns(T.nilable(Integer)) }
    attr_reader :device_id
    sig { returns(T.nilable(String)) }
    attr_reader :error_code
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :extended_authorization_attributes
    sig { returns(T.nilable(String)) }
    attr_reader :gateway
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Integer)) }
    attr_reader :location_id
    sig { returns(T.nilable(String)) }
    attr_reader :message
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :parent_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payment_details
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payments_refund_attributes
    sig { returns(T.nilable(String)) }
    attr_reader :processed_at
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :receipt
    sig { returns(T.nilable(String)) }
    attr_reader :source_name
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :test
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_unsettled_set
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          order_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          in_shop_currency: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Transaction))
      end
      def find(
        id:,
        order_id: nil,
        fields: nil,
        in_shop_currency: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, order_id: order_id},
          params: {fields: fields, in_shop_currency: in_shop_currency},
        )
        T.cast(result[0], T.nilable(Transaction))
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          since_id: T.untyped,
          fields: T.untyped,
          in_shop_currency: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Transaction])
      end
      def all(
        order_id: nil,
        since_id: nil,
        fields: nil,
        in_shop_currency: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {order_id: order_id},
          params: {since_id: since_id, fields: fields, in_shop_currency: in_shop_currency}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Transaction])
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        order_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {order_id: order_id},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
