# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class AssignedFulfillmentOrder < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @assigned_location_id = T.let(nil, T.nilable(Integer))
      @destination = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @id = T.let(nil, T.nilable(Integer))
      @line_items = T.let(nil, T.nilable(T::Array[T.untyped]))
      @order_id = T.let(nil, T.nilable(Integer))
      @request_status = T.let(nil, T.nilable(String))
      @shop_id = T.let(nil, T.nilable(Integer))
      @status = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [], path: "assigned_fulfillment_orders.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :assigned_location_id
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :destination
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :line_items
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(String)) }
    attr_reader :request_status
    sig { returns(T.nilable(Integer)) }
    attr_reader :shop_id
    sig { returns(T.nilable(String)) }
    attr_reader :status

    class << self
      sig do
        returns(T::Array[String])
      end
      def json_response_body_names()
        [
          "fulfillment_order"
        ]
      end

      sig do
        params(
          assignment_status: T.untyped,
          location_ids: T.nilable(T.any(T::Array[T.untyped], Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[AssignedFulfillmentOrder])
      end
      def all(
        assignment_status: nil,
        location_ids: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {assignment_status: assignment_status, location_ids: location_ids}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[AssignedFulfillmentOrder])
      end

    end

  end
end
