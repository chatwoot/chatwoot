# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Asset < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @attachment = T.let(nil, T.nilable(String))
      @checksum = T.let(nil, T.nilable(String))
      @content_type = T.let(nil, T.nilable(String))
      @created_at = T.let(nil, T.nilable(String))
      @key = T.let(nil, T.nilable(String))
      @public_url = T.let(nil, T.nilable(String))
      @size = T.let(nil, T.nilable(Integer))
      @theme_id = T.let(nil, T.nilable(Integer))
      @updated_at = T.let(nil, T.nilable(String))
      @value = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:theme_id], path: "themes/<theme_id>/assets.json"},
      {http_method: :get, operation: :get, ids: [:theme_id], path: "themes/<theme_id>/assets.json"},
      {http_method: :get, operation: :get, ids: [:theme_id], path: "themes/<theme_id>/assets.json"},
      {http_method: :put, operation: :put, ids: [:theme_id], path: "themes/<theme_id>/assets.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :attachment
    sig { returns(T.nilable(String)) }
    attr_reader :checksum
    sig { returns(T.nilable(String)) }
    attr_reader :content_type
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :key
    sig { returns(T.nilable(String)) }
    attr_reader :public_url
    sig { returns(T.nilable(Integer)) }
    attr_reader :size
    sig { returns(T.nilable(Integer)) }
    attr_reader :theme_id
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(String)) }
    attr_reader :value

    class << self
      sig do
        returns(String)
      end
      def primary_key()
        "key"
      end

      sig do
        params(
          theme_id: T.nilable(T.any(Integer, String)),
          asset: T.nilable(T::Hash[T.untyped, T.untyped]),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        theme_id: nil,
        asset: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {theme_id: theme_id},
          params: {asset: asset},
        )
      end

      sig do
        params(
          theme_id: T.nilable(T.any(Integer, String)),
          fields: T.untyped,
          asset: T.nilable(T::Hash[T.untyped, T.untyped]),
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Asset])
      end
      def all(
        theme_id: nil,
        fields: nil,
        asset: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {theme_id: theme_id},
          params: {fields: fields, asset: asset}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Asset])
      end

    end

  end
end
