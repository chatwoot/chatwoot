# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class DraftOrder < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @applied_discount = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @billing_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @completed_at = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @customer = T.let(nil, T.nilable(Customer))
      @email = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @invoice_sent_at = T.let(nil, T.nilable(String))
      @invoice_url = T.let(nil, T.nilable(String))
      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @name = T.let(nil, T.nilable(String))
      @note = T.let(nil, T.nilable(String))
      @note_attributes = T.let(nil, T.nilable(T::Array[T.untyped]))
      @order_id = T.let(nil, T.nilable(Integer))
      @payment_terms = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @shipping_line = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @source_name = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @subtotal_price = T.let(nil, T.nilable(String))
      @tags = T.let(nil, T.nilable(String))
      @tax_exempt = T.let(nil, T.nilable(T::Boolean))
      @tax_exemptions = T.let(nil, T.nilable(T::Array[T.untyped]))
      @tax_lines = T.let(nil, T.nilable(T::Array[T.untyped]))
      @taxes_included = T.let(nil, T.nilable(T::Boolean))
      @total_price = T.let(nil, T.nilable(String))
      @total_tax = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      customer: Customer
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "draft_orders/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "draft_orders/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "draft_orders.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "draft_orders/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "draft_orders.json"},
      {http_method: :post, operation: :send_invoice, ids: [:id], path: "draft_orders/<id>/send_invoice.json"},
      {http_method: :put, operation: :complete, ids: [:id], path: "draft_orders/<id>/complete.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "draft_orders/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :applied_discount
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :billing_address
    sig { returns(T.nilable(String)) }
    attr_reader :completed_at
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(Customer)) }
    attr_reader :customer
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :invoice_sent_at
    sig { returns(T.nilable(String)) }
    attr_reader :invoice_url
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :note_attributes
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :payment_terms
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_address
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :shipping_line
    sig { returns(T.nilable(String)) }
    attr_reader :source_name
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(String)) }
    attr_reader :subtotal_price
    sig { returns(T.nilable(String)) }
    attr_reader :tags
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :tax_exempt
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :tax_exemptions
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :tax_lines
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxes_included
    sig { returns(T.nilable(String)) }
    attr_reader :total_price
    sig { returns(T.nilable(String)) }
    attr_reader :total_tax
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(DraftOrder))
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
        T.cast(result[0], T.nilable(DraftOrder))
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
          fields: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          ids: T.untyped,
          status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[DraftOrder])
      end
      def all(
        fields: nil,
        limit: nil,
        since_id: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        ids: nil,
        status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {fields: fields, limit: limit, since_id: since_id, updated_at_min: updated_at_min, updated_at_max: updated_at_max, ids: ids, status: status}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[DraftOrder])
      end

      sig do
        params(
          since_id: T.untyped,
          status: T.untyped,
          updated_at_max: T.untyped,
          updated_at_min: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        since_id: nil,
        status: nil,
        updated_at_max: nil,
        updated_at_min: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {since_id: since_id, status: status, updated_at_max: updated_at_max, updated_at_min: updated_at_min}.merge(kwargs).compact,
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
    def send_invoice(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :send_invoice,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        payment_gateway_id: T.untyped,
        payment_pending: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def complete(
      payment_gateway_id: nil,
      payment_pending: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :put,
        operation: :complete,
        session: @session,
        ids: {id: @id},
        params: {payment_gateway_id: payment_gateway_id, payment_pending: payment_pending}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
