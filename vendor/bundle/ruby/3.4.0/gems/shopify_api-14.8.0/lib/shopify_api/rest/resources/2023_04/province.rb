# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Province < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @code = T.let(nil, T.nilable(String))
      @country_id = T.let(nil, T.nilable(Integer))
      @id = T.let(nil, T.nilable(Integer))
      @name = T.let(nil, T.nilable(String))
      @shipping_zone_id = T.let(nil, T.nilable(Integer))
      @tax = T.let(nil, T.nilable(Float))
      @tax_name = T.let(nil, T.nilable(String))
      @tax_percentage = T.let(nil, T.nilable(Float))
      @tax_type = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :count, ids: [:country_id], path: "countries/<country_id>/provinces/count.json"},
      {http_method: :get, operation: :get, ids: [:country_id], path: "countries/<country_id>/provinces.json"},
      {http_method: :get, operation: :get, ids: [:country_id, :id], path: "countries/<country_id>/provinces/<id>.json"},
      {http_method: :put, operation: :put, ids: [:country_id, :id], path: "countries/<country_id>/provinces/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :code
    sig { returns(T.nilable(Integer)) }
    attr_reader :country_id
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(Integer)) }
    attr_reader :shipping_zone_id
    sig { returns(T.nilable(Float)) }
    attr_reader :tax
    sig { returns(T.nilable(String)) }
    attr_reader :tax_name
    sig { returns(T.nilable(Float)) }
    attr_reader :tax_percentage
    sig { returns(T.nilable(String)) }
    attr_reader :tax_type

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          country_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Province))
      end
      def find(
        id:,
        country_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session
      )
        result = base_find(
          session: session,
          ids: {id: id, country_id: country_id},
          params: {fields: fields},
        )
        T.cast(result[0], T.nilable(Province))
      end

      sig do
        params(
          country_id: T.nilable(T.any(Integer, String)),
          since_id: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Province])
      end
      def all(
        country_id: nil,
        since_id: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {country_id: country_id},
          params: {since_id: since_id, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Province])
      end

      sig do
        params(
          country_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        country_id: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {country_id: country_id},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
