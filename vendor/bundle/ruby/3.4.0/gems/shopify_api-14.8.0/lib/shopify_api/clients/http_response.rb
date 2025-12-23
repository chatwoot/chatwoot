# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Clients
    class HttpResponse
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :code

      sig { returns(T::Hash[String, T::Array[String]]) }
      attr_reader :headers

      sig { returns(T.any(T::Hash[String, T.untyped], String, OpenStruct)) }
      attr_reader :body

      sig { returns(T.nilable(String)) }
      attr_reader :prev_page_info, :next_page_info

      sig { returns(T.nilable(T::Hash[String, Integer])) }
      attr_reader :api_call_limit

      sig { returns(T.nilable(Float)) }
      attr_reader :retry_request_after

      sig do
        params(
          code: Integer,
          headers: T::Hash[String, T::Array[String]],
          body: T.any(T::Hash[String, T.untyped], String, OpenStruct),
        ).void
      end
      def initialize(code:, headers:, body:)
        @code = code
        @headers = headers
        @body = body

        @prev_page_info = T.let(nil, T.nilable(String))
        @next_page_info = T.let(nil, T.nilable(String))
        @prev_page_info, @next_page_info = parse_link_header

        @api_call_limit = T.let(nil, T.nilable(T::Hash[String, Integer]))
        @retry_request_after = T.let(nil, T.nilable(Float))
        @api_call_limit = parse_api_call_limit_header
        @retry_request_after = parse_retry_header
      end

      sig { returns(T::Boolean) }
      def ok?
        code >= 200 && code <= 299
      end

      private

      sig { returns(T::Array[T.nilable(String)]) }
      def parse_link_header
        return [nil, nil] if @headers["link"].nil?

        page_info = {}
        T.must(T.must(@headers["link"])[0]).split(",").each do |link|
          rel = T.must(link.match(/rel="(.*?)"/))[1]
          url = T.must(T.must(link.match(/<(.*?)>/))[1])

          T.must(URI.parse(url).query).split("&").each do |param|
            if param.split("=")[0] == "page_info"
              page_info[rel] = param.split("=")[1]
              break
            end
          end
        end

        [page_info["previous"], page_info["next"]]
      end

      sig { returns(T.nilable(Float)) }
      def parse_retry_header
        return nil if @headers["retry-after"].nil?

        T.must(@headers["retry-after"])[0].to_f
      end

      sig { returns(T.nilable(T::Hash[String, Integer])) }
      def parse_api_call_limit_header
        rate_limit_info = headers["x-shopify-shop-api-call-limit"]&.first
        return if rate_limit_info.nil?

        request_count, bucket_size = rate_limit_info.split("/").map(&:to_i)
        { request_count: request_count, bucket_size: bucket_size }
      end
    end
  end
end
