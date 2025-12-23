# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Payment < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @checkout = T.let(nil, T.nilable(Checkout))
      @credit_card = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @id = T.let(nil, T.nilable(Integer))
      @next_action = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @payment_processing_error_message = T.let(nil, T.nilable(String))
      @transaction = T.let(nil, T.nilable(Transaction))
      @unique_token = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      transaction: Transaction,
      checkout: Checkout
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [:checkout_id, :id], path: "checkouts/<checkout_id>/payments/<id>.json"},
      {http_method: :post, operation: :post, ids: [:checkout_id], path: "checkouts/<checkout_id>/payments.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Checkout)) }
    attr_reader :checkout
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :credit_card
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :next_action
    sig { returns(T.nilable(String)) }
    attr_reader :payment_processing_error_message
    sig { returns(T.nilable(Transaction)) }
    attr_reader :transaction
    sig { returns(T.nilable(String)) }
    attr_reader :unique_token

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          checkout_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.nilable(Payment))
      end
      def find(
        id:,
        checkout_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, checkout_id: checkout_id},
          params: {},
        )
        T.cast(result[0], T.nilable(Payment))
      end

    end

    sig do
      returns(T.untyped)
    end
    def checkout_id()
      @checkout&.token
    end

    sig do
      params(
        val: T.untyped
      ).void
    end
    def checkout_id=(val)
      @checkout = @checkout || Checkout.new(session: @session)
      T.unsafe(@checkout).token = val
    end

  end
end
