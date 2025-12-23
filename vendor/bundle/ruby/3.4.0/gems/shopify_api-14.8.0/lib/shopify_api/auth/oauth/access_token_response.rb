# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Auth
    module Oauth
      class AccessTokenResponse < T::Struct
        extend T::Sig

        const :access_token, String
        const :scope, String
        const :session, T.nilable(String)
        const :expires_in, T.nilable(Integer)
        const :associated_user, T.nilable(AssociatedUser)
        const :associated_user_scope, T.nilable(String)

        sig { returns(T::Boolean) }
        def online_token?
          !associated_user.nil?
        end

        alias_method :eql?, :==
        sig { params(other: T.nilable(AccessTokenResponse)).returns(T::Boolean) }
        def ==(other)
          return false unless other

          access_token == other.access_token &&
            scope == other.scope &&
            session == other.session &&
            expires_in == other.expires_in &&
            associated_user == other.associated_user &&
            associated_user_scope == other.associated_user_scope
        end
      end
    end
  end
end
