# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class FulfillmentOrder < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @assigned_location = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @assigned_location_id = T.let(nil, T.nilable(Integer))
      @delivery_method = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @destination = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @fulfill_at = T.let(nil, T.nilable(String))
      @fulfill_by = T.let(nil, T.nilable(String))
      @fulfillment_holds = T.let(nil, T.nilable(T::Array[T.untyped]))
      @id = T.let(nil, T.nilable(Integer))
      @international_duties = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @merchant_requests = T.let(nil, T.nilable(T::Array[T.untyped]))
      @order_id = T.let(nil, T.nilable(Integer))
      @request_status = T.let(nil, T.nilable(String))
      @shop_id = T.let(nil, T.nilable(Integer))
      @status = T.let(nil, T.nilable(String))
      @supported_actions = T.let(nil, T.nilable(T::Array[T.untyped]))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [:id], path: "fulfillment_orders/<id>.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/fulfillment_orders.json"},
      {http_method: :post, operation: :cancel, ids: [:id], path: "fulfillment_orders/<id>/cancel.json"},
      {http_method: :post, operation: :close, ids: [:id], path: "fulfillment_orders/<id>/close.json"},
      {http_method: :post, operation: :hold, ids: [:id], path: "fulfillment_orders/<id>/hold.json"},
      {http_method: :post, operation: :move, ids: [:id], path: "fulfillment_orders/<id>/move.json"},
      {http_method: :post, operation: :open, ids: [:id], path: "fulfillment_orders/<id>/open.json"},
      {http_method: :post, operation: :release_hold, ids: [:id], path: "fulfillment_orders/<id>/release_hold.json"},
      {http_method: :post, operation: :reschedule, ids: [:id], path: "fulfillment_orders/<id>/reschedule.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :assigned_location
    sig { returns(T.nilable(Integer)) }
    attr_reader :assigned_location_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :delivery_method
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :destination
    sig { returns(T.nilable(String)) }
    attr_reader :fulfill_at
    sig { returns(T.nilable(String)) }
    attr_reader :fulfill_by
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :fulfillment_holds
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :international_duties
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :merchant_requests
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(String)) }
    attr_reader :request_status
    sig { returns(T.nilable(Integer)) }
    attr_reader :shop_id
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :supported_actions

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(FulfillmentOrder))
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
        T.cast(result[0], T.nilable(FulfillmentOrder))
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[FulfillmentOrder])
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

        T.cast(response, T::Array[FulfillmentOrder])
      end

    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def cancel(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :cancel,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        message: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def close(
      message: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :close,
        session: @session,
        ids: {id: @id},
        params: {message: message}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        fulfillment_hold: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def hold(
      fulfillment_hold: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :hold,
        session: @session,
        ids: {id: @id},
        params: {fulfillment_hold: fulfillment_hold}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        fulfillment_order: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def move(
      fulfillment_order: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :move,
        session: @session,
        ids: {id: @id},
        params: {fulfillment_order: fulfillment_order}.merge(kwargs).compact,
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

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def release_hold(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :release_hold,
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
    def reschedule(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :reschedule,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
