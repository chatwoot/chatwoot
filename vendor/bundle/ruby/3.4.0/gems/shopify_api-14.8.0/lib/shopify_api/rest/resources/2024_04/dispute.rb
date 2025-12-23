# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Dispute < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @amount = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @evidence_due_by = T.let(nil, T.nilable(String))
      @evidence_sent_on = T.let(nil, T.nilable(String))
      @finalized_on = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @network_reason_code = T.let(nil, T.nilable(String))
      @order_id = T.let(nil, T.nilable(Integer))
      @reason = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @type = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [], path: "shopify_payments/disputes.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "shopify_payments/disputes/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :amount
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(String)) }
    attr_reader :evidence_due_by
    sig { returns(T.nilable(String)) }
    attr_reader :evidence_sent_on
    sig { returns(T.nilable(String)) }
    attr_reader :finalized_on
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :network_reason_code
    sig { returns(T.nilable(Integer)) }
    attr_reader :order_id
    sig { returns(T.nilable(String)) }
    attr_reader :reason
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(String)) }
    attr_reader :type

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(Dispute))
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
        T.cast(result[0], T.nilable(Dispute))
      end

      sig do
        params(
          since_id: T.untyped,
          last_id: T.untyped,
          status: T.untyped,
          initiated_at: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Dispute])
      end
      def all(
        since_id: nil,
        last_id: nil,
        status: nil,
        initiated_at: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {since_id: since_id, last_id: last_id, status: status, initiated_at: initiated_at}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Dispute])
      end

    end

  end
end
