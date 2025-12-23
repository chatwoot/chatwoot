# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class PaymentGateway < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @attachment = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @credential1 = T.let(nil, T.nilable(String))
      @credential2 = T.let(nil, T.nilable(String))
      @credential3 = T.let(nil, T.nilable(String))
      @credential4 = T.let(nil, T.nilable(String))
      @disabled = T.let(nil, T.nilable(T::Boolean))
      @enabled_card_brands = T.let(nil, T.nilable(T::Array[T.untyped]))
      @id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @processing_method = T.let(nil, T.nilable(String))
      @provider_id = T.let(nil, T.nilable(Integer))
      @sandbox = T.let(nil, T.nilable(T::Boolean))
      @service_name = T.let(nil, T.nilable(String))
      @supports_network_tokenization = T.let(nil, T.nilable(T::Boolean))
      @type = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "payment_gateways/<id>.json"},
      {http_method: :get, operation: :get, ids: [], path: "payment_gateways.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "payment_gateways/<id>.json"},
      {http_method: :post, operation: :post, ids: [], path: "payment_gateways.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "payment_gateways/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :attachment
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :credential1
    sig { returns(T.nilable(String)) }
    attr_reader :credential2
    sig { returns(T.nilable(String)) }
    attr_reader :credential3
    sig { returns(T.nilable(String)) }
    attr_reader :credential4
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :disabled
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :enabled_card_brands
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(String)) }
    attr_reader :processing_method
    sig { returns(T.nilable(Integer)) }
    attr_reader :provider_id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :sandbox
    sig { returns(T.nilable(String)) }
    attr_reader :service_name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :supports_network_tokenization
    sig { returns(T.nilable(String)) }
    attr_reader :type
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(PaymentGateway))
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
        T.cast(result[0], T.nilable(PaymentGateway))
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
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[PaymentGateway])
      end
      def all(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[PaymentGateway])
      end

    end

  end
end
