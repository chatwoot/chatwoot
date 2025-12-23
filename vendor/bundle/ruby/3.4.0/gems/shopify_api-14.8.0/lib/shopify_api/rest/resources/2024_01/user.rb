# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class User < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @account_owner = T.let(nil, T.nilable(T::Boolean))
      @bio = T.let(nil, T.nilable(String))
      @email = T.let(nil, T.nilable(String))
      @first_name = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @im = T.let(nil, T.nilable(String))
      @last_name = T.let(nil, T.nilable(String))
      @locale = T.let(nil, T.nilable(String))
      @permissions = T.let(nil, T.nilable(T::Array[T.untyped]))
      @phone = T.let(nil, T.nilable(String))
      @receive_announcements = T.let(nil, T.nilable(Integer))
      @screen_name = T.let(nil, T.nilable(String))
      @url = T.let(nil, T.nilable(String))
      @user_type = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :current, ids: [], path: "users/current.json"},
      {http_method: :get, operation: :get, ids: [], path: "users.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "users/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :account_owner
    sig { returns(T.nilable(String)) }
    attr_reader :bio
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(String)) }
    attr_reader :first_name
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :im
    sig { returns(T.nilable(String)) }
    attr_reader :last_name
    sig { returns(T.nilable(String)) }
    attr_reader :locale
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :permissions
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(Integer)) }
    attr_reader :receive_announcements
    sig { returns(T.nilable(String)) }
    attr_reader :screen_name
    sig { returns(T.nilable(String)) }
    attr_reader :url
    sig { returns(T.nilable(String)) }
    attr_reader :user_type

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          session: Auth::Session
        ).returns(T.nilable(User))
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
        T.cast(result[0], T.nilable(User))
      end

      sig do
        params(
          limit: T.untyped,
          page_info: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[User])
      end
      def all(
        limit: nil,
        page_info: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {limit: limit, page_info: page_info}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[User])
      end

      sig do
        params(
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def current(
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :current,
          session: session,
          ids: {},
          params: {}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

  end
end
