# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class TenderTransaction < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @amount = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @order_id = T.let(nil, T.nilable(Integer))
      @payment_details = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @payment_method = T.let(nil, T.nilable(String))
      @processed_at = T.let(nil, T.nilable(String))
      @remote_reference = T.let(nil, T.nilable(String))
      @test = T.let(nil, T.nilable(T::Boolean))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [], path: "tender_transactions.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :amount
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payment_details
    sig { returns(T.nilable(String)) }
    attr_reader :payment_method
    sig { returns(T.nilable(String)) }
    attr_reader :processed_at
    sig { returns(T.nilable(String)) }
    attr_reader :remote_reference
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :test
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          limit: T.untyped,
          since_id: T.untyped,
          processed_at_min: T.untyped,
          processed_at_max: T.untyped,
          processed_at: T.untyped,
          order: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[TenderTransaction])
      end
      def all(
        limit: nil,
        since_id: nil,
        processed_at_min: nil,
        processed_at_max: nil,
        processed_at: nil,
        order: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, since_id: since_id, processed_at_min: processed_at_min, processed_at_max: processed_at_max, processed_at: processed_at, order: order}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[TenderTransaction])
      end

    end

  end
end
