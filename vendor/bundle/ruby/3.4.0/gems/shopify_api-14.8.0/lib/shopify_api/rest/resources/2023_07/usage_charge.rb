# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class UsageCharge < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(Currency))
      @description = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @price = T.let(nil, T.nilable(String))
      @recurring_application_charge_id = T.let(nil, T.nilable(Integer))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      currency: Currency
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [:recurring_application_charge_id], path: "recurring_application_charges/<recurring_application_charge_id>/usage_charges.json"},
      {http_method: :get, operation: :get, ids: [:recurring_application_charge_id, :id], path: "recurring_application_charges/<recurring_application_charge_id>/usage_charges/<id>.json"},
      {http_method: :post, operation: :post, ids: [:recurring_application_charge_id], path: "recurring_application_charges/<recurring_application_charge_id>/usage_charges.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Currency)) }
    attr_reader :currency
    sig { returns(T.nilable(String)) }
    attr_reader :description
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :price
    sig { returns(T.nilable(Integer)) }
    attr_reader :recurring_application_charge_id
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          recurring_application_charge_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(UsageCharge))
      end
      def find(
        id:,
        recurring_application_charge_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, recurring_application_charge_id: recurring_application_charge_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(UsageCharge))
      end

      sig do
        params(
          recurring_application_charge_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[UsageCharge])
      end
      def all(
        recurring_application_charge_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {recurring_application_charge_id: recurring_application_charge_id},
          params: {fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[UsageCharge])
      end

    end

  end
end
