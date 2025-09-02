module Weave
  module Core
    class RateLimitOverride < ApplicationRecord
      self.table_name = 'weave_core_rate_limit_overrides'

      belongs_to :account, class_name: '::Account'

      RATE_CATEGORIES = %w[
        account_rpm
        messaging_write_rpm
        widget_write_rpm
        whatsapp_inbound_rpm
        reports_rpm
      ].freeze

      validates :account_id, presence: true
      validates :category, presence: true, inclusion: { in: RATE_CATEGORIES }
      validates :override_limit, presence: true, 
                numericality: { greater_than: 0, less_than_or_equal_to: 10000 }
      validates :reason, presence: true
      validates :expires_at, presence: true
      validates :created_by_user_id, presence: true

      validate :expires_at_in_future
      validate :unique_active_override_per_category

      scope :active, -> { where('expires_at > ?', Time.current) }
      scope :expired, -> { where('expires_at <= ?', Time.current) }

      def active?
        expires_at > Time.current
      end

      def expired?
        !active?
      end

      def expires_in_hours
        return 0 if expired?
        ((expires_at - Time.current) / 1.hour).round(2)
      end

      private

      def expires_at_in_future
        return unless expires_at
        
        errors.add(:expires_at, 'must be in the future') if expires_at <= Time.current
      end

      def unique_active_override_per_category
        existing = self.class.active
                      .where(account_id: account_id, category: category)
                      .where.not(id: id)
        
        if existing.exists?
          errors.add(:category, 'already has an active override. Please expire the existing one first.')
        end
      end
    end
  end
end