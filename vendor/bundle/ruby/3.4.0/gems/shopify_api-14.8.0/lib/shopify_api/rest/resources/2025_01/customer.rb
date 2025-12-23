# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Customer < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @addresses = T.let(nil, T.nilable(T::Array[T.untyped]))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @default_address = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @email = T.let(nil, T.nilable(String))
      @email_marketing_consent = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @first_name = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @last_name = T.let(nil, T.nilable(String))
      @last_order_id = T.let(nil, T.nilable(Integer))
      @last_order_name = T.let(nil, T.nilable(String))
      @marketing_opt_in_level = T.let(nil, T.nilable(String))
      @metafield = T.let(nil, T.nilable(Metafield))
      @multipass_identifier = T.let(nil, T.nilable(String))
      @note = T.let(nil, T.nilable(String))
      @orders_count = T.let(nil, T.nilable(Integer))
      @password = T.let(nil, T.nilable(String))
      @password_confirmation = T.let(nil, T.nilable(String))
      @phone = T.let(nil, T.nilable(String))
      @sms_marketing_consent = T.let(nil, T.nilable(T::Hash[T.untyped, T.untyped]))
      @state = T.let(nil, T.nilable(String))
      @tags = T.let(nil, T.nilable(String))
      @tax_exempt = T.let(nil, T.nilable(T::Boolean))
      @tax_exemptions = T.let(nil, T.nilable(T::Array[T.untyped]))
      @total_spent = T.let(nil, T.nilable(String))
      @updated_at = T.let(nil, T.nilable(String))
      @verified_email = T.let(nil, T.nilable(T::Boolean))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({
      metafield: Metafield
    }, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @atomic_hash_attributes = [:email_marketing_consent]
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:id], path: "customers/<id>.json"},
      {http_method: :get, operation: :count, ids: [], path: "customers/count.json"},
      {http_method: :get, operation: :get, ids: [], path: "customers.json"},
      {http_method: :get, operation: :get, ids: [:id], path: "customers/<id>.json"},
      {http_method: :get, operation: :orders, ids: [:id], path: "customers/<id>/orders.json"},
      {http_method: :get, operation: :search, ids: [], path: "customers/search.json"},
      {http_method: :post, operation: :account_activation_url, ids: [:id], path: "customers/<id>/account_activation_url.json"},
      {http_method: :post, operation: :post, ids: [], path: "customers.json"},
      {http_method: :post, operation: :send_invite, ids: [:id], path: "customers/<id>/send_invite.json"},
      {http_method: :put, operation: :put, ids: [:id], path: "customers/<id>.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(T::Array[T::Hash[T.untyped, T.untyped]])) }
    attr_reader :addresses
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :default_address
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :email_marketing_consent
    sig { returns(T.nilable(String)) }
    attr_reader :first_name
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :last_name
    sig { returns(T.nilable(Integer)) }
    attr_reader :last_order_id
    sig { returns(T.nilable(String)) }
    attr_reader :last_order_name
    sig { returns(T.nilable(String)) }
    attr_reader :marketing_opt_in_level
    sig { returns(T.nilable(Metafield)) }
    attr_reader :metafield
    sig { returns(T.nilable(String)) }
    attr_reader :multipass_identifier
    sig { returns(T.nilable(String)) }
    attr_reader :note
    sig { returns(T.nilable(Integer)) }
    attr_reader :orders_count
    sig { returns(T.nilable(String)) }
    attr_reader :password
    sig { returns(T.nilable(String)) }
    attr_reader :password_confirmation
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    attr_reader :sms_marketing_consent
    sig { returns(T.nilable(String)) }
    attr_reader :state
    sig { returns(T.nilable(String)) }
    attr_reader :tags
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :tax_exempt
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :tax_exemptions
    sig { returns(T.nilable(String)) }
    attr_reader :total_spent
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :verified_email

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          fields: T.untyped,
          session: Auth::Session
        ).returns(T.nilable(Customer))
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
        T.cast(result[0], T.nilable(Customer))
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
          ids: T.untyped,
          since_id: T.untyped,
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          limit: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Customer])
      end
      def all(
        ids: nil,
        since_id: nil,
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        limit: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {ids: ids, since_id: since_id, created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max, limit: limit, fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Customer])
      end

      sig do
        params(
          created_at_min: T.untyped,
          created_at_max: T.untyped,
          updated_at_min: T.untyped,
          updated_at_max: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def count(
        created_at_min: nil,
        created_at_max: nil,
        updated_at_min: nil,
        updated_at_max: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :count,
          session: session,
          ids: {},
          params: {created_at_min: created_at_min, created_at_max: created_at_max, updated_at_min: updated_at_min, updated_at_max: updated_at_max}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          id: T.any(Integer, String),
          status: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def orders(
        id:,
        status: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :orders,
          session: session,
          ids: {id: id},
          params: {status: status}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

      sig do
        params(
          order: T.untyped,
          query: T.untyped,
          limit: T.untyped,
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T.untyped)
      end
      def search(
        order: nil,
        query: nil,
        limit: nil,
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        request(
          http_method: :get,
          operation: :search,
          session: session,
          ids: {},
          params: {order: order, query: query, limit: limit, fields: fields}.merge(kwargs).compact,
          body: {},
          entity: nil,
        )
      end

    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def account_activation_url(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :account_activation_url,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

    sig do
      params(
        body: T.untyped,
        kwargs: T.untyped
      ).returns(T.untyped)
    end
    def send_invite(
      body: nil,
      **kwargs
    )
      self.class.request(
        http_method: :post,
        operation: :send_invite,
        session: @session,
        ids: {id: @id},
        params: {}.merge(kwargs).compact,
        body: body,
        entity: self,
      )
    end

  end
end
