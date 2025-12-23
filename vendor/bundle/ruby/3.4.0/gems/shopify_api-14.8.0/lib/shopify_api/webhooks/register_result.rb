# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Webhooks
    class RegisterResult < T::Struct
      extend T::Sig

      const :topic, String
      const :success, T::Boolean
      const :body, T.nilable(T.any(T::Hash[String, T.untyped], String))
    end
  end
end
