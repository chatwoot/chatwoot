# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class GiftCard < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @api_client_id = T.let(nil, T.nilable(Integer))
      @balance = T.let(nil, T.nilable(Balance))
      @code = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(Currency))
      @customer_id = T.let(nil, T.nilable(Integer))
      @disabled_at = T.let(nil, T.nilable(String))
      @expires_on = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @initial_value = T.let(nil, T.nilable(String))
      @last_characters = T.let(nil, T.nilable(String))
      @line_item_id = T.let(nil, T.nilable(Integer))
      @note = T.let(nil, T.nilable(String))
      @order_id = T.let(nil, T.nilable(Integer))
      @template_suffix = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      balance: Balance,
      currency: Currency
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [], path: "gift_cards/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "gift_cards.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "gift_cards/<id>.json"},
      {http_method: :get, operation: :search, ids: [], path: "gift_cards/search.json"},
      {http_method: :post, operation: :disable, ids: [:id], path: "gift_cards/<id>/disable.json"},
      {http_method: :post, operation: :post, ids: [], path: "gift_cards.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "gift_cards/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :api_client_id
    sig { returns(T.nilable(Balance)) }
    attr_reader :balance
    sig { returns(T.nilable(String)) }
    attr_reader :code
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Currency)) }
    attr_reader :currency
    sig { returns(T.nilable(Integer)) }
    attr_reader :customer_id
    sig { returns(T.nilable(String)) }
    attr_reader :disabled_at
    sig { returns(T.nilable(String)) }
    attr_reader :expires_on
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :initial_value
    sig { returns(T.nilable(String)) }
    attr_reader :last_characters
    sig { returns(T.nilable(Integer)) }
    attr_reader :line_item_id
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(String)) }
    attr_reader :template_suffix
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(GiftCard))
      end
      def find(
        id:,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id},
          params: {},
        )
        T.cast(result[0], T.nilable(GiftCard))
      end

      sig do
        params(
          status: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[GiftCard])
      end
      def all(
        status: nil,
        limit: nil,
        since_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {status: status, limit: limit, since_id: since_id, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[GiftCard])
      end

      sig do
        params(
          status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {status: status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          order: T.untyped,
          query: T.untyped,
          limit: T.untyped,
          fields: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def search(
        order: nil,
        query: nil,
        limit: nil,
        fields: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :search,
          session: session,
          ids: {},
          params: {order: order, query: query, limit: limit, fields: fields, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max}.merge(kwargs).compact,
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
    def disable(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :disable,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
