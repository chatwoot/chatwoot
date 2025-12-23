# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class DisputeFileUpload < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @dispute_evidence_id = T.let(nil, T.nilable(Integer))
      @dispute_evidence_type = T.let(nil, T.nilable(String))
      @file_size = T.let(nil, T.nilable(Integer))
      @file_type = T.let(nil, T.nilable(String))
      @filename = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @original_filename = T.let(nil, T.nilable(String))
      @shop_id = T.let(nil, T.nilable(Integer))
      @url = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :delete, operation: :delete, ids: [:dispute_id, :id], path: "shopify_payments/disputes/<dispute_id>/dispute_file_uploads/<id>.json"},
      {http_method: :post, operation: :post, ids: [:dispute_id], path: "shopify_payments/disputes/<dispute_id>/dispute_file_uploads.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(Integer)) }
    attr_reader :dispute_evidence_id
    sig { returns(T.nilable(String)) }
    attr_reader :dispute_evidence_type
    sig { returns(T.nilable(Integer)) }
    attr_reader :file_size
    sig { returns(T.nilable(String)) }
    attr_reader :file_type
    sig { returns(T.nilable(String)) }
    attr_reader :filename
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(String)) }
    attr_reader :original_filename
    sig { returns(T.nilable(Integer)) }
    attr_reader :shop_id
    sig { returns(T.nilable(String)) }
    attr_reader :url

    class << self
      sig do
        params(
          id: T.any(Integer, String),
          dispute_id: T.nilable(T.any(Integer, String)),
          session: Auth::Session
        ).returns(T.untyped)
      end
      def delete(
        id:,
        dispute_id: nil,
        session: ShopifyAPI::Context.active_session
      )
        request(
          http_method: :delete,
          operation: :delete,
          session: session,
          ids: {id: id, dispute_id: dispute_id},
          params: {},
        )
      end

    end

  end
end
