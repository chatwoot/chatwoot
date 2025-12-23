# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Fulfillment < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @created_at = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @location_id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @notify_customer = T.let(nil, T.nilable(T::Boolean))
      @order_id = T.let(nil, T.nilable(Integer))
      @origin_address = T.let(nil, T.nilable(T::Array[T.untyped]))
      @receipt = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @service = T.let(nil, T.nilable(String))
      @shipment_status = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @tracking_company = T.let(nil, T.nilable(String))
      @tracking_number = T.let(nil, T.nilable(String))
      @tracking_numbers = T.let(nil, T.nilable(T::Array[T.untyped]))
      @tracking_url = T.let(nil, T.nilable(String))
      @tracking_urls = T.let(nil, T.nilable(T::Array[T.untyped]))
      @updated_at = T.let(nil, T.nilable(String))
      @variant_inventory_management = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [:order_id], path: "orders/<order_id>/fulfillments/count.json"},
      {http_method: :get, operation: :get, ids: [:fulfillment_order_id], path: "fulfillment_orders/<fulfillment_order_id>/fulfillments.json"},
      {http_method: :get, operation: :get, ids: [:order_id], path: "orders/<order_id>/fulfillments.json"},
      {http_method: :get, operation: :get, ids: [:order_id, :id], path: "orders/<order_id>/fulfillments/<id>.json"},
      {http_method: :post, operation: :cancel, ids: [:id], path: "fulfillments/<id>/cancel.json"},
      {http_method: :post, operation: :post, ids: [], path: "fulfillments.json"},
      {http_method: :post, operation: :update_tracking, ids: [:id], path: "fulfillments/<id>/update_tracking.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(Integer)) }
    attr_reader :location_id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :notify_customer
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :origin_address
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :receipt
    sig { returns(T.nilable(String)) }
    attr_reader :service
    sig { returns(T.nilable(String)) }
    attr_reader :shipment_status
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(String)) }
    attr_reader :tracking_company
    sig { returns(T.nilable(String)) }
    attr_reader :tracking_number
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :tracking_numbers
    sig { returns(T.nilable(String)) }
    attr_reader :tracking_url
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :tracking_urls
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(String)) }
    attr_reader :variant_inventory_management

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          order_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Fulfillment))
      end
      def find(
        id:,
        order_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, order_id: order_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Fulfillment))
      end

      sig do
        params(
          fulfillment_order_id: T.nilable(T.any(Integer, String)),
          order_id: T.nilable(T.any(Integer, String)),
          created_at_max: T.untyped,
          created_at_min: T.untyped,
          fields: T.untyped,
          limit: T.untyped,
          since_id: T.untyped,
          updated_at_max: T.untyped,
          updated_at_min: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Fulfillment])
      end
      def all(
        fulfillment_order_id: nil,
        order_id: nil,
        created_at_max: nil,
        created_at_min: nil,
        fields: nil,
        limit: nil,
        since_id: nil,
        updated_at_max: nil,
        updated_at_min: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {fulfillment_order_id: fulfillment_order_id, order_id: order_id},
          params: {created_at_max: created_at_max, created_at_min: created_at_min, fields: fields, limit: limit, since_id: since_id, updated_at_max: updated_at_max, updated_at_min: updated_at_min}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Fulfillment])
      end

      sig do
        params(
          order_id: T.nilable(T.any(Integer, String)),
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        order_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {order_id: order_id},
          params: {created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max}.merge(kwargs).compact,
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
        notify_customer: T.untyped,
        tracking_info: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def update_tracking(
      notify_customer: nil,
      tracking_info: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :update_tracking,
        session: @session,
        ids: {id: @id},
        params: {notify_customer: notify_customer, tracking_info: tracking_info}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
