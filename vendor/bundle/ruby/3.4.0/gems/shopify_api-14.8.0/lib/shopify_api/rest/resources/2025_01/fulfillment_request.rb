# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class FulfillmentRequest < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @fulfillment_order_id = T.let(nil, T.nilable(Integer))
      @kind = T.let(nil, T.nilable(String))
      @message = T.let(nil, T.nilable(String))
      @request_options = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @response_data = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @sent_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :post, operation: :accept, ids: [:fulfillment_order_id], path: "fulfillment_orders/<fulfillment_order_id>/fulfillment_request/accept.json"},
      {http_method: :post, operation: :post, ids: [:fulfillment_order_id], path: "fulfillment_orders/<fulfillment_order_id>/fulfillment_request.json"},
      {http_method: :post, operation: :reject, ids: [:fulfillment_order_id], path: "fulfillment_orders/<fulfillment_order_id>/fulfillment_request/reject.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :fulfillment_order_id
    sig { returns(T.nilable(String)) }
    attr_reader :kind
    sig { returns(T.nilable(String)) }
    attr_reader :message
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :request_options
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :response_data
    sig { returns(T.nilable(String)) }
    attr_reader :sent_at

    class << self
      sig do
        returns(T::Array[String])
      end
      def json_response_body_names()
        [
          "submitted_fulfillment_order",
          "fulfillment_order"
        ]
      end

    end

    sig do
      params(
        message: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def accept(
      message: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :accept,
        session: @session,
        ids: {fulfillment_order_id: @fulfillment_order_id},
        params: {message: message}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        message: T.untyped,
        reason: T.untyped,
        line_items: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def reject(
      message: nil,
      reason: nil,
      line_items: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :reject,
        session: @session,
        ids: {fulfillment_order_id: @fulfillment_order_id},
        params: {message: message, reason: reason, line_items: line_items}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
