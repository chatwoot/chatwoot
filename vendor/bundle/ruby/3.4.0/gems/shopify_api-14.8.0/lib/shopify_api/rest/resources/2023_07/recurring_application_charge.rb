# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class RecurringApplicationCharge < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @activated_on = T.let(nil, T.nilable(String))
      @billing_on = T.let(nil, T.nilable(String))
      @cancelled_on = T.let(nil, T.nilable(String))
      @capped_amount = T.let(nil, T.nilable(T.any(String, Integer)))
      @confirmation_url = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(Currency))
      @id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @price = T.let(nil, T.nilable(T.any(String, Float)))
      @return_url = T.let(nil, T.nilable(String))
      @status = T.let(nil, T.nilable(String))
      @terms = T.let(nil, T.nilable(String))
      @test = T.let(nil, T.nilable(T::Boolean))
      @trial_days = T.let(nil, T.nilable(Integer))
      @trial_ends_on = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      currency: Currency
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "recurring_application_charges/<id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "recurring_application_charges.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "recurring_application_charges/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "recurring_application_charges.json"},
      {http_method: :put, operation: :customize, ids: [:id], path: "recurring_application_charges/<id>/customize.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :activated_on
    sig { returns(T.nilable(String)) }
    attr_reader :billing_on
    sig { returns(T.nilable(String)) }
    attr_reader :cancelled_on
    sig { returns(T.nilable(T.any(String, Integer))) }
    attr_reader :capped_amount
    sig { returns(T.nilable(String)) }
    attr_reader :confirmation_url
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Currency)) }
    attr_reader :currency
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(T.any(String, Float))) }
    attr_reader :price
    sig { returns(T.nilable(String)) }
    attr_reader :return_url
    sig { returns(T.nilable(String)) }
    attr_reader :status
    sig { returns(T.nilable(String)) }
    attr_reader :terms
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :test
    sig { returns(T.nilable(Integer)) }
    attr_reader :trial_days
    sig { returns(T.nilable(String)) }
    attr_reader :trial_ends_on
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(RecurringApplicationCharge))
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
        T.cast(result[0], T.nilable(RecurringApplicationCharge))
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
          since_id: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[RecurringApplicationCharge])
      end
      def all(
        since_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {since_id: since_id, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[RecurringApplicationCharge])
      end

      sig do
        params(session: Auth::Session)
          .returns(T.nilable(RecurringApplicationCharge))
      end
      def current(session: ShopifyAPI::Context.active_session)
        charges = all(session: session)
        charges.select { |charge| charge.status == "active" }.first
      end

    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def customize(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :put,
        operation: :customize,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
