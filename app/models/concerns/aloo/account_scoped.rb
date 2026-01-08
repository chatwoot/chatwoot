# frozen_string_literal: true

module Aloo
  module AccountScoped
    extend ActiveSupport::Concern

    included do
      belongs_to :account
      validates :account_id, presence: true

      # CRITICAL: Always scope queries by account to prevent data leakage
      scope :for_account, ->(account) { where(account: account) }
    end

    class_methods do
      # Raises error if query doesn't include account scope
      # Use in development/test to catch missing scopes
      def require_account_scope!
        unless current_scope&.where_values_hash&.key?('account_id')
          raise ArgumentError, 'Query must be scoped by account'
        end
      end
    end
  end
end
