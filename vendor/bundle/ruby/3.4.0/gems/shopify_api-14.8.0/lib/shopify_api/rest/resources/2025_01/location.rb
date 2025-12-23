# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Location < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @active = T.let(nil, T.nilable(T::Boolean))
      @address1 = T.let(nil, T.nilable(String))
      @address2 = T.let(nil, T.nilable(String))
      @city = T.let(nil, T.nilable(String))
      @country = T.let(nil, T.nilable(String))
      @country_code = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @legacy = T.let(nil, T.nilable(T::Boolean))
      @localized_country_name = T.let(nil, T.nilable(String))
      @localized_province_name = T.let(nil, T.nilable(String))
      @name = T.let(nil, T.nilable(String))
      @phone = T.let(nil, T.nilable(String))
      @province = T.let(nil, T.nilable(String))
      @province_code = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @zip = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [], path: "locations/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "locations.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "locations/<id>.json"},
      {http_method: :get, operation: :inventory_levels, ids: [:id], path: "locations/<id>/inventory_levels.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :active
    sig { returns(T.nilable(String)) }
    attr_reader :address1
    sig { returns(T.nilable(String)) }
    attr_reader :address2
    sig { returns(T.nilable(String)) }
    attr_reader :city
    sig { returns(T.nilable(String)) }
    attr_reader :country
    sig { returns(T.nilable(String)) }
    attr_reader :country_code
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :legacy
    sig { returns(T.nilable(String)) }
    attr_reader :localized_country_name
    sig { returns(T.nilable(String)) }
    attr_reader :localized_province_name
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :province
    sig { returns(T.nilable(String)) }
    attr_reader :province_code
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(String)) }
    attr_reader :zip

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(Location))
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
        T.cast(result[0], T.nilable(Location))
      end

      sig do
        params(
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Location])
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

        T.cast(response, T::Array[Location])
      end

      sig do
        params(
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def inventory_levels(
        id:,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :inventory_levels,
          session: session,
          ids: {id: id},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
