# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class CustomerAddress < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @address1 = T.let(nil, T.nilable(String))
      @address2 = T.let(nil, T.nilable(String))
      @city = T.let(nil, T.nilable(String))
      @company = T.let(nil, T.nilable(String))
      @country = T.let(nil, T.nilable(String))
      @country_code = T.let(nil, T.nilable(String))
      @country_name = T.let(nil, T.nilable(String))
      @customer_id = T.let(nil, T.nilable(Integer))
      @first_name = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @last_name = T.let(nil, T.nilable(String))
      @name = T.let(nil, T.nilable(String))
      @phone = T.let(nil, T.nilable(String))
      @province = T.let(nil, T.nilable(String))
      @province_code = T.let(nil, T.nilable(String))
      @zip = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:customer_id, :id], path: "customers/<customer_id>/addresses/<id>.json"},
      {http_method: :get, operation: :get, ids: [:customer_id], path: "customers/<customer_id>/addresses.json"},
      {http_method: :get, operation: :get, ids: [:customer_id, :id], path: "customers/<customer_id>/addresses/<id>.json"},
      {http_method: :post, operation: :post, ids: [:customer_id], path: "customers/<customer_id>/addresses.json"},
      {http_method: :put, operation: :default, ids: [:customer_id, :id], path: "customers/<customer_id>/addresses/<id>/default.json"},
      {http_method: :put, operation: :put, ids: [:customer_id, :id], path: "customers/<customer_id>/addresses/<id>.json"},
      {http_method: :put, operation: :set, ids: [:customer_id], path: "customers/<customer_id>/addresses/set.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :address1
    sig { returns(T.nilable(String)) }
    attr_reader :address2
    sig { returns(T.nilable(String)) }
    attr_reader :city
    sig { returns(T.nilable(String)) }
    attr_reader :company
    sig { returns(T.nilable(String)) }
    attr_reader :country
    sig { returns(T.nilable(String)) }
    attr_reader :country_code
    sig { returns(T.nilable(String)) }
    attr_reader :country_name
    sig { returns(T.nilable(Integer)) }
    attr_reader :customer_id
    sig { returns(T.nilable(String)) }
    attr_reader :first_name
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :last_name
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :province
    sig { returns(T.nilable(String)) }
    attr_reader :province_code
    sig { returns(T.nilable(String)) }
    attr_reader :zip

    class << self
      sig do
        returns(String)
      end
      def json_body_name()
        "address"
      end

      sig do
        returns(T::Array[String])
      end
      def json_response_body_names()
        [
          "customer_address",
          "address"
        ]
      end

      sig do
        params(
          id: T.any(Integer, String),
          customer_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.nilable(CustomerAddress))
      end
      def find(
        id:,
        customer_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, customer_id: customer_id},
          params: {},
        )
        T.cast(result[0], T.nilable(CustomerAddress))
      end

      sig do
        params(
          id: T.any(Integer, String),
          customer_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        customer_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, customer_id: customer_id},
          params: {},
        )
      end

      sig do
        params(
          customer_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[CustomerAddress])
      end
      def all(
        customer_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {customer_id: customer_id},
          params: {}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[CustomerAddress])
      end

    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def default(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :put,
        operation: :default,
        session: @session,
        ids: {id: @id, customer_id: @customer_id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        address_ids: T.nilable(T.any(T::Array[T.untyped], Integer, String)),
        operation: T.untyped,
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def set(
      address_ids: nil,
      operation: nil,
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :put,
        operation: :set,
        session: @session,
        ids: {customer_id: @customer_id},
        params: {address_ids: address_ids, operation: operation}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
