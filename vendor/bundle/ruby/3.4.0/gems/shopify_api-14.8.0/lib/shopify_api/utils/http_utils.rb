# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Utils
    module HttpUtils
      class << self
        extend T::Sig

        sig { params(headers: T::Hash[String, T.untyped]).returns(T::Hash[String, T.untyped]) }
        def normalize_headers(headers)
          headers.to_h { |k, v| [k.downcase.sub("http_", "").gsub("_", "-"), v] }
        end
      end
    end
  end
end
