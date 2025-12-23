# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class GiftCardAdjustment < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @amount = T.let(nil, T.nilable(Float))
      @api_client_id = T.let(nil, T.nilable(Integer))
      @created_at = T.let(nil, T.nilable(String))
      @gift_card_id = T.let(nil, T.nilable(Integer))
      @id = T.let(nil, T.nilable(Integer))
      @note = T.let(nil, T.nilable(String))
      @number = T.let(nil, T.nilable(Integer))
      @order_transaction_id = T.let(nil, T.nilable(Integer))
      @processed_at = T.let(nil, T.nilable(String))
      @remote_transaction_ref = T.let(nil, T.nilable(String))
      @remote_transaction_url = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [:gift_card_id], path: "gift_cards/<gift_card_id>/adjustments.json"},
      {http_method: :get, operation: :get, ids: [:gift_card_id, :id], path: "gift_cards/<gift_card_id>/adjustments/<id>.json"},
      {http_method: :post, operation: :post, ids: [:gift_card_id], path: "gift_cards/<gift_card_id>/adjustments.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Float)) }
    attr_reader :amount
    sig { returns(T.nilable(Integer)) }
    attr_reader :api_client_id
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :gift_card_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(Integer)) }
    attr_reader :number
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_transaction_id
    sig { returns(T.nilable(String)) }
    attr_reader :processed_at
    sig { returns(T.nilable(String)) }
    attr_reader :remote_transaction_ref
    sig { returns(T.nilable(String)) }
    attr_reader :remote_transaction_url
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        returns(String)
      end
      def json_body_name()
        "adjustment"
      end

      sig do
        params(
          id: T.any(Integer, String),
          gift_card_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.nilable(GiftCardAdjustment))
      end
      def find(
        id:,
        gift_card_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, gift_card_id: gift_card_id},
          params: {},
        )
        T.cast(result[0], T.nilable(GiftCardAdjustment))
      end

      sig do
        params(
          gift_card_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[GiftCardAdjustment])
      end
      def all(
        gift_card_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {gift_card_id: gift_card_id},
          params: {}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[GiftCardAdjustment])
      end

    end

  end
end
