# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Order < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @app_id = T.let(nil, T.nilable(Integer))
      @billing_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @browser_ip = T.let(nil, T.nilable(String))
      @buyer_accepts_marketing = T.let(nil, T.nilable(T::Boolean))
      @cancel_reason = T.let(nil, T.nilable(String))
      @cancelled_at = T.let(nil, T.nilable(String))
      @cart_token = T.let(nil, T.nilable(String))
      @checkout_token = T.let(nil, T.nilable(String))
      @client_details = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @closed_at = T.let(nil, T.nilable(String))
      @confirmation_number = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @current_subtotal_price = T.let(nil, T.nilable(String))
      @current_subtotal_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @current_total_discounts = T.let(nil, T.nilable(String))
      @current_total_discounts_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @current_total_duties_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @current_total_price = T.let(nil, T.nilable(String))
      @current_total_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @current_total_tax = T.let(nil, T.nilable(String))
      @current_total_tax_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @customer = T.let(nil, T.nilable(Customer))
      @customer_locale = T.let(nil, T.nilable(String))
      @discount_applications = T.let(nil, T.nilable(T::Array[T.untyped]))
      @discount_codes = T.let(nil, T.nilable(T::Array[T.untyped]))
      @email = T.let(nil, T.nilable(String))
      @estimated_taxes = T.let(nil, T.nilable(T::Boolean))
      @financial_status = T.let(nil, T.nilable(String))
      @fulfillment_status = T.let(nil, T.nilable(String))
      @fulfillments = T.let(nil, T.nilable(T::Array[T.untyped]))
      @gateway = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @landing_site = T.let(nil, T.nilable(String))
      @location_id = T.let(nil, T.nilable(Integer))
      @merchant_of_record_app_id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @note = T.let(nil, T.nilable(String))
      @note_attributes = T.let(nil, T.nilable(T::Array[T.untyped]))
      @number = T.let(nil, T.nilable(Integer))
      @order_number = T.let(nil, T.nilable(Integer))
      @order_status_url = T.let(nil, T.nilable(String))
      @original_total_duties_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @payment_details = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @payment_gateway_names = T.let(nil, T.nilable(T::Array[T.untyped]))
      @payment_terms = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @phone = T.let(nil, T.nilable(String))
      @presentment_currency = T.let(nil, T.nilable(String))
      @processed_at = T.let(nil, T.nilable(String))
      @processing_method = T.let(nil, T.nilable(String))
      @referring_site = T.let(nil, T.nilable(String))
      @refunds = T.let(nil, T.nilable(T::Array[T.untyped]))
      @shipping_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_lines = T.let(nil, T.nilable(T::Array[T.untyped]))
      @source_identifier = T.let(nil, T.nilable(String))
      @source_name = T.let(nil, T.nilable(String))
      @source_url = T.let(nil, T.nilable(String))
      @subtotal_price = T.let(nil, T.nilable(String))
      @subtotal_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @tags = T.let(nil, T.nilable(String))
      @tax_lines = T.let(nil, T.nilable(T::Array[T.untyped]))
      @taxes_included = T.let(nil, T.nilable(T::Boolean))
      @test = T.let(nil, T.nilable(T::Boolean))
      @token = T.let(nil, T.nilable(String))
      @total_discounts = T.let(nil, T.nilable(String))
      @total_discounts_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @total_line_items_price = T.let(nil, T.nilable(String))
      @total_line_items_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @total_outstanding = T.let(nil, T.nilable(String))
      @total_price = T.let(nil, T.nilable(String))
      @total_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @total_shipping_price_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @total_tax = T.let(nil, T.nilable(T.any(String, Float)))
      @total_tax_set = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @total_tip_received = T.let(nil, T.nilable(String))
      @total_weight = T.let(nil, T.nilable(Integer))
      @updated_at = T.let(nil, T.nilable(String))
      @user_id = T.let(nil, T.nilable(Integer))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      customer: Customer
    }, T::Hash[Symbol, Class])
    @has_many = T.let({
      discount_codes: DiscountCode,
      fulfillments: Fulfillment,
      refunds: Refund
    }, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "orders/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "orders/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "orders.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "orders/<id>.json"},
      {http_method: :post, operation: :cancel, ids: [:id], path: "orders/<id>/cancel.json"},
      {http_method: :post, operation: :close, ids: [:id], path: "orders/<id>/close.json"},
      {http_method: :post, operation: :open, ids: [:id], path: "orders/<id>/open.json"},
      {http_method: :post, operation: :post, ids: [], path: "orders.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "orders/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(Integer)) }
    attr_reader :app_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :billing_address
    sig { returns(T.nilable(String)) }
    attr_reader :browser_ip
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :buyer_accepts_marketing
    sig { returns(T.nilable(String)) }
    attr_reader :cancel_reason
    sig { returns(T.nilable(String)) }
    attr_reader :cancelled_at
    sig { returns(T.nilable(String)) }
    attr_reader :cart_token
    sig { returns(T.nilable(String)) }
    attr_reader :checkout_token
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :client_details
    sig { returns(T.nilable(String)) }
    attr_reader :closed_at
    sig { returns(T.nilable(String)) }
    attr_reader :confirmation_number
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(String)) }
    attr_reader :current_subtotal_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :current_subtotal_price_set
    sig { returns(T.nilable(String)) }
    attr_reader :current_total_discounts
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :current_total_discounts_set
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :current_total_duties_set
    sig { returns(T.nilable(String)) }
    attr_reader :current_total_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :current_total_price_set
    sig { returns(T.nilable(String)) }
    attr_reader :current_total_tax
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :current_total_tax_set
    sig { returns(T.nilable(Customer)) }
    attr_reader :customer
    sig { returns(T.nilable(String)) }
    attr_reader :customer_locale
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :discount_applications
    sig { returns(T.nilable(T::Array[DiscountCode])) }
    attr_reader :discount_codes
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :estimated_taxes
    sig { returns(T.nilable(String)) }
    attr_reader :financial_status
    sig { returns(T.nilable(String)) }
    attr_reader :fulfillment_status
    sig { returns(T.nilable(T::Array[Fulfillment])) }
    attr_reader :fulfillments
    sig { returns(T.nilable(String)) }
    attr_reader :gateway
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :landing_site
    sig { returns(T.nilable(Integer)) }
    attr_reader :location_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :merchant_of_record_app_id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :note_attributes
    sig { returns(T.nilable(Integer)) }
    attr_reader :number
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_number
    sig { returns(T.nilable(String)) }
    attr_reader :order_status_url
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :original_total_duties_set
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payment_details
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :payment_gateway_names
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payment_terms
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :presentment_currency
    sig { returns(T.nilable(String)) }
    attr_reader :processed_at
    sig { returns(T.nilable(String)) }
    attr_reader :processing_method
    sig { returns(T.nilable(String)) }
    attr_reader :referring_site
    sig { returns(T.nilable(T::Array[Refund])) }
    attr_reader :refunds
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_address
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :shipping_lines
    sig { returns(T.nilable(String)) }
    attr_reader :source_identifier
    sig { returns(T.nilable(String)) }
    attr_reader :source_name
    sig { returns(T.nilable(String)) }
    attr_reader :source_url
    sig { returns(T.nilable(String)) }
    attr_reader :subtotal_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :subtotal_price_set
    sig { returns(T.nilable(String)) }
    attr_reader :tags
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :tax_lines
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxes_included
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :test
    sig { returns(T.nilable(String)) }
    attr_reader :token
    sig { returns(T.nilable(String)) }
    attr_reader :total_discounts
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_discounts_set
    sig { returns(T.nilable(String)) }
    attr_reader :total_line_items_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_line_items_price_set
    sig { returns(T.nilable(String)) }
    attr_reader :total_outstanding
    sig { returns(T.nilable(String)) }
    attr_reader :total_price
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_price_set
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_shipping_price_set
    sig { returns(T.nilable(T.any(String, Float))) }
    attr_reader :total_tax
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :total_tax_set
    sig { returns(T.nilable(String)) }
    attr_reader :total_tip_received
    sig { returns(T.nilable(Integer)) }
    attr_reader :total_weight
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :user_id

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Order))
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
        T.cast(result[0], T.nilable(Order))
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
          ids: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          processed_at_min: T.untyped,
          processed_at_max: T.untyped,
          attribution_app_id: T.untyped,
          status: T.untyped,
          financial_status: T.untyped,
          fulfillment_status: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Order])
      end
      def all(
        ids: nil,
        limit: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        processed_at_min: nil,
        processed_at_max: nil,
        attribution_app_id: nil,
        status: nil,
        financial_status: nil,
        fulfillment_status: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {ids: ids, limit: limit, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, processed_at_min: processed_at_min, processed_at_max: processed_at_max, attribution_app_id: attribution_app_id, status: status, financial_status: financial_status, fulfillment_status: fulfillment_status, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Order])
      end

      sig do
        params(
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          status: T.untyped,
          financial_status: T.untyped,
          fulfillment_status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        status: nil,
        financial_status: nil,
        fulfillment_status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, status: status, financial_status: financial_status, fulfillment_status: fulfillment_status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

    sig do
      params(
        amount: T.untyped,
        currency: T.untyped,
        restock: T.untyped,
        reason: T.untyped,
        email: T.untyped,
        refund: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def cancel(
      amount: nil,
      currency: nil,
      restock: nil,
      reason: nil,
      email: nil,
      refund: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :cancel,
        session: @session,
        ids: {id: @id},
        params: {amount: amount, currency: currency, restock: restock, reason: reason, email: email, refund: refund}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def close(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :close,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def open(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :open,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
