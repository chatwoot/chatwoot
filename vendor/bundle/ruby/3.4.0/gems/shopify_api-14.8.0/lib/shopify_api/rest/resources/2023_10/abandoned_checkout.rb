# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class AbandonedCheckout < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @abandoned_checkout_url = T.let(nil, T.nilable(String))
      @billing_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @buyer_accepts_marketing = T.let(nil, T.nilable(T::Boolean))
      @buyer_accepts_sms_marketing = T.let(nil, T.nilable(T::Boolean))
      @cart_token = T.let(nil, T.nilable(String))
      @closed_at = T.let(nil, T.nilable(String))
      @completed_at = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(Currency))
      @customer = T.let(nil, T.nilable(Customer))
      @customer_locale = T.let(nil, T.nilable(String))
      @device_id = T.let(nil, T.nilable(Integer))
      @discount_codes = T.let(nil, T.nilable(T::Array[T.untyped]))
      @email = T.let(nil, T.nilable(String))
      @gateway = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @landing_site = T.let(nil, T.nilable(String))
      @line_items = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @location_id = T.let(nil, T.nilable(Integer))
      @note = T.let(nil, T.nilable(String))
      @phone = T.let(nil, T.nilable(String))
      @presentment_currency = T.let(nil, T.nilable(String))
      @referring_site = T.let(nil, T.nilable(String))
      @shipping_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_lines = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @sms_marketing_phone = T.let(nil, T.nilable(String))
      @source_name = T.let(nil, T.nilable(String))
      @subtotal_price = T.let(nil, T.nilable(String))
      @tax_lines = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @taxes_included = T.let(nil, T.nilable(T::Boolean))
      @token = T.let(nil, T.nilable(String))
      @total_discounts = T.let(nil, T.nilable(String))
      @total_duties = T.let(nil, T.nilable(String))
      @total_line_items_price = T.let(nil, T.nilable(String))
      @total_price = T.let(nil, T.nilable(String))
      @total_tax = T.let(nil, T.nilable(String))
      @total_weight = T.let(nil, T.nilable(Integer))
      @updated_at = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      currency: Currency,
      customer: Customer
    }, T::Hash[Symbol, Class])
    @has_many = T.let({
      discount_codes: DiscountCode
    }, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :checkouts, ids: [], path: "checkouts.json"},
      {http_method: :get, operation: :checkouts, ids: [], path: "checkouts.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :abandoned_checkout_url
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :billing_address
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :buyer_accepts_marketing
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :buyer_accepts_sms_marketing
    sig { returns(T.nilable(String)) }
    attr_reader :cart_token
    sig { returns(T.nilable(String)) }
    attr_reader :closed_at
    sig { returns(T.nilable(String)) }
    attr_reader :completed_at
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Currency)) }
    attr_reader :currency
    sig { returns(T.nilable(Customer)) }
    attr_reader :customer
    sig { returns(T.nilable(String)) }
    attr_reader :customer_locale
    sig { returns(T.nilable(Integer)) }
    attr_reader :device_id
    sig { returns(T.nilable(T::Array[DiscountCode])) }
    attr_reader :discount_codes
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(String)) }
    attr_reader :gateway
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :landing_site
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :line_items
    sig { returns(T.nilable(Integer)) }
    attr_reader :location_id
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :presentment_currency
    sig { returns(T.nilable(String)) }
    attr_reader :referring_site
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_address
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_lines
    sig { returns(T.nilable(String)) }
    attr_reader :sms_marketing_phone
    sig { returns(T.nilable(String)) }
    attr_reader :source_name
    sig { returns(T.nilable(String)) }
    attr_reader :subtotal_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :tax_lines
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxes_included
    sig { returns(T.nilable(String)) }
    attr_reader :token
    sig { returns(T.nilable(String)) }
    attr_reader :total_discounts
    sig { returns(T.nilable(String)) }
    attr_reader :total_duties
    sig { returns(T.nilable(String)) }
    attr_reader :total_line_items_price
    sig { returns(T.nilable(String)) }
    attr_reader :total_price
    sig { returns(T.nilable(String)) }
    attr_reader :total_tax
    sig { returns(T.nilable(Integer)) }
    attr_reader :total_weight
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          status: T.untyped,
          limit: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def checkouts(
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        status: nil,
        limit: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :checkouts,
          session: session,
          ids: {},
          params: {since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, status: status, limit: limit}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
