# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Checkout < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @billing_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @applied_discount = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @buyer_accepts_marketing = T.let(nil, T.nilable(T::Boolean))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @customer_id = T.let(nil, T.nilable(Integer))
      @discount_code = T.let(nil, T.nilable(DiscountCode))
      @email = T.let(nil, T.nilable(String))
      @gift_cards = T.let(nil, T.nilable(T::Array[T.untyped]))
      @order = T.let(nil, T.nilable(Order))
      @payment_due = T.let(nil, T.nilable(String))
      @payment_url = T.let(nil, T.nilable(String))
      @phone = T.let(nil, T.nilable(String))
      @presentment_currency = T.let(nil, T.nilable(String))
      @requires_shipping = T.let(nil, T.nilable(T::Boolean))
      @reservation_time = T.let(nil, T.nilable(String))
      @reservation_time_left = T.let(nil, T.nilable(Integer))
      @shipping_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_line = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_rate = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @source_identifier = T.let(nil, T.nilable(String))
      @source_name = T.let(nil, T.nilable(String))
      @source_url = T.let(nil, T.nilable(String))
      @subtotal_price = T.let(nil, T.nilable(String))
      @tax_lines = T.let(nil, T.nilable(T::Array[T.untyped]))
      @taxes_included = T.let(nil, T.nilable(T::Boolean))
      @token = T.let(nil, T.nilable(String))
      @total_price = T.let(nil, T.nilable(String))
      @total_tax = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))
      @web_url = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      discount_code: DiscountCode,
      order: Order
    }, T::Hash[Symbol, Class])
    @has_many = T.let({
      gift_cards: GiftCard
    }, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [:token], path: "checkouts/<token>.json"},
      {http_method: :get, operation: :shipping_rates, ids: [:token], path: "checkouts/<token>/shipping_rates.json"},
      {http_method: :post, operation: :complete, ids: [:token], path: "checkouts/<token>/complete.json"},
      {http_method: :post, operation: :post, ids: [], path: "checkouts.json"},
      {http_method: :put, operation: :put, ids: [:token], path: "checkouts/<token>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :billing_address
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :applied_discount
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :buyer_accepts_marketing
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(Integer)) }
    attr_reader :customer_id
    sig { returns(T.nilable(DiscountCode)) }
    attr_reader :discount_code
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(T::Array[GiftCard])) }
    attr_reader :gift_cards
    sig { returns(T.nilable(Order)) }
    attr_reader :order
    sig { returns(T.nilable(String)) }
    attr_reader :payment_due
    sig { returns(T.nilable(String)) }
    attr_reader :payment_url
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :presentment_currency
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :requires_shipping
    sig { returns(T.nilable(String)) }
    attr_reader :reservation_time
    sig { returns(T.nilable(Integer)) }
    attr_reader :reservation_time_left
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_address
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_line
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_rate
    sig { returns(T.nilable(String)) }
    attr_reader :source_identifier
    sig { returns(T.nilable(String)) }
    attr_reader :source_name
    sig { returns(T.nilable(String)) }
    attr_reader :source_url
    sig { returns(T.nilable(String)) }
    attr_reader :subtotal_price
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :tax_lines
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxes_included
    sig { returns(T.nilable(String)) }
    attr_reader :token
    sig { returns(T.nilable(String)) }
    attr_reader :total_price
    sig { returns(T.nilable(String)) }
    attr_reader :total_tax
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id
    sig { returns(T.nilable(String)) }
    attr_reader :web_url

    class << self
      sig do
        returns(String)
      end
      def primary_key()
        "token"
      end

      sig do
        params(
          token: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(Checkout))
      end
      def find(
        token:,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {token: token},
          params: {},
        )
        T.cast(result[0], T.nilable(Checkout))
      end

      sig do
        params(
          token: T.any(Integer, String),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def shipping_rates(
        token:,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :shipping_rates,
          session: session,
          ids: {token: token},
          params: {}.merge(kwargs).compact,
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
    def complete(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :complete,
        session: @session,
        ids: {token: @token},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
