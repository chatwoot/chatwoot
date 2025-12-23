# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Auth
    class AuthScopes
      extend T::Sig

      SCOPE_DELIMITER = ","

      sig { params(scope_names: T.any(String, T::Array[String])).void }
      def initialize(scope_names = [])
        @compressed_scopes = T.let([].to_set, T::Set[String])
        @expanded_scopes = T.let([].to_set, T::Set[String])

        if scope_names.is_a?(String)
          scope_names = scope_names.to_s.split(SCOPE_DELIMITER)
        end

        store_scopes(scope_names)
      end

      sig { params(auth_scopes: AuthScopes).returns(T::Boolean) }
      def covers?(auth_scopes)
        auth_scopes.compressed_scopes <= expanded_scopes
      end

      sig { returns(String) }
      def to_s
        to_a.join(SCOPE_DELIMITER)
      end

      sig { returns(T::Array[String]) }
      def to_a
        compressed_scopes.to_a
      end

      sig { params(other: T.nilable(AuthScopes)).returns(T::Boolean) }
      def ==(other)
        !other.nil? &&
          other.class == self.class &&
          compressed_scopes == other.compressed_scopes
      end

      alias_method :eql?, :==

      sig { returns(Integer) }
      def hash
        compressed_scopes.hash
      end

      protected

      sig { returns(T::Set[String]) }
      attr_reader :compressed_scopes, :expanded_scopes

      private

      sig { params(scope_names: T::Array[String]).void }
      def store_scopes(scope_names)
        scopes = scope_names.map(&:strip).reject(&:empty?).to_set
        implied_scopes = scopes.map { |scope| implied_scope(scope) }.compact

        @compressed_scopes = scopes - implied_scopes
        @expanded_scopes = scopes + implied_scopes
      end

      sig { params(scope: String).returns(T.nilable(String)) }
      def implied_scope(scope)
        is_write_scope = scope =~ /\A(unauthenticated_)?write_(.*)\z/
        "#{Regexp.last_match(1)}read_#{Regexp.last_match(2)}" if is_write_scope
      end
    end
  end
end
